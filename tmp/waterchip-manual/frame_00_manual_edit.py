"""Directly hand-place objects whose cells are visible in video frame 00:00."""
from pathlib import Path
import re
import string
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/os13_map'))
from waterchip_manual import read_map

path = ROOT / 'maps/os13/waterchip-manual.dmm'
text = path.read_text()
grid = read_map(text)
source_grid = read_map((ROOT / 'os13.dmm').read_text())
definitions = dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$', text, re.M | re.S))
width = len(next(iter(definitions)))
assert width == 1, width
used = set(definitions)
free = iter(ch for ch in string.ascii_lowercase + string.ascii_uppercase if ch not in used)

# Coordinates are measured from the center window at (100,102,4), visible
# at image pixel (643,396), with a 72-pixel tile pitch in the 00:00 frame.
placements = [
    ((100, 104, 4), '/obj/machinery/floor_light/os13'),
    ((100, 106, 4), '/obj/machinery/computer/os13_scanner'),
    ((98, 106, 4), '/obj/structure/closet{icon = \'icons/os13/objects/objects/closet.dmi\'; icon_state = "nt"; icon_closed = "nt"; icon_opened = "ntopen"; opened = 0; density = 1; anchored = 1}'),
    ((97, 105, 4), '/obj/structure{icon = \'icons/os13/objects/objects/orbital_decor.dmi\'; icon_state = "wall1"; name = "wall lamp"; anchored = 1; density = 0}'),
]

blocks = list(re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}', text, re.S))
new_definitions = []
edited = set()
for point, atom in placements:
    assert point in grid, point
    assert any(item.startswith(('/turf/simulated/floor', '/turf/simulated/wall'))
               for item in grid[point]), point
    assert atom not in grid[point], (point, atom)
    key = next(free)
    edited_cell = [atom, *grid[point]]
    definition = '"' + key + '" = (\n' + ',\n'.join(edited_cell) + ')'
    new_definitions.append(definition)
    x, y, z = point
    block = next(m for m in blocks if int(m.group(1)) == x and int(m.group(3)) == z
                 and int(m.group(2)) <= y < int(m.group(2)) + len(m.group(4).strip().splitlines()))
    rows = block.group(4).strip().splitlines()
    row_index = len(rows) - 1 - (y - int(block.group(2)))
    assert len(rows[row_index]) == width
    assert rows[row_index] in used
    rows[row_index] = key
    replacement = block.group(0).replace(block.group(4), '\n' + '\n'.join(rows) + '\n')
    text = text.replace(block.group(0), replacement, 1)
    grid[point] = edited_cell
    edited.add(point)
    # Re-scan after each direct coordinate edit so later blocks use fresh spans.
    blocks = list(re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}', text, re.S))

first_block = re.search(r'(?m)^\(\d+,\d+,\d+\) = \{', text)
assert first_block
text = text[:first_block.start()] + '\n'.join(new_definitions) + '\n' + text[first_block.start():]
path.write_text(text)
check = read_map(path.read_text())
for point, atom in placements:
    assert atom in check[point], (point, atom)
assert {p for p in check if check[p] != source_grid[p]} == edited
print('Direct frame 00:00 placements:', ', '.join(map(str, sorted(edited))))
