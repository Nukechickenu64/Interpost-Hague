"""Direct edits for individual tiles inspected in full-resolution frame 6000."""
from pathlib import Path
import sys, re, json, string
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/os13_map'))
from waterchip_manual import read_map
path=ROOT/'maps/os13/waterchip-manual.dmm'
text=path.read_text()
before=read_map(text)
changes={}
notes={}

def floor(x,y,state):
    p=(x,y,6)
    assert any(a.startswith('/turf/simulated/floor') for a in before[p]),p
    changes[p]=['/turf/simulated/floor/fixed/os13/'+state if a.startswith('/turf/') else a for a in before[p]]
    notes[p]='Floor art manually matched at 72-pixel tile pitch'

def add(p,atom,note):
    changes[p]=[atom,*changes.get(p,before[p])]
    notes[p]=notes.get(p,'')+'; '+note

# The lift door (116,123) and south psi door (116,119) anchor the route.
# Frame 5490 is centered at (119,126); frame 5640 at (121,133).
# The repeated cabin threshold and wall corner track north to frame 6000.
# Frame 6000: center (120,142,6) at pixel (787,541).
floor(113,142,'floors/state_os4')
floor(114,142,'floors/state_os4')
floor(115,142,'floors/state_os4')
floor(116,142,'floors/state_os4')
floor(117,142,'floors/state_os4')
floor(118,142,'floors/state_os4')
floor(119,142,'floors/state_os4')
floor(120,142,'floors/state_os4')
floor(121,142,'floors/state_os4')
floor(120,141,'floors/state_os4')
floor(121,141,'floors/state_os4')
floor(120,140,'floors/state_os4')
floor(121,140,'perforated_cover')
add((121,142,6),'/obj/machinery/atmospherics/unary/vent_pump/os13_reference','Square vent at pixel (859,541)')
add((120,141,6),'/obj/machinery/floor_light/os13','Round grated floor light at pixel (787,613)')
add((121,136,6),'/obj/machinery/atmospherics/unary/vent_pump/os13_reference','Square vent at pixel (859,973); underlying floor not yet transcribed')
add((116,143,6),'/obj/machinery/door/os13_office','North cabin hatch at pixel (499,469)')
add((120,143,6),'/obj/machinery/door/os13_office','North cabin hatch at pixel (787,469)')
add((116,140,6),'/obj/machinery/door/os13_office','South cabin hatch at pixel (499,685)')
add((122,141,6),'/obj/machinery/door/os13_office{dir = 4}','East cabin hatch at pixel (931,613)')

definitions=dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$',text,re.M|re.S))
free=iter(a+b for a in reversed(string.ascii_letters) for b in reversed(string.ascii_letters) if a+b not in definitions)
extra=[]
log=[]
for p,atoms in changes.items():
    x,y,z=p
    assert atoms!=before[p]
    key=next(free)
    block=re.search(r'\('+str(x)+r',1,'+str(z)+r'\) = \{"(.*?)"\}',text,re.S)
    rows=block[1].strip().splitlines()
    assert len(rows[len(rows)-y])==2
    rows[len(rows)-y]=key
    text=text[:block.start(1)]+'\n'+'\n'.join(rows)+'\n'+text[block.end(1):]
    extra.append('"'+key+'" = ('+','.join(atoms)+')\n')
    log.append(dict(position=p,evidence_frame=6000,before=before[p],after=atoms,note=notes[p]))
first=text.index('(1,1,1)')
text=text[:first]+''.join(extra)+'\n'+text[first:]
after=read_map(text)
assert after.keys()==before.keys()
assert {p for p in after if after[p]!=before[p]}==set(changes)
path.write_text(text)
(ROOT/'tmp/waterchip-manual/housing-frame6000-edits.json').write_text(json.dumps(log,indent=2)+'\n')
print('Edited',len(log),'individually inspected cells; all others identical.')
