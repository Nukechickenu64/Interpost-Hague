"""Direct DMM edits at individually inspected coordinates in frame 4410.

No room filling, generated layout, or replay of the previous map writer.
"""
from pathlib import Path
import re
import json
import sys
import string

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/os13_map'))
from waterchip_manual import read_map

path = ROOT/'maps/os13/waterchip-manual.dmm'
text = path.read_text()
before = read_map(text)
definitions = dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$', text, re.M|re.S))
free = iter(a+b for a in reversed(string.ascii_letters) for b in reversed(string.ascii_letters) if a+b not in definitions)
extra = []
log = []

def edit(position, atoms, note):
    global text
    x,y,z = position
    key = next(free)
    block = re.search(r'\('+str(x)+r',1,'+str(z)+r'\) = \{"(.*?)"\}', text, re.S)
    rows = block[1].strip().splitlines()
    assert len(rows[len(rows)-y]) == 2
    rows[len(rows)-y] = key
    text = text[:block.start(1)]+'\n'+'\n'.join(rows)+'\n'+text[block.end(1):]
    extra.append('"'+key+'" = ('+','.join(atoms)+')\n')
    log.append(dict(position=position, evidence_frame=4410, before=before[position], after=atoms, note=note))

def floor(x,y,state):
    p=(x,y,4)
    edit(p, ['/turf/simulated/floor/fixed/os13/floors/state_'+state if a.startswith('/turf/') else a for a in before[p]], 'Manually matched floor '+state)

# Measured from the existing two-column north stairs at x=114 and x=115.
# In frame 4410, x=114 is pixel 787 and y=111 is pixel 521, pitch 72.
floor(114,115,'os4')
floor(115,115,'os4')
floor(113,113,'n00')
floor(114,113,'n00')
floor(115,113,'n00')
floor(113,112,'n00')
floor(114,112,'n00')
floor(115,112,'n00')
floor(116,112,'n00')
floor(112,111,'n00')
floor(113,111,'n00')
floor(114,111,'os4')
floor(115,111,'os4')
floor(116,111,'n00')
floor(112,110,'n00')
floor(113,110,'n00')
floor(114,110,'os4')
floor(115,110,'os4')
floor(116,110,'n00')
floor(112,109,'n00')
floor(113,109,'n00')
floor(114,109,'n00')
floor(115,109,'n00')
floor(116,109,'n00')
edit((116,114,4), ['/obj/structure/sign/os13_reference_deck',*before[116,114,4]], 'Visible yellow 3 DECK sign; not used to infer BYOND z')

first=text.index('(1,1,1)')
text=text[:first]+''.join(extra)+'\n'+text[first:]
after=read_map(text)
expected={tuple(c['position']) for c in log}
assert after.keys() == before.keys()
assert {p for p in after if after[p] != before[p]} == expected
path.write_text(text)
(ROOT/'tmp/waterchip-manual/stair-hall-frame4410-edits.json').write_text(json.dumps(log,indent=2)+'\n')
print('Directly edited',len(log),'named cells; every other cell preserved.')
