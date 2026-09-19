#!/usr/bin/env python3
"""
Convert BYOND DMM map files to TGM (TG Map) format for easy editing in StrongDMM.
Usage:
    python tools/dmm2tgm.py               # converts all .dmm files in maps/
    python tools/dmm2tgm.py path/to/map   # converts specific map file or directory
"""

import os
import sys
import pathlib

# Import helper functions from mapmergepy
mapmerge_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mapmerge_backup", "mapmergepy")
if mapmerge_dir not in sys.path:
    sys.path.insert(0, mapmerge_dir)

import map_helpers

def convert_file(map_path, force=False):
    with open(map_path, "r", encoding="latin1") as f:
        first_line = f.readline()
    if not force and "MAP CONVERTED BY dmm2tgm.py" in first_line:
        return False, "Already converted to TGM format"

    map_helpers.reset_globals()
    data = map_helpers.parse_map(map_path)
    if not data or not data.get("dictionary"):
        return False, "Failed to parse map dictionary"

    default_key = list(data["dictionary"].keys())[0] if len(data["dictionary"]) > 0 else "a"
    with open(map_path, "w", encoding="latin1", newline="\n") as f:
        map_helpers.write_dictionary_tgm(f, data["dictionary"])
        map_helpers.write_grid_coord_small(f, data["grid"], default_key)

    return True, "Successfully converted to TGM"

def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "maps"
    force = "--force" in sys.argv

    if os.path.isfile(target):
        files = [target]
    elif os.path.isdir(target):
        files = [
            os.path.join(root, f)
            for root, _, filenames in os.walk(target)
            for f in filenames
            if f.endswith(".dmm")
        ]
    else:
        print(f"Error: Target path '{target}' not found.")
        sys.exit(1)

    print(f"Found {len(files)} map file(s) to process.")
    converted = 0
    skipped = 0
    errors = 0

    for path in files:
        try:
            success, message = convert_file(path, force)
            if success:
                print(f"[CONVERTED] {path}")
                converted += 1
            else:
                skipped += 1
        except Exception as e:
            print(f"[ERROR] {path}: {e}")
            errors += 1

    print("-" * 40)
    print(f"Summary: {converted} converted, {skipped} skipped, {errors} errors.")

if __name__ == "__main__":
    main()
