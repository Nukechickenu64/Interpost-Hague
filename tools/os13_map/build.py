"""Reproducible furnishing pass over os13.dmm. Run from any directory.

Coordinates belong to the supplied shell; video deck numbers differ from z.
See docs/os13_map_recreation.md for evidence and inferred sections.
"""
from pathlib import Path
from collections import Counter
import json
import re
import string

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'maps/os13/recreated.dmm'
source = (ROOT / 'os13.dmm').read_text()
definitions = dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$', source, re.M | re.S))
original = {}
for block in re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}', source, re.S):
    x, y, z = map(int, block.group(1, 2, 3))
    rows = block[4].strip().splitlines()
    for j, row in enumerate(rows):
        for i, key in enumerate(row):
            original[x+i, y+len(rows)-1-j, z] = key

DECKS = {2:'engineering', 3:'medical', 4:'cargo', 5:'civilian',
         6:'security', 7:'research', 8:'mezzanine', 9:'command'}
FLOOR = '/turf/simulated/floor/tiled/'
WALL = '/turf/simulated/wall/os13'
grid = {}
fixtures = []
invalid = []
for p, key in original.items():
    x,y,z = p
    if key in ('a','N','M'):
        # Keep genuine inter-deck voids, not 200,000 empty openspace turfs.
        below = any(original.get((x,y,l)) in ('d','s','i','T','L') for l in range(2,z))
        grid[p] = [[], '/turf/simulated/open' if key != 'a' and below else '/turf/space', '/area/space']
        continue
    parts = [s.strip() for s in definitions[key].split(',')]
    turf = next(s for s in parts if s.startswith('/turf'))
    objects = [s for s in parts if s.startswith('/obj')]
    if turf == '/turf/simulated/wall': turf = WALL
    if turf == '/turf/simulated/floor/tiled': turf = FLOOR+'os3'
    if turf == '/turf/simulated/floor/plating': turf = FLOOR+'os13'
    grid[p] = [objects, turf, '/area/os13/'+DECKS.get(z,'engineering')]

def rect(x1,y1,x2,y2,z):
    return [(x,y,z) for x in range(x1,x2+1) for y in range(y1,y2+1)]

def floor(p):
    return '/floor' in grid[p][1]

def paint(box,z,style,area=None):
    for p in rect(*box,z):
        if floor(p):
            grid[p][1] = FLOOR+style
            if area: grid[p][2] = '/area/os13/'+area

def put(x,y,z,path,**props):
    p=x,y,z
    if not floor(p):
        invalid.append((p, path))
        return
    obj=path
    if props:
        obj += '{'+ '; '.join(f'{k} = {v}' for k,v in props.items())+'}'
    grid[p][0].append(obj)
    fixtures.append({'position':list(p),'path':path})

def door(x,y,z,access=None):
    if not floor((x,y,z)): grid[x,y,z]=[[],FLOOR+'os3','/area/os13/'+DECKS[z]]
    props={'req_access':f'list({access})'} if access else {}
    put(x,y,z,'/obj/machinery/door/airlock',**props)

def sign(x,y,z,text):
    put(x,y,z,'/obj/structure/sign/os13_label',name=json.dumps(text))

def row(xs,y,z,path,**props):
    for x in xs: put(x,y,z,path,**props)

def table(x1,y1,x2,y2,z):
    for x,y,_ in rect(x1,y1,x2,y2,z): put(x,y,z,'/obj/structure/table/standard')

def chair(x,y,z,direction=1):
    put(x,y,z,'/obj/structure/bed/chair',dir=direction)

# Department floor palettes and the purple circulation stripes visible throughout.
for z in DECKS:
    for p in list(grid):
        if p[2] != z or not floor(p) or original.get(p) == 's': continue
        x,y,_ = p
        if z in (2,4): grid[p][1]=FLOOR+'no0'
        elif z == 3: grid[p][1]=FLOOR+'verybright'
        elif z in (6,7): grid[p][1]=FLOOR+'darkpurpleos'
    paint((110,111,111,130),z,'purpleos')
paint((100,112,151,113),5,'chesssteel')
paint((103,119,111,122),5,'chesssteel','kitchen')
paint((114,116,118,123),5,'chesssteel','kitchen')
paint((118,102,126,110),5,'barnew','chapel')
paint((118,104,128,115),4,'purpleos','hydroponics')
paint((119,105,127,114),4,'os3','hydroponics')
paint((94,132,103,138),6,'barnew','armory')
paint((112,137,121,143),9,'os3')
paint((112,137,112,143),9,'purpleos')
paint((121,137,121,143),9,'purpleos')

# Complete the shell's main lift shaft. The original empty shaft appears on
# decks 2 and 4; other landings need small structural infills.
for z in DECKS:
    for x,y,_ in rect(114,124,118,128,z):
        grid[x,y,z]=[[],WALL if x in (114,118) or y in (124,128) else FLOOR+'no0','/area/os13/'+DECKS[z]]
    for x,y,_ in rect(115,122,117,124,z):
        grid[x,y,z]=[[],FLOOR+'os3','/area/os13/'+DECKS[z]]
    # The adjacent service ladder provides a power-independent route.
    for x in (119,120):
        grid[x,123,z]=[[],FLOOR+'os3','/area/os13/'+DECKS[z]]
    for x in range(117,121):
        grid[x,122,z]=[[],FLOOR+'os3','/area/os13/'+DECKS[z]]
    ladder='/obj/structure/ladder/up' if z==2 else '/obj/structure/ladder' if z==9 else '/obj/structure/ladder/updown'
    put(120,123,z,ladder)
    number={2:1,3:2,4:3,5:4,6:5,7:6,8:6,9:7}[z]
    put(115,122,z,'/obj/structure/sign/os13_deck',icon_state=f'"odeck{number}"')

# Landings connect to each original deck without erasing the surrounding rooms.
for z, target_y in ((4,111),(8,115)):
    for y in range(target_y,123):
        for x in (115,116,117): grid[x,y,z]=[[],FLOOR+'os3','/area/os13/'+DECKS[z]]
if True:
    for x in range(117,133): grid[x,115,8]=[[],FLOOR+'os3','/area/os13/mezzanine']
# Holder occupies a wall at build time and replaces the complete shaft at startup.
grid[114,124,2][0].append('/obj/turbolift_map_holder/os13')

# Deck 1: engineering workshop, EVA preparation and the comb-shaped solar array.
table(103,125,105,125,2)
row([103,105,107],126,2,'/obj/structure/closet/secure_closet/engineering_personal')
put(108,124,2,'/obj/machinery/vending/engineering/os13')
put(103,124,2,'/obj/machinery/autolathe')
put(109,126,2,'/obj/machinery/computer/engineering_power')
put(105,121,2,'/obj/structure/solar_panel_cart/loaded')
put(107,121,2,'/obj/structure/harvester')
put(104,121,2,'/obj/machinery/computer/station_gas_control')
put(97,110,2,'/obj/machinery/station_gas_tank')
put(99,110,2,'/obj/machinery/filter_hub')
row([97,99],113,2,'/obj/structure/closet/secure_closet/engineering_personal')
sign(104,122,2,'ENGINEERING')
for x in range(103,110):
    grid[x,128,2]=[[],FLOOR+'os3','/area/os13/engineering']
door(106,128,2)
for p in rect(103,129,109,134,2):
    x,y,z=p; grid[p]=[[],WALL if x in (103,109) or y==134 else FLOOR+'no0','/area/os13/engineering']
door(106,134,2)
for y in range(135,158):
    for x in (105,106,107): grid[x,y,2]=[['/obj/structure/catwalk'],'/turf/simulated/floor/airless','/area/os13/solar']
for y in (139,143,147,151,155):
    for x in range(91,122):
        if x in (105,106,107): continue
        grid[x,y,2]=[[], '/turf/simulated/floor/airless/solar_array','/area/os13/solar']
        put(x,y,2,'/obj/machinery/power/solar_base/installed')
        grid[x,y-1,2]=[['/obj/structure/catwalk'],'/turf/simulated/floor/airless','/area/os13/solar']
for x,y in ((104,130),(108,130),(104,132),(108,132)):
    put(x,y,2,'/obj/machinery/power/smes',charge=5000000,input_attempt=1,output_attempt=1,output_level=100000)
put(106,133,2,'/obj/machinery/computer/engineering_power')

# Deck 2: ward, surgery, chemistry and cloning. Keep central aisles clear.
row([102,104,106],125,3,'/obj/structure/bed')
row([102,104,106],121,3,'/obj/structure/bed')
put(107,126,3,'/obj/machinery/vending/medical')
put(102,126,3,'/obj/machinery/computer/crew')
table(114,116,116,116,3)
put(118,117,3,'/obj/item/modular_computer/console/preset/medical')
put(114,114,3,'/obj/structure/bed')
put(118,114,3,'/obj/structure/bed')
sign(115,117,3,'MEDICAL BAY')
put(122,123,3,'/obj/machinery/chemical_dispenser/full')
put(125,123,3,'/obj/machinery/chem_master')
table(122,120,125,120,3)
put(130,122,3,'/obj/machinery/clonepod')
put(132,122,3,'/obj/machinery/computer/cloning')
put(134,122,3,'/obj/machinery/dna_scannernew')
put(130,120,3,'/obj/machinery/vending/medical')
sign(132,123,3,'CLONING')
put(101,114,3,'/obj/machinery/optable')
put(104,114,3,'/obj/machinery/computer/operating')
put(100,110,3,'/obj/structure/closet/secure_closet/medical_wall')

# Deck 3: ChargeMaster service counter, storage bays and six vats in two rows.
table(100,116,102,116,4)
put(100,116,4,'/obj/machinery/chargemaster')
put(102,116,4,'/obj/machinery/chargemaster')
row([100,101,102],117,4,'/obj/item/precursor_charge')
put(108,117,4,'/obj/item/modular_computer/console/preset/supply')
put(106,117,4,'/obj/machinery/vending/engineering/os13')
sign(102,118,4,'CARGO BAY')
for x in (94,97,101,105,109):
    for y in (99,104):
        if floor((x,y,4)): put(x,y,4,'/obj/structure/closet/crate')
for x in (120,123,126):
    for y in (106,111): put(x,y,4,'/obj/machinery/biomass_vat')
put(119,114,4,'/obj/machinery/computer/hydroponics/os13')
put(123,114,4,'/obj/machinery/biomass_press')
put(127,114,4,'/obj/machinery/vending/hydro_cultures')
put(118,105,4,'/obj/item/hydroponics_supply/skimmer')
sign(124,115,4,'HYDROPONICS')

# Deck 4: cafe/bar counter, kitchen processors, dining, chapel, bunks.
table(104,121,108,121,5)
for x in (104,106,108): chair(x,120,5)
put(103,122,5,'/obj/machinery/vending/boozeomat')
put(110,122,5,'/obj/machinery/vending/cigarette')
put(109,121,5,'/obj/machinery/chemical_dispenser/bar_soft/full')
sign(106,122,5,'BAR')
put(115,121,5,'/obj/machinery/biomass_press/food_processor/pizza')
put(117,121,5,'/obj/machinery/biomass_press/food_processor/sandwich')
put(118,121,5,'/obj/machinery/biomass_press/food_processor/shawarma/broken')
put(115,119,5,'/obj/machinery/biomass_press/food_processor/meat_processor')
put(118,119,5,'/obj/structure/hygiene/sink')
for x in (104,109,123,127):
    if floor((x,113,5)):
        table(x,113,x+1,113,5)
        chair(x,112,5)
        if floor((x,114,5)): chair(x,114,5,2)
row([131,132],119,5,'/obj/machinery/vending/snack')
put(131,121,5,'/obj/machinery/vending/coffee')
for y in (103,106,109):
    row([120,123],y,5,'/obj/structure/bed/chair')
table(120,110,122,110,5)
sign(121,110,5,'CHAPEL')
for x in (143,146,149):
    for y in (114,116): put(x,y,5,'/obj/structure/bed')

# Deck 5: security reception, marshal office, armory and detention cells.
table(112,120,115,120,6)
put(113,120,6,'/obj/item/modular_computer/console/preset/security')
put(116,121,6,'/obj/item/modular_computer/console/preset/security')
put(110,121,6,'/obj/machinery/vending/security')
sign(114,121,6,'SECURITY')
row([95,97,99,101],137,6,'/obj/structure/closet/secure_closet/security')
row([95,97,99,101],134,6,'/obj/structure/table/rack')
sign(98,138,6,'ARMORY')
door(102,133,6,'access_armory')
for x in (112,116,120):
    put(x,145,6,'/obj/structure/bed')
    put(x+1,144,6,'/obj/structure/hygiene/toilet')
for x,y in ((108,141),(124,141),(108,133),(124,133)):
    if floor((x,y,6)): put(x,y,6,'/obj/structure/bed')
table(117,137,118,137,6)
chair(118,136,6)
put(118,138,6,'/obj/item/modular_computer/console/preset/security')

# Deck 6: two Replicators, research benches, containment and prototype annex.
put(117,120,7,'/obj/machinery/r_n_d/protolathe')
put(121,120,7,'/obj/machinery/r_n_d/protolathe')
put(124,126,7,'/obj/machinery/computer/rdconsole')
put(122,126,7,'/obj/machinery/r_n_d/destructive_analyzer')
table(119,124,121,124,7)
sign(122,127,7,'RESEARCH')
row([111,112],111,7,'/obj/structure/table/standard')
put(112,104,7,'/obj/machinery/computer/rdconsole')
put(124,112,7,'/obj/machinery/chemical_dispenser/full')
row([133,136],126,7,'/obj/structure/closet')
put(133,120,7,'/obj/machinery/computer/robotics')
put(97,139,7,'/obj/machinery/r_n_d/protolathe')
sign(97,140,7,'PROTOTYPE')

# Deck 7: briefing table below the control room and bridge reception below it.
table(116,138,117,141,9)
for y in (138,139,140,141):
    chair(115,y,9,4); chair(118,y,9,8)
row([113,120],142,9,'/obj/structure/flora/pottedplant')
table(115,143,118,143,9)
put(112,142,9,'/obj/item/modular_computer/console/preset/command')
put(120,140,9,'/obj/machinery/computer/crew')
sign(116,142,9,'BRIEFING')
row([112,115,118,120],148,9,'/obj/item/modular_computer/console/preset/security')
put(116,146,9,'/obj/item/modular_computer/console/preset/command')
put(120,146,9,'/obj/machinery/computer/engineering_power')
chair(116,145,9)
table(115,134,118,134,9)
put(116,134,9,'/obj/item/modular_computer/console/preset/command')
put(120,134,9,'/obj/machinery/vending/coffee')
sign(116,135,9,'BRIDGE')
put(125,141,9,'/obj/structure/bed')
put(125,139,9,'/obj/structure/closet/secure_closet/captains')

# Restore missing internal doorways in the unfinished shell.
for x,y,z in [(118,112,3),(125,109,4),(119,111,5),(130,127,5),
              (134,113,5),(139,114,5),(128,117,5),(134,112,5),(137,118,5),
              (103,133,6),(131,129,7),(135,129,7)]:
    door(x,y,z)
# Original prototype annex and detached docking pod get exterior access gantries.
for x in range(102,115):
    grid[x,134,7]=[['/obj/structure/catwalk'],'/turf/simulated/floor/airless','/area/os13/solar']
door(102,134,7);door(114,134,7)
for x in range(152,163):
    grid[x,116,5]=[['/obj/structure/catwalk'],'/turf/simulated/floor/airless','/area/os13/solar']
for y in range(117,129):
    grid[162,y,5]=[['/obj/structure/catwalk'],'/turf/simulated/floor/airless','/area/os13/solar']
door(151,116,5);door(162,128,5)
# Glass briefing table, as seen in all three recordings.
for p in rect(116,138,117,141,9):
    grid[p][0]=[o.replace('/table/standard','/table/glass') for o in grid[p][0]]
# Remove incomplete ladder/stair placeholders; the completed lift/service shaft
# supplies all inter-deck routes rather than retaining nonfunctional exits.
for p,c in grid.items():
    if not (p[0]==120 and p[1]==123):
        c[0]=[o for o in c[0] if not o.startswith(('/obj/structure/ladder','/obj/structure/stairs'))]

# Seal exposed edges left unfinished in the shell, including wall-gap hatches.
# Existing floors/walls remain in place; only adjacent empty tiles are filled.
for p,c in list(grid.items()):
    if not floor(p) or c[2]=='/area/os13/solar': continue
    x,y,z=p
    for q in ((x-1,y,z),(x+1,y,z),(x,y-1,z),(x,y+1,z)):
        if q in grid and grid[q][1] in ('/turf/space','/turf/simulated/open'):
            grid[q]=[[],WALL,c[2]]

# Install doors into unambiguous single-tile gaps in straight internal walls.
for p,c in list(grid.items()):
    if not floor(p) or c[0] or c[2]=='/area/os13/solar' or original.get(p)=='s': continue
    x,y,z=p
    if 114<=x<=120 and 122<=y<=128: continue
    north=grid.get((x,y+1,z)); south=grid.get((x,y-1,z));east=grid.get((x+1,y,z));west=grid.get((x-1,y,z))
    if not all((north,south,east,west)):continue
    if (north[1]==south[1]==WALL and '/floor' in east[1] and '/floor' in west[1]) or (east[1]==west[1]==WALL and '/floor' in north[1] and '/floor' in south[1]):
        door(x,y,z)

# Every named area has power, a modcon, a vent and practical illumination.
areas=sorted({c[2] for c in grid.values() if c[2].startswith('/area/os13/') and c[2]!='/area/os13/solar'})
for area in areas:
    candidates=[p for p,c in grid.items() if c[2]==area and floor(p) and not c[0] and not(114<=p[0]<=120 and 122<=p[1]<=128)]
    assert len(candidates)>4,area
    # Prefer wall-adjacent utility tiles over walking routes.
    candidates.sort(key=lambda p:(not any(grid.get((p[0]+dx,p[1]+dy,p[2]),[None,''])[1]==WALL for dx,dy in ((0,1),(0,-1),(1,0),(-1,0))),p))
    for p,path in zip(candidates,('/obj/machinery/power/area_smes','/obj/machinery/alarm','/obj/machinery/atmospherics/unary/vent_pump')):
        if path == '/obj/machinery/power/area_smes':
            put(*p,path,area_id=json.dumps(area))
            put(*p,'/obj/effect/area_power_marker',area_id=json.dumps(area))
        else: put(*p,path)
    for p in candidates[3:]:
        x,y,z=p
        if x%5==0 and y%5==0:put(x,y,z,'/obj/machinery/light/small')

put(118,122,5,'/obj/effect/landmark')
grid[118,122,5][0][-1]='/obj/effect/landmark{ name = "JoinLateCryo" }'
put(119,122,9,'/obj/effect/landmark',name='"JoinLateCryoCaptain"')
grid[1,1,9][0].append('/obj/effect/landmark/map_data{height = 8}')

if invalid:
    for item in invalid: print('INVALID', item)
    raise SystemExit(1)

# Stable three-character TGM keys. Never alter the input template.
alphabet=string.ascii_lowercase+string.ascii_uppercase
def key(n): return alphabet[n//2704]+alphabet[n//52%52]+alphabet[n%52]
dictionary={};cells={}
for p,c in grid.items():
    content=',\n'.join(c[0]+c[1:])
    if content not in dictionary: dictionary[content]=key(len(dictionary))
    cells[p]=dictionary[content]
OUT.parent.mkdir(parents=True,exist_ok=True)
with OUT.open('w',newline='\n') as f:
    f.write('//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE\n')
    for content,k in dictionary.items():f.write(f'"{k}" = (\n{content})\n')
    for z in range(1,11):
        for x in range(1,201):
            f.write(f'\n({x},1,{z}) = {{"\n'+ '\n'.join(cells[x,y,z] for y in range(200,0,-1))+'\n"}\n')
(OUT.parent/'fixtures.json').write_text(json.dumps(fixtures,indent=2)+'\n')
print(f'Wrote {OUT}: {len(dictionary)} definitions, {len(fixtures)} fixtures.')


