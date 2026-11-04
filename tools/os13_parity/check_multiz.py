"""Check Classic's connected decks/roof and complete exterior ladder routes."""
import argparse
from pathlib import Path
import re
from dmm import read_map

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--baseline", type=Path)
args = parser.parse_args()
_, _, grid = read_map(ROOT / "maps/os13classic/os13classic.dmm")
markers = [(p, cell) for p, cell in grid.items() if "/landmark/map_data" in cell]
config = (ROOT / "maps/alpha/alpha_define.dm").read_text()
assert "new /obj/effect/landmark/map_data/os13classic(locate(1, 1, 3))" in config
assert re.search(r"/obj/effect/landmark/map_data/os13classic\n\s+height = 3\b", config)
assert not markers, "Classic establishes its stack in setup_map, before atom initialization."
ladder_positions = {(104, y) for y in (117, 121, 123, 127)} | {(143, 150)}
for x, y in ladder_positions:
    assert "/obj/structure/ladder/up," in grid[x, y, 1], (x, y, 1)
    assert re.search(r"/obj/structure/ladder(?:/updown)?,", grid[x, y, 2]), (x, y, 2)
    assert "/obj/structure/catwalk," in grid[x, y, 2], (x, y, 2)
    assert "/turf/simulated/open," in grid[x, y, 2], (x, y, 2)
assert sum("/obj/structure/ladder" in c for c in grid.values()) == 10
print("PASS: startup stack configuration and five mapped exterior ladder pairs; native connectivity requires check_multiz regression.")
if args.baseline:
    before = read_map(args.baseline)[2]
    assert grid.keys() == before.keys()
    changed = {p for p in grid if grid[p] != before[p]}
    expected = {(x, y, 2) for x, y in ladder_positions}
    assert changed == expected, changed ^ expected
    print(f"PASS: exactly {len(changed)} connection/ladder cells changed; all other map cells preserved.")
