#!/usr/bin/env python3
"""Convert legacy DMM cable/APC power layouts to CCID-link helpers.

Dry-run by default. Add --apply to rewrite selected maps. --from-git reads source maps
from a clean revision so already-converted maps can be regenerated after converter fixes.
"""

import argparse
import collections
import os
import re
import subprocess
import sys
import tempfile
import traceback
from pathlib import Path

MAP_HELPERS = Path(__file__).resolve().parents[1] / "mapmerge_backup" / "mapmergepy"
sys.path.insert(0, str(MAP_HELPERS))
import map_helpers

CABLE_PATH = "/obj/structure/cable"
TERMINAL_PATH = "/obj/machinery/power/terminal"
APC_PATH = "/obj/machinery/power/apc"
SMES_PATH = "/obj/machinery/power/smes"
POWER_PATH = "/obj/machinery/power"

DIRECTIONS = {
    1: (0, 1), 2: (0, -1), 4: (1, 0), 8: (-1, 0),
    5: (1, 1), 6: (1, -1), 9: (-1, 1), 10: (-1, -1),
    16: (0, 0), 32: (0, 0),
}
REVERSE = {
    1: 2, 2: 1, 4: 8, 8: 4, 5: 10, 10: 5, 6: 9, 9: 6, 16: 32, 32: 16,
}
DELTA_TO_DIR = {delta: direction for direction, delta in DIRECTIONS.items() if direction in (1, 2, 4, 8, 5, 6, 9, 10)}
GRID_BLOCK = re.compile(r'\((\d+),(\d+),(\d+)\)\s*=\s*\{"(.*?)"\}', re.S)
TYPE_LINE = re.compile(r'^\s*(/obj(?:/[A-Za-z0-9_+]+)+)(?=\s|\(|$)', re.M)
VALID_OBJECT_TYPES = None


def datum_path(datum):
    return datum.split("{", 1)[0].strip()


def datum_vars(datum):
    if "{" not in datum:
        return ""
    return datum.split("{", 1)[1].rsplit("}", 1)[0]


def is_path(datum, path):
    value = datum_path(datum)
    return value == path or value.startswith(path + "/")


def get_valid_object_types():
    global VALID_OBJECT_TYPES
    if VALID_OBJECT_TYPES is not None:
        return VALID_OBJECT_TYPES
    code_root = Path(__file__).resolve().parents[2] / "code"
    valid = {"/obj"}
    for source in code_root.rglob("*.dm"):
        try:
            text = source.read_text(encoding="cp1252")
        except (OSError, UnicodeError):
            continue
        for match in TYPE_LINE.finditer(text):
            path = match.group(1)
            parts = path.split("/")
            valid.update("/".join(parts[:index]) for index in range(2, len(parts) + 1))
    VALID_OBJECT_TYPES = valid
    return valid


def normalize_object_datum(datum, valid_types):
    original_path = datum_path(datum)
    if not original_path.startswith("/obj/") or original_path in valid_types:
        return datum
    candidates = []
    if original_path.startswith("/obj/item/weapon/"):
        candidates.append(original_path.replace("/obj/item/weapon/", "/obj/item/", 1))
    candidates.append(original_path)
    for candidate in candidates:
        if candidate in valid_types:
            return datum.replace(original_path, candidate, 1)
        parent = candidate
        while "/" in parent[1:]:
            parent = parent.rsplit("/", 1)[0]
            if parent in valid_types:
                return datum.replace(original_path, parent, 1)
    return datum


def path_subtype(value, old, new):
    path = datum_path(value)
    return value.replace(path, path.replace(old, new, 1), 1)


def cable_dirs(datum):
    match = re.search(r'icon_state\s*=\s*"(\d+)-(\d+)"', datum_vars(datum))
    if not match:
        return None
    return int(match.group(1)), int(match.group(2))


def node_port(machine):
    path = datum_path(machine)
    if path.startswith(APC_PATH):
        return "in"
    if path.startswith(SMES_PATH):
        return "out"
    if path.startswith("/obj/machinery/power/solar_control"):
        return "in"
    if path.startswith("/obj/machinery/power/fusion_core"):
        return "both"
    producer_fragments = (
        "/solar", "/port_gen", "/generator", "/turbine", "/rad_collector",
        "/singularity/generator", "/antimatter/engine", "/antimatter/control", "/turbinemotor",
        "/debug_items/infinite_generator",
    )
    if any(fragment in path for fragment in producer_fragments):
        return "out"
    return "in"


def connected_tiles(coord, directions, cables):
    x, y, z = coord
    result = set()

    for direction in directions:
        if direction == 0 or direction not in DIRECTIONS:
            continue
        dx, dy = DIRECTIONS[direction]
        adjacent = (x + dx, y + dy, z + (1 if direction == 16 else -1 if direction == 32 else 0))
        reverse = REVERSE.get(direction)
        if adjacent in cables and reverse in cables[adjacent]:
            result.add(adjacent)

        if direction in (5, 6, 9, 10):
            for pair in (3, 12):
                leg = direction & pair
                if leg not in DIRECTIONS:
                    continue
                adjacent = (x + DIRECTIONS[leg][0], y + DIRECTIONS[leg][1], z)
                required = direction ^ pair
                if adjacent in cables and required in cables[adjacent]:
                    result.add(adjacent)

    return result


def scan_tile(dictionary, key):
    objects = list(dictionary[key])
    area_path = next((datum_path(item) for item in objects if is_path(item, "/area")), None)
    return objects, area_path


def read_grid(path, dictionary, text=None):
    if text is None:
        text = Path(path).read_text(encoding="cp1252")
    grid = {}
    z_levels = set()
    key_length = len(next(iter(dictionary)))
    for match in GRID_BLOCK.finditer(text):
        start_x, start_y, z_level = (int(match.group(index)) for index in (1, 2, 3))
        z_levels.add(z_level)
        rows = match.group(4).splitlines()
        for row_index, row in enumerate(rows):
            row = row.strip()
            if not row:
                continue
            if len(row) % key_length:
                raise ValueError("map grid row length is not divisible by DMM key width")
            y = start_y + row_index
            for column in range(0, len(row), key_length):
                x = start_x + column // key_length
                key = row[column:column + key_length]
                if key not in dictionary:
                    raise ValueError("grid references missing DMM dictionary key {}".format(key))
                grid[x, y, z_level] = key
    if not z_levels:
        raise ValueError("no DMM grid blocks were found")
    map_helpers.maxx = max((x for x, _, _ in grid), default=0)
    map_helpers.maxy = max((y for _, y, _ in grid), default=0)
    map_helpers.key_length = key_length
    return grid


def write_multiz_grid(output, grid, default_key):
    for z_level in sorted({z for _, _, z in grid}):
        z_cells = [(x, y) for x, y, z in grid if z == z_level]
        min_x = min(x for x, _ in z_cells)
        max_x = max(x for x, _ in z_cells)
        min_y = min(y for _, y in z_cells)
        max_y = max(y for _, y in z_cells)
        output.write("\n({},{},{}) = {{\"\n".format(min_x, min_y, z_level))
        for y in range(min_y, max_y + 1):
            output.write("".join(grid.get((x, y, z_level), default_key) for x in range(min_x, max_x + 1)))
            output.write("\n")
        output.write("\"}\n")


def rekey_dictionary(dictionary, grid):
    old_key_length = map_helpers.key_length
    map_helpers.key_length = old_key_length + 1
    new_dictionary = collections.OrderedDict()
    key_map = {}
    last_key = ""
    for old_key, value in dictionary.items():
        new_key = map_helpers.get_next_key(last_key)
        if new_key == "OVERFLOW":
            raise ValueError("DMM dictionary key space exhausted after widening")
        new_dictionary[new_key] = value
        key_map[old_key] = new_key
        last_key = new_key
    new_grid = {coord: key_map[key] for coord, key in grid.items()}
    return new_dictionary, new_grid


def convert_map(path, apply=False, source_text=None):
    path = Path(path)
    parts = list(path.parts)
    maps_index = max((index for index, part in enumerate(parts) if part.lower() == "maps"), default=-1)
    namespace_parts = parts[maps_index + 1:-1] if maps_index >= 0 else []
    if not namespace_parts or namespace_parts[-1].lower() != path.stem.lower():
        namespace_parts.append(path.stem)
    map_namespace = re.sub(r"[^A-Za-z0-9]+", "_", "_".join(namespace_parts)).strip("_")
    text = source_text if source_text is not None else Path(path).read_text(encoding="cp1252")
    if not any(marker in text for marker in (CABLE_PATH, APC_PATH, TERMINAL_PATH)) and "/obj/effect/power_link_helper" not in text:
        return {"path": path, "changed": False, "cables": 0, "apcs": 0, "terminals": 0, "helpers": 0}
    map_helpers.reset_globals()
    temp_path = None
    if source_text is None:
        parsed = map_helpers.parse_map(str(path))
    else:
        with tempfile.NamedTemporaryFile("w", encoding="cp1252", newline="\n", suffix=".dmm", delete=False) as source_file:
            source_file.write(source_text)
            temp_path = source_file.name
        try:
            parsed = map_helpers.parse_map(temp_path)
        finally:
            Path(temp_path).unlink(missing_ok=True)
    dictionary = parsed["dictionary"]
    grid = read_grid(path, dictionary, text)
    if not dictionary or not grid:
        raise ValueError("map parser returned an empty map")
    valid_types = get_valid_object_types()
    used_dictionary_keys = set(grid.values())
    stale_legacy_keys = {
        key for key, objects in dictionary.items()
        if key not in used_dictionary_keys and any(
            is_path(item, CABLE_PATH) or is_path(item, APC_PATH) or is_path(item, TERMINAL_PATH)
            for item in objects
        )
    }

    tiles = {}
    cables = {}
    apc_areas = collections.defaultdict(list)
    cable_count = 0
    apc_count = 0
    terminal_count = 0
    helper_count = 0

    for coord, key in grid.items():
        objects, area_path = scan_tile(dictionary, key)
        tiles[coord] = (key, objects, area_path)
        dirs = [cable_dirs(item) for item in objects if is_path(item, CABLE_PATH)]
        dirs = [pair for pair in dirs if pair]
        if dirs:
            cables[coord] = set(direction for pair in dirs for direction in pair)
            cable_count += len(dirs)
        for item in objects:
            if is_path(item, APC_PATH):
                area_key = area_path or "unknown_{}_{}_{}".format(*coord)
                apc_areas[area_key].append((coord, item))
                apc_count += 1
            if is_path(item, TERMINAL_PATH):
                terminal_count += 1

    components = []
    unseen = set(cables)
    while unseen:
        start = unseen.pop()
        component = {start}
        pending = [start]
        while pending:
            current = pending.pop()
            directions = cables[current]
            for neighbor in connected_tiles(current, directions, cables):
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    component.add(neighbor)
                    pending.append(neighbor)
        components.append(component)

    component_for_tile = {}
    for number, component in enumerate(components, 1):
        for coord in component:
            component_for_tile[coord] = number

    component_sources = collections.Counter()
    for coord, (_, objects, _) in tiles.items():
        component_number = component_for_tile.get(coord)
        if not component_number or coord not in cables or 0 not in cables[coord]:
            continue
        for machine in objects:
            if not is_path(machine, POWER_PATH) or is_path(machine, TERMINAL_PATH) or is_path(machine, "/obj/machinery/power/breakerbox"):
                continue
            if node_port(machine) in ("out", "both"):
                component_sources[component_number] += 1

    breaker_connections = collections.defaultdict(list)
    for coord, (_, objects, _) in tiles.items():
        breaker_paths = [datum_path(item) for item in objects if is_path(item, "/obj/machinery/power/breakerbox")]
        if not breaker_paths:
            continue
        x, y, z = coord
        neighbors = set()
        if coord in component_for_tile:
            neighbors.add(component_for_tile[coord])
        for (nx, ny, nz), directions in cables.items():
            if nz != z:
                continue
            direction = DELTA_TO_DIR.get((nx - x, ny - y))
            if direction and REVERSE[direction] in directions:
                component_number = component_for_tile.get((nx, ny, nz))
                if component_number:
                    neighbors.add(component_number)
        if len(neighbors) < 2:
            continue
        source_components = [component for component in neighbors if component_sources[component]]
        if source_components:
            input_components = set(source_components)
            output_components = neighbors - input_components
            if not output_components:
                strongest_source = max(source_components, key=lambda component: component_sources[component])
                input_components.remove(strongest_source)
                output_components.add(strongest_source)
        else:
            input_components = {min(neighbors)}
            output_components = neighbors - input_components
        for breaker_path in breaker_paths:
            for component in input_components:
                breaker_connections[coord].append((breaker_path, component, "in"))
            for component in output_components:
                breaker_connections[coord].append((breaker_path, component, "out"))

    area_smes_ids = {}
    primary_apc_tile = {}
    for area_path, apcs in apc_areas.items():
        area_id = "AREA_{}_{}".format(map_namespace, re.sub(r"[^A-Za-z0-9]+", "_", area_path).strip("_"))
        area_smes_ids[area_path] = area_id
        primary_apc_tile[area_path] = apcs[0][0]

    changed_tiles = {}
    seen_areas = set()
    helper_tags = collections.defaultdict(set)
    helper_ports = {}
    for coord, (key, objects, area_path) in tiles.items():
        output = []
        apc_here = False
        terminal_here = any(is_path(item, TERMINAL_PATH) for item in objects)
        area_key = area_path or "unknown_{}_{}_{}".format(*coord)
        power_machines = [
            item for item in objects
            if is_path(item, POWER_PATH) and not is_path(item, TERMINAL_PATH)
            and not is_path(item, "/obj/machinery/power/breakerbox")
            and (not is_path(item, APC_PATH) or primary_apc_tile.get(area_key) == coord)
        ]

        for item in objects:
            if is_path(item, CABLE_PATH) or is_path(item, TERMINAL_PATH):
                continue
            if is_path(item, "/obj/effect/power_link_helper"):
                helper_vars = datum_vars(item)
                target_match = re.search(r'target_type\s*=\s*([^;]+)', helper_vars)
                port_match = re.search(r'port\s*=\s*"([^"]+)"', helper_vars)
                tag_match = re.search(r'net_tag\s*=\s*"([^"]+)"', helper_vars)
                if tag_match:
                    tag_suffix = tag_match.group(1)
                    while tag_suffix.startswith(map_namespace + "_"):
                        tag_suffix = tag_suffix[len(map_namespace) + 1:]
                    normalized_tag = "{}_{}".format(map_namespace, tag_suffix)
                    if normalized_tag != tag_match.group(1):
                        item = item.replace('net_tag="{}"'.format(tag_match.group(1)), 'net_tag="{}"'.format(normalized_tag), 1)
                    helper_vars = datum_vars(item)
                    target_match = re.search(r'target_type\s*=\s*([^;]+)', helper_vars)
                    port_match = re.search(r'port\s*=\s*"([^"]+)"', helper_vars)
                if target_match and port_match:
                    target_path = datum_path(target_match.group(1).strip())
                    if target_path in (
                        "/obj/machinery/power/solar_control", "/obj/machinery/power/fusion_core",
                        "/obj/machinery/power/antimatter/control", "/obj/machinery/power/turbinemotor",
                    ):
                        wanted_port = node_port(target_path)
                    elif target_path.startswith(SMES_PATH) and port_match.group(1) == "both":
                        wanted_port = "out"
                    else:
                        wanted_port = port_match.group(1)
                    if target_match and port_match and port_match.group(1) != wanted_port:
                        item = item.replace('port="{}"'.format(port_match.group(1)), 'port="{}"'.format(wanted_port), 1)
                output.append(item)
                continue
            if is_path(item, "/obj/machinery/power/area_smes") or is_path(item, "/obj/effect/area_power_marker"):
                area_id_match = re.search(r'area_id\s*=\s*"([^"]+)"', datum_vars(item))
                if area_id_match:
                    old_id = area_id_match.group(1)
                    id_suffix = old_id
                    prefix = "AREA_{}_".format(map_namespace)
                    while id_suffix.startswith(prefix):
                        id_suffix = id_suffix[len(prefix):]
                    if id_suffix.startswith("AREA_"):
                        id_suffix = id_suffix[len("AREA_"):]
                    new_id = prefix + id_suffix
                    if new_id != old_id:
                        item = item.replace('area_id="{}"'.format(old_id), 'area_id="{}"'.format(new_id), 1)
                output.append(item)
                continue
            if is_path(item, APC_PATH):
                if area_key in seen_areas:
                    continue
                seen_areas.add(area_key)
                item = path_subtype(item, APC_PATH, "/obj/machinery/power/area_smes")
                area_id = area_smes_ids[area_key]
                if "{" in item:
                    item = item[:-1] + ";area_id=\"" + area_id + "\"}"
                else:
                    item += "{area_id=\"" + area_id + "\"}"
                output.append(item)
                marker = '/obj/effect/area_power_marker{area_id="' + area_id + '"}'
                output.append(marker)
                apc_here = True
                continue
            output.append(normalize_object_datum(item, valid_types))

        component_number = component_for_tile.get(coord)
        node_cable = coord in cables and 0 in cables[coord]
        for breaker_path, breaker_component, breaker_port in breaker_connections.get(coord, []):
            tag = "{}_net_{}".format(map_namespace, breaker_component)
            helper_tags[tag].add((coord, breaker_path, breaker_port))
        if component_number and (node_cable or terminal_here):
            for machine in power_machines:
                port = node_port(machine)
                target_path = datum_path(machine)
                if target_path.startswith(APC_PATH):
                    target_path = target_path.replace(APC_PATH, "/obj/machinery/power/area_smes", 1)
                tag = "{}_net_{}".format(map_namespace, component_number)
                helper_tags[tag].add((coord, target_path, port))
                helper_ports[(coord, target_path, port, tag)] = True
            if terminal_here:
                x, y, z = coord
                for dx, dy in ((0, 0), (0, 1), (0, -1), (1, 0), (-1, 0)):
                    smes_coord = (x + dx, y + dy, z)
                    if smes_coord not in tiles:
                        continue
                    _, smes_objects, _ = tiles[smes_coord]
                    for machine in smes_objects:
                        if is_path(machine, SMES_PATH):
                            tag = "{}_net_{}".format(map_namespace, component_number)
                            helper_tags[tag].add((smes_coord, datum_path(machine), "in"))

        if output != objects:
            changed_tiles[coord] = tuple(output)

    for tag, members in helper_tags.items():
        for coord, target_path, port in members:
            key, objects, area_path = tiles[coord]
            helper = '/obj/effect/power_link_helper{net_tag="' + tag + '";port="' + port + '";target_type=' + target_path + '}'
            changed_tiles[coord] = tuple(list(changed_tiles.get(coord, objects)) + [helper])
            helper_count += 1

    if not changed_tiles and not stale_legacy_keys:
        return {"path": path, "changed": False, "cables": cable_count, "apcs": apc_count, "terminals": terminal_count, "helpers": helper_count}

    rewritten = collections.OrderedDict(dictionary)
    new_grid = dict(grid)
    needs_rekey = False
    for coord, objects in changed_tiles.items():
        old_key = grid[coord]
        old_objects = dictionary[old_key]
        # DMM dictionary entries can be shared by many coordinates; insert a new key only when needed.
        key = next((candidate for candidate, value in rewritten.items() if value == objects), None)
        if key is None:
            key = map_helpers.generate_new_key(rewritten)
            if key == "OVERFLOW":
                needs_rekey = True
                break
            rewritten[key] = objects
        new_grid[coord] = key
    if needs_rekey:
        rewritten, new_grid = rekey_dictionary(rewritten, new_grid)
        for coord, objects in changed_tiles.items():
            key = next((candidate for candidate, value in rewritten.items() if value == objects), None)
            if key is None:
                key = map_helpers.generate_new_key(rewritten)
                if key == "OVERFLOW":
                    raise ValueError("DMM dictionary key space exhausted after widening")
                rewritten[key] = objects
            new_grid[coord] = key
    used_keys = set(new_grid.values())
    rewritten = collections.OrderedDict((key, value) for key, value in rewritten.items() if key in used_keys)

    if apply:
        with open(path, "w", encoding="cp1252", newline="\n") as output:
            map_helpers.write_dictionary_dmm(output, rewritten)
            default_key = next(iter(rewritten))
            write_multiz_grid(output, new_grid, default_key)

    return {"path": path, "changed": True, "cables": cable_count, "apcs": apc_count, "terminals": terminal_count, "helpers": helper_count}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="DMM files or directories; defaults to maps/")
    parser.add_argument("--apply", action="store_true", help="rewrite maps (default is dry-run)")
    parser.add_argument("--from-git", metavar="REV", help="read each source DMM from this git revision")
    args = parser.parse_args()
    targets = args.paths or ["maps"]
    files = []
    for value in targets:
        candidate = Path(value)
        if candidate.is_file() and candidate.suffix.lower() == ".dmm":
            files.append(candidate)
        elif candidate.is_dir():
            files.extend(candidate.rglob("*.dmm"))
        else:
            print("Skipping missing or unsupported path: {}".format(candidate), file=sys.stderr)

    converted = 0
    failures = 0
    for path in sorted(set(files)):
        try:
            source_text = None
            if args.from_git:
                relative_path = os.path.relpath(path.resolve(), Path.cwd()).replace(os.sep, "/")
                source = subprocess.run(
                    ["git", "show", "{}:{}".format(args.from_git, relative_path)],
                    check=True, capture_output=True, text=True, encoding="cp1252",
                )
                source_text = source.stdout
            result = convert_map(path, args.apply, source_text)
            print("{mode} {path}: cables={cables}, apcs={apcs}, terminals={terminals}, helpers={helpers}".format(
                mode="WROTE" if args.apply and result["changed"] else "WOULD CONVERT" if result["changed"] else "UNCHANGED",
                **result))
            converted += bool(result["changed"])
        except Exception as error:
            print("ERROR {}: {}".format(path, error), file=sys.stderr)
            traceback.print_exc()
            failures += 1
    print("{} maps changed; {} errors; {} mode.".format(converted, failures, "apply" if args.apply else "dry-run"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
