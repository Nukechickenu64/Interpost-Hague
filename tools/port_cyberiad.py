"""Convert the pinned Paradise Cyberiad map using reviewed type mappings.

Unknown types block output. Run without --apply to inventory remaining content.
"""

import argparse
import collections
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/mapmerge_backup/mapmergepy"))
import map_helpers


SOURCE_COMMIT = "44060b61f407ed10043502cbb39cc6518e0a20b6"
SOURCE_URL = (
    "https://raw.githubusercontent.com/ParadiseSS13/Paradise/"
    + SOURCE_COMMIT
    + "/_maps/map_files/stations/boxstation.dmm"
)
TYPE_DEFINITION = re.compile(r"^\s*(/(?:obj|mob|turf|area)(?:/\w+)*)(?=\s|\(|$)", re.M)
GRID_START = re.compile(r'^\(\d+,\d+,\d+\)\s*=\s*\{"', re.M)
EXCLUDED_TYPES = (
    "/obj/structure/cable",
    "/obj/machinery/power/terminal",
    "/obj/machinery/atmospherics/pipe",
    "/obj/structure/disposalpipe",
    "/obj/structure/disposaljunction",
)


def datum_path(datum):
    return datum.split("{", 1)[0].strip()


def is_excluded(path):
    return any(path == prefix or path.startswith(prefix + "/") for prefix in EXCLUDED_TYPES)


def local_types():
    result = {"/obj", "/mob", "/turf", "/area"}
    for directory in (ROOT / "code", ROOT / "maps"):
        for source in directory.rglob("*.dm"):
            if "unit_test" in str(source):
                continue
            for match in TYPE_DEFINITION.finditer(source.read_text(encoding="latin1")):
                parts = match.group(1).split("/")
                result.update("/".join(parts[:length]) for length in range(2, len(parts) + 1))
    return result


def convert(source, mappings):
    text = source.read_text(encoding="utf-8")
    grid_start = GRID_START.search(text)
    if grid_start is None:
        raise ValueError("Source has no DMM grid")
    dictionary = map_helpers.parse_map(str(source))["dictionary"]
    available = local_types()
    unknown = collections.Counter()
    removed = collections.Counter()
    converted = collections.OrderedDict()
    for key, datums in dictionary.items():
        tile = []
        for datum in datums:
            path = datum_path(datum)
            if is_excluded(path):
                removed[path] += 1
                continue
            target = mappings.get(path, path)
            if target not in available:
                unknown[path] += 1
            tile.append(target + datum[len(path):])
        if sum(datum_path(datum).startswith("/turf/") for datum in tile) != 1:
            raise ValueError("Tile {} must have exactly one turf".format(key))
        if sum(datum_path(datum).startswith("/area/") for datum in tile) != 1:
            raise ValueError("Tile {} must have exactly one area".format(key))
        converted[key] = tuple(tile)
    return converted, text[grid_start.start():], unknown, removed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--mappings", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--output", type=Path, default=ROOT / "maps/cyberiad/cyberiad.dmm")
    arguments = parser.parse_args()
    mappings = json.loads(arguments.mappings.read_text()) if arguments.mappings else {}
    dictionary, grid, unknown, removed = convert(arguments.source, mappings)
    report = {
        "source_commit": SOURCE_COMMIT,
        "source_url": SOURCE_URL,
        "dictionary_tiles": len(dictionary),
        "unresolved_types": dict(sorted(unknown.items())),
        "excluded_types": dict(sorted(removed.items())),
    }
    if arguments.report:
        arguments.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("{} dictionary tiles; {} unresolved types; {} excluded types".format(
        len(dictionary), len(unknown), len(removed)))
    if unknown:
        print("Map output blocked: resolve all types before applying.")
        return 1
    if arguments.apply:
        arguments.output.parent.mkdir(parents=True, exist_ok=True)
        with arguments.output.open("w", encoding="utf-8", newline="\n") as output:
            map_helpers.write_dictionary_tgm(output, dictionary)
            output.write(grid)
    return 0


if __name__ == "__main__":
    sys.exit(main())