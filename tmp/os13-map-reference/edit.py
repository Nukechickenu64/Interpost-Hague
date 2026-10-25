p='maps/os13/recreation_assets.dm';s=open(p).read().replace("icons/os13/turf/turf/walls.dmi","icons/os13/turf/turf/wwalls.dmi").replace('"wall0"','"rwall0"').replace('"wall[connections]"','"rwall[connections]"');s=s.replace('overlays += image(icon, "damage[stage]")',"overlays += image('icons/os13/turf/turf/walls.dmi', \"damage[stage]\")");open(p,'w').write(s)
p='tools/os13_map/inspect_map.py';s=open(p).read().replace("icons/os13/turf/turf/walls.dmi","icons/os13/turf/turf/wwalls.dmi").replace("f'wall{mask}'","f'rwall{mask}'");open(p,'w').write(s)
p='tools/os13_map/build.py';s=open(p).read().replace("if not floor(p) or c[0] or c[2]=='/area/os13/solar': continue","if not floor(p) or c[0] or c[2]=='/area/os13/solar' or original.get(p)=='s': continue")
s=s.replace("        put(*p,path)\n", "        if path == '/obj/machinery/power/area_smes':\n            put(*p,path,area_id=json.dumps(area))\n            put(*p,'/obj/effect/area_power_marker',area_id=json.dumps(area))\n        else: put(*p,path)\n")
s=s.replace("# Seal exposed edges", """# Restore missing internal doorways in the unfinished shell.
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

# Seal exposed edges""")
open(p,'w').write(s)
