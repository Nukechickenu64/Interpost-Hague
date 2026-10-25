"""Direct cell edits selected by manual inspection of frames 0 through 1199.

This edits the existing DMM in place. It contains no room filling, scene
matching, furnishing rules, or regeneration from the original map.
"""
from pathlib import Path
import json
import re
import string

ROOT = Path(__file__).resolve().parents[2]
path = ROOT / 'maps/os13/waterchip-manual.dmm'
text = path.read_text()

def atoms(s):
    result=[]; start=0; depth=0; quote=None
    for i,ch in enumerate(s):
        if quote:
            if ch==quote and (i==0 or s[i-1]!='\\'): quote=None
        elif ch in ('"', "'"): quote=ch
        elif ch in '({': depth+=1
        elif ch in ')}': depth-=1
        elif ch==',' and depth==0:
            result.append(s[start:i].strip()); start=i+1
    result.append(s[start:].strip())
    return result

definitions={k:atoms(v) for k,v in re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$',text,re.M|re.S)}
width=len(next(iter(definitions)))
assert width==2
blocks=list(re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}',text,re.S))
rows=[b[4].strip().splitlines() for b in blocks]
locations={}
for bi,b in enumerate(blocks):
    x,y,z=map(int,b.group(1,2,3))
    for ri,row in enumerate(rows[bi]):
        assert len(row)==width
        locations[x,y+len(rows[bi])-1-ri,z]=(bi,ri)

alphabet=string.ascii_lowercase+string.ascii_uppercase
free=iter(a+b for a in reversed(alphabet) for b in reversed(alphabet) if a+b not in definitions)
signatures={tuple(v):k for k,v in definitions.items()}
new_definitions={}
changes=[]

def edit(point,new_atoms,description,frame):
    bi,ri=locations[point]
    old_key=rows[bi][ri]
    old=definitions[old_key]
    assert old!=new_atoms,(point,'already edited')
    signature=tuple(new_atoms)
    if signature not in signatures:
        key=next(free); signatures[signature]=key
        definitions[key]=new_atoms; new_definitions[key]=new_atoms
    rows[bi][ri]=signatures[signature]
    changes.append(dict(position=list(point),frame=frame,time_seconds=frame/60,
                        description=description,before=old,after=new_atoms))

def cell(point):
    bi,ri=locations[point]
    return list(definitions[rows[bi][ri]])

def turf(point,new_turf,description,frame):
    old=cell(point); assert sum(a.startswith('/turf/') for a in old)==1
    edit(point,[new_turf if a.startswith('/turf/') else a for a in old],description,frame)

def add(point,atom,description,frame):
    old=cell(point); assert atom not in old,(point,atom)
    edit(point,[atom,*old],description,frame)

def replace_grille(point):
    old=cell(point)
    matches=[a for a in old if 'square floor grille (approximate art)' in a]
    assert len(matches)==1,(point,matches)
    edit(point,['/obj/machinery/atmospherics/unary/vent_pump/os13_reference' if a==matches[0] else a for a in old],
         'Square vent: original hoff7 sprite, replacing the scaled grille',720)

# Each coordinate below was selected individually from the reviewed frames.
turf((106,108,4),'/turf/simulated/floor/fixed/os13/plain_cover','North solid cover: h3',720)
turf((104,105,4),'/turf/simulated/floor/fixed/os13/plain_cover','West solid cover: h3',720)
turf((108,105,4),'/turf/simulated/floor/fixed/os13/plain_cover','East solid cover: h3',720)
turf((105,106,4),'/turf/simulated/floor/fixed/os13/paired_cover','West paired cover: ccc',720)
turf((107,106,4),'/turf/simulated/floor/fixed/os13/paired_cover','East paired cover: ccc',720)
turf((106,103,4),'/turf/simulated/floor/fixed/os13/panel_floor','South pale four-panel floor: hhh',720)
turf((100,99,4),'/turf/simulated/floor/fixed/os13/paired_cover','Center cryopod bay paired cover',0)
turf((106,99,4),'/turf/simulated/floor/fixed/os13/perforated_cover','East cryopod bay perforated cover',600)
replace_grille((106,107,4))
replace_grille((106,104,4))
add((94,98,4),'/obj/machinery/atmospherics/unary/vent_pump/os13_reference','West lower square vent',600)
add((106,98,4),'/obj/machinery/atmospherics/unary/vent_pump/os13_reference','East lower square vent',600)
add((98,102,4),'/obj/structure/sign/os13_station_emblem','West emblem beside the three-window wall',0)
add((102,102,4),'/obj/structure/sign/os13_station_emblem','East emblem beside the three-window wall',0)
add((109,106,4),'/obj/structure/sign/os13_station_emblem','Locker-room east wall emblem',720)
add((98,101,4),'/obj/machinery/light/small/os13_green_strip{dir = 2}','Center cryopod bay upper green strip',0)
add((98,98,4),'/obj/machinery/light/small/os13_green_strip{dir = 1}','Center cryopod bay lower green strip',0)

changed_blocks={locations[tuple(c['position'])][0] for c in changes}
for bi in sorted(changed_blocks,reverse=True):
    b=blocks[bi]
    replacement='('+b[1]+','+b[2]+','+b[3]+') = {"\n'+'\n'.join(rows[bi])+'\n"}'
    text=text[:b.start()]+replacement+text[b.end():]
first=re.search(r'(?m)^\(\d+,\d+,\d+\) = \{',text)
extra='\n'.join('"'+k+'" = (\n'+',\n'.join(v)+')' for k,v in new_definitions.items())+'\n'
text=text[:first.start()]+extra+text[first.start():]
path.write_text(text)
(ROOT/'tmp/waterchip-manual/opening-cell-edits.json').write_text(json.dumps(changes,indent=2)+'\n')
print('Edited',len(changes),'individually selected cells; all other coordinate rows retained.')
