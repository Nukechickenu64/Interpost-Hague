#!/usr/bin/env python3
"""Convert a DMM vehicle layout into a Civ13 vehicle preset definition.

Example:
    python tools/dmm_to_vehicle_preset.py layout.dmm --name "Field Car"
"""

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP_HELPERS = ROOT / "tools/mapmerge_backup/mapmergepy"
sys.path.insert(0, str(MAP_HELPERS))
import map_helpers

GRID_BLOCK = re.compile(r'\((\d+),(\d+),(\d+)\)\s*=\s*\{"(.*?)"\}', re.S)
AXIS_ROOT = "/obj/structure/vehicleparts/axis"
PART_ROOT = "/obj/structure/vehicleparts"
SEAT_ROOT = "/obj/structure/bed/chair/civ13"
PRESET_ROOT = "/obj/effect/civ13_vehicle"


def datum_path(datum):
    return datum.split("{", 1)[0].strip()


def read_grid(text, dictionary):
    grid = {}
    key_width = len(next(iter(dictionary)))
    for match in GRID_BLOCK.finditer(text):
        start_x, start_y, z_level = (int(match.group(index)) for index in (1, 2, 3))
        row_index = 0
        for row in match.group(4).splitlines():
            row = row.strip()
            if not row:
                continue
            if len(row) % key_width:
                raise ValueError("map grid row length is not divisible by DMM key width")
            for column in range(0, len(row), key_width):
                key = row[column:column + key_width]
                if key not in dictionary:
                    raise ValueError("grid references missing DMM dictionary key " + key)
                coord = (start_x + column // key_width, start_y + row_index, z_level)
                grid[coord] = key
            row_index += 1
    if not grid:
        raise ValueError("no DMM grid blocks were found")
    return grid


def is_supported_part(path):
    return (
        path.startswith(PART_ROOT + "/")
        and not path.startswith(AXIS_ROOT + "/")
    ) or path.startswith(SEAT_ROOT + "/")


def dm_string(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def slug(value):
    result = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_").lower()
    if not result:
        raise ValueError("name must contain at least one letter or number")
    return result


def convert(path, name, preset_path):
    text = path.read_text(encoding="cp1252")
    map_helpers.reset_globals()
    dictionary = map_helpers.parse_map(str(path))["dictionary"]
    if not dictionary:
        raise ValueError("map contains no DMM dictionary entries")
    grid = read_grid(text, dictionary)

    axes = []
    components = defaultdict(list)
    for coord, key in grid.items():
        for datum in dictionary[key]:
            object_path = datum_path(datum)
            if object_path == AXIS_ROOT or object_path.startswith(AXIS_ROOT + "/"):
                axes.append((coord, object_path, datum))
            elif is_supported_part(object_path):
                components[coord].append((object_path, datum))

    if len(axes) != 1:
        raise ValueError("expected exactly one vehicle axis in the DMM; found {}".format(len(axes)))
    if not components:
        raise ValueError("no vehicle parts or Civ13 seats were found in the DMM")

    axis_coord, axis_type, axis_datum = axes[0]
    selected = [(axis_datum, axis_coord)]
    selected.extend((datum, coord) for coord, entries in components.items() for _, datum in entries)
    edited = [datum_path(datum) for datum, _ in selected if "{" in datum]
    if edited:
        raise ValueError(
            "vehicle datums contain map variable overrides that presets cannot preserve: "
            + ", ".join(sorted(set(edited)))
        )

    if any(coord[2] != axis_coord[2] for coord in components):
        raise ValueError("vehicle axis and components must be on the same z-level")
    min_x = min(coord[0] for coord in components)
    min_y = min(coord[1] for coord in components)
    max_x = max(coord[0] for coord in components)
    max_y = max(coord[1] for coord in components)
    if axis_coord[0] > min_x or axis_coord[1] > min_y:
        raise ValueError("vehicle axis must be at or southwest of every component")

    lines = [
        preset_path,
        "\tname = " + dm_string(name),
        "\taxis_type = " + axis_type,
        "\ttocreate = list(",
    ]
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            entries = components.get((x, y, axis_coord[2]))
            if not entries:
                continue
            coordinate = "{},{}".format(x - axis_coord[0] + 1, y - axis_coord[1] + 1)
            types = ", ".join(object_path for object_path, _ in entries)
            lines.append("\t\t{} = list({}),".format(dm_string(coordinate), types))
    lines.append("\t)")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dmm", type=Path, help="DMM containing exactly one laid-out vehicle")
    parser.add_argument("--name", help="display name for the preset (defaults to the DMM filename)")
    parser.add_argument("--preset-path", help="DM type path (defaults to a path derived from --name)")
    parser.add_argument("--output", type=Path, help="write the generated definition to a file")
    args = parser.parse_args()

    try:
        name = args.name or args.dmm.stem.replace("_", " ").title()
        preset_path = args.preset_path or PRESET_ROOT + "/" + slug(name)
        if not re.fullmatch(r"/obj/effect/civ13_vehicle(?:/[A-Za-z0-9_]+)+", preset_path):
            raise ValueError("preset path must be a subtype of " + PRESET_ROOT)
        output = convert(args.dmm, name, preset_path)
        if args.output:
            args.output.write_text(output, encoding="utf-8", newline="\n")
            print("Wrote " + str(args.output))
        else:
            sys.stdout.write(output)
    except (OSError, UnicodeError, ValueError, KeyError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()