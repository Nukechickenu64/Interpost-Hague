#!/usr/bin/env python3
"""Remove selected legacy atmos equipment from alpha; dry-run unless --apply."""

import argparse
from collections import Counter
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/mapmerge_backup/mapmergepy"))
import map_helpers

MAP = ROOT / "maps/alpha/alpha.dmm"
REMOVE_ROOTS = (
    "/obj/machinery/atmospherics",
    "/obj/machinery/meter",
    "/obj/machinery/air_sensor",
    "/obj/machinery/computer/atmos_alert",
    "/obj/machinery/computer/general_air_control",
    "/obj/machinery/pipedispenser",
    "/obj/item/device/pipe_painter",
    "/obj/structure/disposalpipe",
)
KEEP_ROOTS = (
    "/obj/machinery/pipedispenser/disposal",
    "/obj/machinery/atmospherics/unary/vent_pump",
    "/obj/machinery/atmospherics/unary/vent_scrubber",
)
DEFINITION = re.compile(r'^"([A-Za-z]+)" = \(([^\r\n]*)\)(?=\r?$)', re.M)
GRID = re.compile(r'\((\d+),(\d+),(\d+)\)\s*=\s*\{"(.*?)"\}', re.S)


def datum_path(datum):
    return datum.split("{", 1)[0].strip()


def matches_root(path, roots):
    return any(path == root or path.startswith(root + "/") for root in roots)


def should_remove(datum):
    path = datum_path(datum)
    return matches_root(path, REMOVE_ROOTS) and not matches_root(path, KEEP_ROOTS)


def parse_dictionary(path):
    map_helpers.reset_globals()
    return map_helpers.parse_map(str(path))["dictionary"]


def restore_vents(apply):
    sys.path.insert(0, str(ROOT / "tools/power_convert"))
    import link_alpha

    vent_roots = KEEP_ROOTS[1:]
    original_bytes = MAP.read_bytes()
    text = original_bytes.decode("cp1252")
    dictionary, grid = link_alpha.read_map(MAP, text)
    source_text = subprocess.check_output(
        ["git", "show", "HEAD:maps/alpha/alpha.dmm"], cwd=ROOT).decode("cp1252")
    with tempfile.TemporaryDirectory(prefix="alpha_vents_") as temporary:
        source_path = Path(temporary) / "source.dmm"
        source_path.write_bytes(source_text.encode("cp1252"))
        source, source_grid = link_alpha.read_map(source_path, source_text)

        def vents(datums):
            return tuple(datum for datum in datums if matches_root(datum_path(datum), vent_roots))

        if any(vents(source[key]) and coord not in grid for coord, key in source_grid.items()):
            raise ValueError("Original vent coordinates are missing from the current map")
        updated = dictionary.copy()
        updated_grid = grid.copy()
        known = {datums: key for key, datums in dictionary.items()}
        expected_vents = {}
        added = 0
        next_key = ""
        map_helpers.key_length = len(next(iter(dictionary)))
        for coord, key in grid.items():
            existing = vents(dictionary[key])
            wanted = existing or vents(source[source_grid[coord]]) if coord in source_grid else existing
            expected_vents[coord] = wanted
            if existing or not wanted:
                continue
            datums = dictionary[key]
            insertion = next(index for index, datum in enumerate(datums)
                             if datum_path(datum).startswith("/turf/"))
            restored = datums[:insertion] + wanted + datums[insertion:]
            if restored not in known:
                next_key = map_helpers.get_next_key(next_key)
                while next_key in updated:
                    next_key = map_helpers.get_next_key(next_key)
                if next_key == "OVERFLOW":
                    raise ValueError("No free dictionary keys available")
                updated[next_key] = restored
                known[restored] = next_key
            updated_grid[coord] = known[restored]
            added += len(wanted)

        def replace_grid(match):
            start_x, start_y, level = (int(match.group(index)) for index in (1, 2, 3))
            rows = []
            row_index = 0
            width = len(next(iter(dictionary)))
            for line in match.group(4).splitlines(keepends=True):
                row = line.rstrip("\r\n")
                if row:
                    row = "".join(updated_grid[start_x + column // width, start_y + row_index, level]
                                  for column in range(0, len(row), width))
                    row_index += 1
                rows.append(row + line[len(line.rstrip("\r\n")):])
            start = match.start(4) - match.start()
            end = match.end(4) - match.start()
            return match.group(0)[:start] + "".join(rows) + match.group(0)[end:]

        result = GRID.sub(replace_grid, text)
        new_definitions = "".join('"{}" = ({})\n'.format(key, ",".join(datums))
                                  for key, datums in updated.items() if key not in dictionary)
        position = GRID.search(result).start()
        result = result[:position] + new_definitions + result[position:]
        candidate = Path(temporary) / "candidate.dmm"
        candidate.write_bytes(result.encode("cp1252"))
        checked, checked_grid = link_alpha.read_map(candidate, result)
        if checked != updated or checked_grid != updated_grid:
            raise ValueError("Restored map did not reparse as expected")
        if grid.keys() != checked_grid.keys():
            raise ValueError("Tile coordinates changed")
        for coord, key in grid.items():
            after = checked[checked_grid[coord]]
            before_other = tuple(datum for datum in dictionary[key]
                                 if not matches_root(datum_path(datum), vent_roots))
            after_other = tuple(datum for datum in after
                                if not matches_root(datum_path(datum), vent_roots))
            if before_other != after_other or vents(after) != expected_vents[coord]:
                raise ValueError("Restoration changed unrelated objects at " + str(coord))
    print("{} vents/scrubbers restored; {} existing preserved".format(
        added, sum(len(vents(dictionary[key])) for key in grid.values())))
    print("Verified: all other objects and tile coordinates unchanged")
    if apply and result != text:
        if MAP.read_bytes() != original_bytes:
            raise ValueError("Map changed while processing; refusing to overwrite")
        MAP.write_bytes(result.encode("cp1252"))
        print("Updated " + str(MAP.relative_to(ROOT)))
    else:
        print("No changes" if result == text else "Dry-run; pass --apply to write")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Rewrite the alpha map")
    parser.add_argument("--restore-vents", action="store_true",
                        help="Restore missing vents/scrubbers from HEAD, preserving existing ones")
    args = parser.parse_args()
    if args.restore_vents:
        restore_vents(args.apply)
        return
    original_bytes = MAP.read_bytes()
    original = original_bytes.decode("cp1252")
    dictionary = parse_dictionary(MAP)
    definitions = list(DEFINITION.finditer(original))
    if len(definitions) != len(dictionary):
        raise ValueError("Expected inline DMM definitions; refusing to rewrite this format")
    key_widths = {len(key) for key in dictionary}
    if len(key_widths) != 1:
        raise ValueError("Inconsistent DMM key widths")
    key_width = key_widths.pop()
    usage = Counter()
    grid_blocks = list(GRID.finditer(original))
    if not grid_blocks:
        raise ValueError("No coordinate blocks found")
    for block in grid_blocks:
        for row in block.group(4).splitlines():
            if not row:
                continue
            if len(row) % key_width:
                raise ValueError("Invalid grid row width")
            usage.update(row[index:index + key_width] for index in range(0, len(row), key_width))
    if usage.keys() - dictionary.keys():
        raise ValueError("Grid references undefined tile keys")
    expected = {}
    removed = Counter()
    removed_definitions = Counter()
    changed_keys = set()
    for key, datums in dictionary.items():
        expected[key] = tuple(datum for datum in datums if not should_remove(datum))
        if expected[key] != datums:
            changed_keys.add(key)
        for datum in datums:
            if should_remove(datum):
                removed[datum_path(datum)] += usage[key]
                removed_definitions[datum_path(datum)] += 1

    def replace_definition(match):
        key = match.group(1)
        if key not in changed_keys:
            return match.group(0)
        if ",".join(dictionary[key]) != match.group(2):
            raise ValueError("Parser did not preserve original definition: " + key)
        if not any(datum_path(datum).startswith("/turf/") for datum in expected[key]):
            raise ValueError("Removal would leave a tile without a turf: " + key)
        return '"{}" = ({})'.format(key, ",".join(expected[key]))

    result = DEFINITION.sub(replace_definition, original)
    if [block.group(0) for block in GRID.finditer(result)] != [block.group(0) for block in grid_blocks]:
        raise ValueError("Coordinate blocks changed")
    with tempfile.TemporaryDirectory(prefix="alpha_atmos_") as temporary:
        candidate = Path(temporary) / "alpha.dmm"
        candidate.write_bytes(result.encode("cp1252"))
        if parse_dictionary(candidate) != expected:
            raise ValueError("Reparsed map does not match the intended object removal")
    for path in sorted(removed_definitions):
        print("{}: {} placed, {} dictionary entries".format(path, removed[path], removed_definitions[path]))
    print("{} placed objects removed; {} definitions changed; {} tiles preserved".format(
        sum(removed.values()), len(changed_keys), sum(usage.values())))
    print("Verified: non-target objects, tile keys, and coordinate blocks unchanged")
    if args.apply and result != original:
        if MAP.read_bytes() != original_bytes:
            raise ValueError("Map changed while processing; refusing to overwrite")
        MAP.write_bytes(result.encode("cp1252"))
        print("Updated " + str(MAP.relative_to(ROOT)))
    else:
        print("No changes" if result == original else "Dry-run; pass --apply to write")


if __name__ == "__main__":
    main()