"""Import complete computer sprites from the supplied OS13 DMI, preserving animations.

Usage: python tools/dmitool/import_os13_computers.py "path/to/os13 sprites.dmi"
Requires Pillow. Existing states are retained for map overrides and other machinery.
The os13_ aliases are complete sprites, not screen/keyboard overlays.
"""

import argparse
import math
import re
from pathlib import Path

from PIL import Image, PngImagePlugin


# Source state triples: powered, unpowered, broken. Names are case-sensitive.
FAMILIES = {
    "general": ("tnccs", "tnccs0", "tnccsb"),
    "green": ("tnc1", "tnc10", "tnc1b"),
    "blue": ("btnc1", "btnc10", "btnc1b"),
    "research": ("ctnc1", "ctnc10", "ctnc1b"),
    "medical": ("mtnc", "mtnc0", "mtncb"),
    "genetics": ("gtnc", "gtnc0", "gtncb"),
    "security": ("stnc", "stnc0", "stncb"),
    "engineering": ("gbtnc", "gbtnc0", "gbtncb"),
    "communications": ("comm", "comm0", "commb"),
    "command": ("rcomm", "rcomm0", "rcommb"),
    "network": ("tncr", "tncr0", "tncrb"),
    "sensors": ("detector", "detector0", "detectorb"),
    "teleport": ("teleport", "teleport0", "teleportb"),
    "reactor": ("RCT", "RCT0", "RCTb"),
    "cargo": ("trading", "trading0", "tradingb"),
    "forensic": ("forensic", "forensic0", "forensicb"),
    "retro": ("old", "old0", "oldb"),
    # These families have no separate damaged/off sprite in the supplied sheet.
    "laptop": ("laptop1", "laptopoff", "laptopoff"),
    "security_laptop": ("laptop_security1", "laptopoff", "laptopoff"),
    "shuttle": ("shuttlecomms", "shuttlecommsb", "shuttlecommsb"),
}

COMMON = {
    "generic": "general", "command": "command", "comm": "communications",
    "comm_monitor": "network", "comm_logs": "network", "crew": "medical",
    "dna": "genetics", "medcomp": "medical", "id": "green",
    "security": "security", "explosive": "security", "cameras": "sensors",
    "shuttle": "shuttle", "teleport": "teleport", "robot": "blue",
    "mecha": "blue", "supply": "cargo", "request": "cargo",
    "forensic": "forensic", "holocontrol": "teleport", "solar": "engineering",
}

COMPUTERS = {
    **COMMON,
    "ai-fixer": "blue", "power": "engineering", "power_screen": "engineering",
    "solar_screen": "engineering", "turbinecomp": "reactor", "engines": "reactor",
    "fuel_screen": "reactor", "gyrotron_screen": "research", "rust_screen": "reactor",
    "area_atmos": "sensors", "tank": "sensors", "helm": "command",
    "alert:0": "green", "alert:1": "engineering", "alert:2": "security",
    "rdcomp": "research", "mass_driver": "cargo", "mining": "cargo",
    "engie_cams": "sensors", "library": "retro", "error": "security",
    "syndie": "security", "syndishuttle": "security", "tcboss": "security",
    "medlaptop": "laptop", "atmoslaptop": "laptop", "retro": "retro",
    "laptop": "laptop", "pass": "green",
}

CONSOLES = {
    **COMMON,
    "menu": "general", "medical": "medical", "operating": "medical",
    "engine": "reactor", "research": "research", "dummy": "general",
    "upload": "green", "ai-fixer-empty": "blue", "ai-fixer-full": "blue",
    "alert-green": "green", "alert-red": "security", "warrant": "security",
    "hostile": "security", "entertainment": "research", "game": "research",
    "power_monitor": "engineering", "power_monitor_warn": "security",
    "alarm_monitor": "security", "atmos_control": "sensors", "word": "retro",
    "shield": "blue", "bsod": "blue",
    **{f"smmon_{i}": "green" if i < 3 else "engineering" if i == 3 else "security"
       for i in range(7)},
}


def read_dmi(path):
    with Image.open(path) as image:
        description = image.info["Description"]
        width = int(re.search(r"^\s*width = (\d+)", description, re.M)[1])
        height = int(re.search(r"^\s*height = (\d+)", description, re.M)[1])
        assert (width, height) == (32, 32), f"Expected 32x32 sprites: {path}"
        sheet = image.convert("RGBA")
    states = []
    offset = 0
    columns = sheet.width // width
    for match in re.finditer(r'^state = "([^\n]*)"\n(.*?)(?=^state =|# END DMI)',
                             description, re.M | re.S):
        name, metadata = match.groups()
        dirs = int(re.search(r"dirs = (\d+)", metadata)[1])
        frames = int(re.search(r"frames = (\d+)", metadata)[1])
        tiles = []
        for index in range(offset, offset + dirs * frames):
            x, y = index % columns * width, index // columns * height
            assert y + height <= sheet.height, f"Truncated state: {name}"
            tiles.append(sheet.crop((x, y, x + width, y + height)))
        states.append((name, metadata, tiles))
        offset += dirs * frames
    return states


def write_dmi(path, states):
    tile_count = sum(len(tiles) for _, _, tiles in states)
    columns = math.ceil(math.sqrt(tile_count))
    sheet = Image.new("RGBA", (columns * 32, math.ceil(tile_count / columns) * 32))
    description = "# BEGIN DMI\nversion = 4.0\n\twidth = 32\n\theight = 32\n"
    offset = 0
    for name, metadata, tiles in states:
        description += f'state = "{name}"\n{metadata}'
        for tile in tiles:
            sheet.paste(tile, (offset % columns * 32, offset // columns * 32))
            offset += 1
    description += "# END DMI\n"
    info = PngImagePlugin.PngInfo()
    info.add_text("Description", description, zip=True)
    sheet.save(path, format="PNG", pnginfo=info)


def import_sprites(source_path, root):
    source = {}
    for name, metadata, tiles in read_dmi(source_path):
        if not name:
            continue
        if name in source:
            previous = source[name]
            assert previous[0] == metadata and all(
                a.tobytes() == b.tobytes() for a, b in zip(previous[1], tiles)
            ), f"Ambiguous source state: {name}"
        source[name] = (metadata, tiles)

    laptops = {name: "security_laptop" if family == "security" else "laptop"
               for name, family in CONSOLES.items()}
    for filename, mapping in [("computer.dmi", COMPUTERS), ("modular_console.dmi", CONSOLES),
                              ("modular_laptop.dmi", laptops)]:
        path = root / "icons" / "obj" / filename
        aliases = {}
        for name, family in mapping.items():
            for suffix, source_name in zip(("", "_off", "_broken"), FAMILIES[family]):
                aliases[f"os13_{name}{suffix}"] = source_name
        if filename == "computer.dmi":
            # The power monitor and solar controller select full sprites directly.
            aliases.update(power="gbtnc", power0="gbtnc0", powerb="gbtncb",
                           power_alert="stnc", solar="gbtnc", broken="gbtncb",
                           c_unpowered="gbtnc0")
        elif filename == "modular_laptop.dmi":
            aliases.update({"laptop-open": "laptopoff", "laptop-closed": "laptop0"})
        states = [state for state in read_dmi(path) if state[0] not in aliases]
        states.extend((name, *source[source_name]) for name, source_name in aliases.items())
        assert len(states) <= 512, f"Too many states in {filename}"
        write_dmi(path, states)
        print(f"{filename}: imported {len(aliases)} aliases; {len(states)} total states")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    import_sprites(args.source, Path(__file__).resolve().parents[2])
