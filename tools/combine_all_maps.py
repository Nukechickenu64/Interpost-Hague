#!/usr/bin/env python3
import os
import sys
import collections
import math

mapmerge_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mapmerge_backup", "mapmergepy")
if mapmerge_dir not in sys.path:
    sys.path.insert(0, mapmerge_dir)

import map_helpers

alphabet = [chr(c) for c in range(ord('a'), ord('z')+1)] + [chr(c) for c in range(ord('A'), ord('Z')+1)]

def num_to_key(n, length):
    chars = []
    for _ in range(length):
        chars.append(alphabet[n % len(alphabet)])
        n //= len(alphabet)
    return ''.join(reversed(chars))

def combine_maps(input_files, output_file):
    z_maps = []
    for z_file in input_files:
        map_helpers.reset_globals()
        d = map_helpers.parse_map(z_file)
        z_maps.append((d, map_helpers.maxx, map_helpers.maxy))

    maxx = max(m[1] for m in z_maps)
    maxy = max(m[2] for m in z_maps)

    unique_defs = collections.OrderedDict()
    for d, mx, my in z_maps:
        for k, tile_tuple in d['dictionary'].items():
            if tile_tuple not in unique_defs:
                unique_defs[tile_tuple] = None

    total_unique = len(unique_defs)
    key_length = max(2, math.ceil(math.log(total_unique, 52)))
    print(f"Combining {len(input_files)} maps into {output_file}: {total_unique} unique tile defs, key length {key_length}, dimensions {maxx}x{maxy}x{len(input_files)}")

    key_map = {}
    unified_dict = collections.OrderedDict()
    for idx, tile_tuple in enumerate(unique_defs.keys()):
        k = num_to_key(idx, key_length)
        key_map[tile_tuple] = k
        unified_dict[k] = list(tile_tuple)

    with open(output_file, 'w', encoding='latin1', newline='\n') as f:
        map_helpers.write_dictionary_tgm(f, unified_dict)
        for z_idx, (d, mx, my) in enumerate(z_maps, start=1):
            default_tile_tuple = list(d['dictionary'].values())[0]
            default_key = key_map[default_tile_tuple]
            f.write('\n')
            for x in range(1, maxx + 1):
                f.write(f"({x},1,{z_idx}) = {{\"\n")
                for y in range(1, maxy + 1):
                    orig_key = d['grid'].get((x, y))
                    if orig_key is not None:
                        tile_tuple = d['dictionary'][orig_key]
                        k = key_map[tile_tuple]
                    else:
                        k = default_key
                    f.write(f"{k}\n")
                f.write("\"}\n")

    print(f"Successfully wrote {output_file}")

MAP_GROUPS = [
    {
        "inputs": [f"maps/derelict/derelict-{i}.dmm" for i in range(1, 6)],
        "output": "maps/derelict/derelict.dmm",
    },
    {
        "inputs": [f"maps/dreyfus/dreyfus-{i:02d}.dmm" for i in range(1, 9)],
        "output": "maps/dreyfus/dreyfus.dmm",
    },
    {
        "inputs": [f"maps/example/example-{i}.dmm" for i in range(1, 4)],
        "output": "maps/example/example.dmm",
    },
    {
        "inputs": [f"maps/frontier/frontier-{i}.dmm" for i in range(1, 6)],
        "output": "maps/frontier/frontier.dmm",
    },
    {
        "inputs": [f"maps/neoderelict/neoderelict-{i}.dmm" for i in range(1, 6)],
        "output": "maps/neoderelict/neoderelict.dmm",
    },
    {
        "inputs": [f"maps/overmap_example/bearcat/bearcat-{i}.dmm" for i in range(1, 3)],
        "output": "maps/overmap_example/bearcat/bearcat.dmm",
    },
    {
        "inputs": [f"maps/trader/trader-{i}.dmm" for i in range(1, 5)],
        "output": "maps/trader/trader.dmm",
    },
    {
        "inputs": [f"maps/away/bearcat/bearcat-{i}.dmm" for i in range(1, 3)],
        "output": "maps/away/bearcat/bearcat.dmm",
    },
    {
        "inputs": [f"maps/away/blueriver/blueriver-{i}.dmm" for i in range(1, 3)],
        "output": "maps/away/blueriver/blueriver.dmm",
    },
    {
        "inputs": [f"maps/away/icarus/icarus-{i}.dmm" for i in range(1, 3)],
        "output": "maps/away/icarus/icarus.dmm",
    },
]

def main():
    for group in MAP_GROUPS:
        inputs = group["inputs"]
        output = group["output"]
        combine_maps(inputs, output)
        for inp in inputs:
            if os.path.exists(inp):
                os.remove(inp)
                print(f"Removed split file: {inp}")

if __name__ == "__main__":
    main()
