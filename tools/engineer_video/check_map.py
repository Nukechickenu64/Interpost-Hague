"""Validate the mapped solar service route without changing the DMM."""
from collections import Counter, deque
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
source = (ROOT / "maps/alpha/alpha.dmm").read_text()
definitions = dict(re.findall(r'^"([A-Za-z]+)" = \((.*)\)$', source, re.M))
grid = {}
for block in re.finditer(r'\((\d+),(\d+),(\d+)\)\s*=\s*\{"(.*?)"\}', source, re.S):
    x0, y0, z = map(int, block.group(1, 2, 3))
    rows = block.group(4).strip("\n").splitlines()
    for j, row in enumerate(rows):
        assert len(row) % 3 == 0
        for i in range(0, len(row), 3):
            grid[x0 + i // 3, y0 + len(rows) - 1 - j, z] = definitions[row[i:i + 3]]

mounts = {p: cell for p, cell in grid.items() if "/obj/machinery/power/solar_base" in cell}
assert len(mounts) == 56, len(mounts)
assert all(p[2] == 3 and "/turf/simulated/floor/airless/solar_array" in cell for p, cell in mounts.items())
counts = Counter(re.search(r'/obj/machinery/power/solar_base([^,]*)', cell)[1] for cell in mounts.values())
assert counts == {"/installed": 48, "/installed/damaged": 4, "/installed/broken": 2, "": 2}, counts

# The west rail on the old landing must be open to the new EVA walkway.
assert 'icon-railing0 (WEST)' not in grid[55, 82, 3]
walkable = {p for p, cell in grid.items()
            if p[2] == 3 and 35 <= p[0] <= 56 and 75 <= p[1] <= 85
            and "/obj/structure/catwalk" in cell and p not in mounts}
reached = {(56, 82, 3)}
todo = deque(reached)
while todo:
    x, y, z = todo.popleft()
    for p in ((x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y - 1, z)):
        if p in walkable and p not in reached:
            reached.add(p)
            todo.append(p)
for x, y, z in mounts:
    assert any(p in reached for p in ((x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y - 1, z))), (x, y, z)

for pos, path in {
    (62, 80, 3): "/obj/machinery/computer/engineering_power",
    (60, 78, 3): "/obj/structure/solar_panel_cart/loaded",
    (61, 78, 3): "/obj/structure/harvester",
    (83, 88, 3): "/obj/machinery/vending/engineering/os13",
    (69, 106, 2): "/obj/machinery/computer/station_gas_control",
}.items():
    assert path in grid[pos], (pos, path)

print(f"PASS: {len(mounts)} mounts are serviceable from the EVA landing; {len(reached)} walkway tiles connected.")
print("PASS: power and atmosphere consoles, loaded replacement cart, harvester and OS13 equipment vendor are mapped.")
