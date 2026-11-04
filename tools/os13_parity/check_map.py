"""Check Classic's deployable Scout geometry and two-deck station metadata."""
from pathlib import Path
import argparse
import re
from dmm import read_map

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--baseline", type=Path)
args = parser.parse_args()
_, _, grid = read_map(ROOT / "maps/os13classic/os13classic.dmm")
craft = {p for p, cell in grid.items() if cell.endswith(",/area/shuttle/mining/station")}
assert craft == {(x, y, 1) for x in range(152, 157) for y in range(140, 147)}
assert sum("/obj/structure/sofa/os13_scout" in grid[p] for p in craft) == 4
assert "/obj/structure/bed/chair" in grid[154, 144, 1]
assert "/obj/machinery/computer/os13_scout_controls" in grid[154, 145, 1]
assert "/obj/machinery/computer/os13_scout," in grid[155, 141, 1]
for p in ((152, 142, 1), (156, 142, 1)):
    assert "/obj/machinery/door/airlock/" in grid[p]
assert "/obj/structure/catwalk" in grid[151, 142, 1]
expected = {
    "/obj/effect/shuttle_landmark/mining/station/os13": (154, 142, 1),
    "/obj/effect/shuttle_landmark/mining/transit": (184, 184, 1),
    "/obj/effect/shuttle_landmark/mining/open_space": (30, 187, 1),
}
for landmark, position in expected.items():
    assert [p for p, cell in grid.items() if landmark + "," in cell] == [position]
    if landmark.endswith("/os13"):
        continue
    dx, dy = position[0] - 154, position[1] - 142
    for x, y, z in craft:
        destination = grid[x + dx, y + dy, z]
        assert destination.endswith("/turf/space,/area/space"), destination
metadata = (ROOT / "maps/alpha/alpha_define.dm").read_text().split("/datum/map/os13classic\n", 1)[1].split("/datum/map/os13classic/setup_map()", 1)[0]
levels = sorted({p[2] for p in grid})
assert levels == [1, 2]
for field in ("station_levels", "contact_levels", "player_levels", "map_levels"):
    declared = re.search(rf"\b{field} = list\((.*?)\)", metadata)[1]
    assert list(map(int, declared.split(","))) == levels, (field, declared)
print("PASS: two mapped station decks, 35-tile Scout, five seats, distinct consoles, exterior berth and clear transit/destination footprints.")
if args.baseline:
    before = read_map(args.baseline)[2]
    assert before.keys() == grid.keys()
    changed = {p for p in before if before[p] != grid[p]}
    assert changed == craft | {(184, 184, 1)}
    print(f"PASS: exactly {len(changed)} deployment cells changed; {len(grid) - len(changed)} other cells preserved.")
