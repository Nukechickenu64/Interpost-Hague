"""Repair Alpha's mapped SMES distribution without changing machine placements.

Dry-run by default. --apply changes only power link helpers on live map tiles.
"""

import argparse
import collections
import re
from pathlib import Path

import convert_power


MAP_PATH = Path(__file__).resolve().parents[2] / "maps/alpha/alpha.dmm"
AREA_SMES = "/obj/machinery/power/area_smes"
SMES = "/obj/machinery/power/smes/buildable"
HELPER = "/obj/effect/power_link_helper"
MARKER = "/obj/effect/area_power_marker"
SENSOR = "/obj/machinery/power/sensor"
STATION_BUS = "alpha_station_distribution"
TELECOM_BUS = "alpha_telecom_distribution"
TELECOM_AREA = "AREA_alpha_area_tcommsat_computer"


def string_var(datum, name):
    match = re.search(r'\b' + re.escape(name) + r'\s*=\s*"([^"]*)"',
                      convert_power.datum_vars(datum))
    return match.group(1) if match else None


def target_type(datum):
    match = re.search(r'\btarget_type\s*=\s*([^;}]+)',
                      convert_power.datum_vars(datum))
    return match.group(1).strip() if match else None


def helper(bus, port, machine_type):
    return (HELPER + '{net_tag = "' + bus + '"; port = "' + port
            + '"; target_type = ' + machine_type + '}')


def read_map(path, text):
    convert_power.map_helpers.reset_globals()
    dictionary = convert_power.map_helpers.parse_map(str(path))["dictionary"]
    grid_text = convert_power.GRID_BLOCK.sub(
        lambda match: '({},{},{}) = {{"{}"}}'.format(
            match.group(1), match.group(2), match.group(3),
            match.group(4).strip("\r\n")), text)
    grid = convert_power.read_grid(path, dictionary, grid_text)
    return dictionary, grid


def placements(dictionary, grid):
    return collections.Counter(
        (coord, datum)
        for coord, key in grid.items()
        for datum in dictionary[key]
        if not convert_power.is_path(datum, HELPER))


def repair(dictionary, grid):
    providers = collections.defaultdict(list)
    markers = collections.defaultdict(list)
    storage = collections.Counter()
    for coord, key in grid.items():
        for datum in dictionary[key]:
            if convert_power.is_path(datum, AREA_SMES):
                area_id = string_var(datum, "area_id")
                if not area_id:
                    raise ValueError("Area SMES at {} has no area_id".format(coord))
                providers[area_id].append(coord)
            elif convert_power.is_path(datum, MARKER):
                markers[string_var(datum, "area_id")].append(coord)
            elif convert_power.is_path(datum, SMES):
                storage[string_var(datum, "RCon_tag")] += 1
    expected_storage = collections.Counter({
        "Engine - Core": 1, "Engineering 1": 1, "Engineering 2": 1,
        "Engineering 3": 1, "Telecommunications Satellite": 1,
    })
    if storage != expected_storage:
        raise ValueError("Unexpected Alpha storage layout: {}".format(storage))

    updated = dictionary.copy()
    for key in set(grid.values()):
        objects = dictionary[key]
        area_ids = {string_var(datum, "area_id") for datum in objects
                    if convert_power.is_path(datum, MARKER)
                    or convert_power.is_path(datum, AREA_SMES)}
        has_storage = any(convert_power.is_path(datum, SMES) for datum in objects)
        output_sensor = any(convert_power.is_path(datum, SENSOR)
                            and string_var(datum, "name_tag") == "SMES Output"
                            for datum in objects)
        kept = []
        for datum in objects:
            if convert_power.datum_path(datum) == HELPER:
                wanted_type = target_type(datum)
                area_helper = wanted_type and wanted_type.startswith(AREA_SMES)
                storage_helper = wanted_type and wanted_type.startswith(SMES)
                if area_helper and any(area_id in providers for area_id in area_ids):
                    continue
                if storage_helper and has_storage:
                    continue
                if output_sensor and wanted_type == SENSOR:
                    continue
            kept.append(datum)
        for datum in objects:
            machine_type = convert_power.datum_path(datum)
            if convert_power.is_path(datum, AREA_SMES):
                area_id = string_var(datum, "area_id")
                bus = TELECOM_BUS if area_id == TELECOM_AREA else STATION_BUS
                kept.append(helper(bus, "in", machine_type))
            elif convert_power.is_path(datum, SMES):
                name = string_var(datum, "RCon_tag")
                if name == "Engine - Core":
                    input_bus, output_bus = "alpha_net_27", "alpha_net_146"
                elif name == "Telecommunications Satellite":
                    input_bus, output_bus = STATION_BUS, TELECOM_BUS
                else:
                    input_bus, output_bus = "alpha_net_146", STATION_BUS
                kept.extend((helper(input_bus, "in", machine_type),
                             helper(output_bus, "out", machine_type)))
        if output_sensor:
            kept.append(helper(STATION_BUS, "in", SENSOR))
        updated[key] = tuple(kept)
    if placements(dictionary, grid) != placements(updated, grid):
        raise ValueError("Repair would change a machine, marker or other map object")
    return updated, providers, markers


def rewrite_dictionary(text, before, after):
    changed = {key for key in before if before[key] != after[key]}
    replaced = set()
    entry_pattern = re.compile(r'^"([A-Za-z]+)"\s*=\s*\(.*\)\r?$', re.M)

    def replace(match):
        key = match.group(1)
        if key not in changed:
            return match.group(0)
        replaced.add(key)
        return '"{}" = ({})'.format(key, ",".join(after[key]))

    result = entry_pattern.sub(replace, text)
    if replaced != changed:
        raise ValueError("Could not locate changed single-line dictionary entries")
    return result, len(changed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    text = MAP_PATH.read_text(encoding="cp1252")
    dictionary, grid = read_map(MAP_PATH, text)
    updated, providers, markers = repair(dictionary, grid)
    result, count = rewrite_dictionary(text, dictionary, updated)
    print("{} live APC SMES placements preserved; {} dictionary entries {}".format(
        sum(map(len, providers.values())), count,
        "changed" if args.apply else "would change"))
    for area_id in sorted(markers.keys() - providers.keys()):
        print("Missing provider left unchanged: {} at {}".format(area_id, markers[area_id]))
    duplicates = {area_id: coords for area_id, coords in providers.items() if len(coords) > 1}
    print("{} duplicate area IDs left unchanged".format(len(duplicates)))
    for area_id, coords in sorted(duplicates.items()):
        print("Duplicate: {} at {}".format(area_id, coords))
    if args.apply and result != text:
        with MAP_PATH.open("w", encoding="cp1252", newline="\n") as output:
            output.write(result)


if __name__ == "__main__":
    main()