"""Check Alpha placements, nearby access and OS13 sprites without changing files."""
from collections import deque
from pathlib import Path
import re
from PIL import Image

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

fixtures = {
    (130, 117, 3): "/obj/machinery/chargemaster",
    (132, 116, 3): "/obj/machinery/chargemaster",
    (132, 115, 3): "/obj/structure/closet/crate/precursor_charges",
    (108, 100, 3): "/obj/machinery/computer/hydroponics",
    (108, 97, 3): "/obj/machinery/biomass_vat",
    (108, 95, 3): "/obj/machinery/biomass_vat",
    (108, 93, 3): "/obj/machinery/biomass_vat",
    (102, 88, 3): "/obj/machinery/biomass_vat",
    (100, 88, 3): "/obj/machinery/biomass_press",
    (120, 95, 2): "/obj/machinery/biomass_press/food_processor/pizza",
    (120, 93, 2): "/obj/machinery/biomass_press/food_processor/sandwich",
    (121, 93, 2): "/obj/machinery/biomass_press/food_processor/shawarma/broken",
    (120, 95, 3): "/obj/machinery/biomass_press/food_processor/meat_processor",
    (110, 107, 2): "/obj/machinery/vending/cigarette/os13",
}
assert sum("/obj/machinery/biomass_vat" in cell for cell in grid.values()) == 4

def neighbors(pos):
    x, y, z = pos
    return ((x+1, y, z), (x-1, y, z), (x, y+1, z), (x, y-1, z))

def access_tile(pos):
    cell = grid.get(pos, "")
    return ("/turf/simulated/floor" in cell
            and not any(obstacle in cell for obstacle in (
                "/obj/machinery/biomass", "/obj/machinery/chargemaster", "/obj/machinery/vending/",
                "/obj/machinery/computer/", "/obj/structure/table", "/obj/structure/closet",
                "/obj/structure/grille", "/obj/structure/window")))

for pos, path in fixtures.items():
    assert path in grid[pos], (pos, path)
    assert "/turf/simulated/floor" in grid[pos], pos
    assert any(access_tile(p) for p in neighbors(pos)), (pos, "no clear adjacent tile")

# The bottom kitchen's new units must not block the only ladder route.
reached = {(122, 93, 2)}
todo = deque(reached)
while todo:
    for pos in neighbors(todo.popleft()):
        if pos not in reached and access_tile(pos) and "/area/crew_quarters/kitchen" in grid[pos]:
            reached.add(pos)
            todo.append(pos)
for pos in ((120, 95, 2), (120, 93, 2), (121, 93, 2)):
    assert any(p in reached for p in neighbors(pos)), (pos, "unreachable from ladder")

required_states = {
    "icons/os13/objects/objects/chargemaster.dmi": ["cmaster", "cmaster_process", "generic-charge", "equipment-charge", "soda-charge", "security-charge", "cigarette-charge", "bar-charge", "chemistry-charge", "coffee-charge", "hydro-charge"],
    "icons/os13/objects/objects/vending.dmi": ["generic-charge", "snack-charge", "cigs", "cigs-off", "cigs-broken", "kitchen_base", "kitchen_inside", "kitchen0", "kitchen1", "kitchen1b", "kitchen1c", "kitchen_blink", "kitchen_door"],
    "icons/os13/objects/objects/cooking.dmi": ["pizza_pros_s1", "msandwich", "shaurma", "soylent"],
    "icons/os13/objects/objects/kitchen.dmi": ["processor", "processor_on"],
}
for path, required in required_states.items():
    states = re.findall(r'state = "([^"]+)"', Image.open(ROOT / path).info["Description"])
    assert set(required) <= set(states), (path, set(required) - set(states))

print(f"PASS: {len(fixtures)} fixtures on floor tiles with adjacent access; all three food units reachable from the kitchen ladder.")
print("PASS: four vats, two ChargeMasters, supply crate, cigarette vendor and all referenced OS13 sprite states.")
