"""Static topology audit and sprite preview of the generated DMM (Pillow).

Preview is an unlit asset composite, not a Dream Seeker screenshot.
"""
from collections import deque, Counter
from functools import lru_cache
from pathlib import Path
import re
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'tmp/os13-map-reference/preview'
OUT.mkdir(parents=True,exist_ok=True)
s=(ROOT/'maps/os13/recreated.dmm').read_text()
defs=dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$',s,re.M|re.S))
grid={}
for b in re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}',s,re.S):
    x,y,z=map(int,b.group(1,2,3));rows=b[4].strip().splitlines()
    for j,row in enumerate(rows):grid[x,y+len(rows)-1-j,z]=defs[row]

def neighbors(p):
    x,y,z=p
    return [(x+1,y,z),(x-1,y,z),(x,y+1,z),(x,y-1,z)]

# Read static icon defaults through DM inheritance, including map overrides.
types={}
for p in [*ROOT.glob('code/**/*.dm'),ROOT/'maps/os13/recreation_assets.dm']:
    current=None
    for line in p.read_text(errors='replace').splitlines():
        m=re.match(r'^(/(?:obj|turf)[\w/]*)\s*(?://.*)?$',line)
        if m:current=m[1];types.setdefault(current,{})
        elif line.startswith('/') or (line and not line[0].isspace()):current=None
        elif current:
            m=re.match(r'^\t(icon|icon_state|parent_type)\s*=\s*(.*?)\s*(?://.*)?$',line)
            if m:types[current][m[1]]=m[2].strip('"\'')

@lru_cache(None)
def inherited(path):
    if not path:return {}
    own=types.get(path,{})
    parent=own.get('parent_type',path.rsplit('/',1)[0])
    return {**inherited(parent),**own}

@lru_cache(None)
def dmi(path):
    im=Image.open(ROOT/path).convert('RGBA')
    meta=Image.open(ROOT/path).info.get('Description','')
    if not meta:return im,{'':(0,32,32,1)}
    w=int(re.search(r'width = (\d+)',meta)[1]);h=int(re.search(r'height = (\d+)',meta)[1])
    states={};offset=0
    for block in re.split(r'\nstate = ',meta)[1:]:
        name=block.split('"')[1];dirs=int(re.search(r'dirs = (\d+)',block)[1]);frames=int(re.search(r'frames = (\d+)',block)[1])
        states[name]=offset,w,h,dirs;offset+=dirs*frames
    return im,states

missing=Counter()
def sprite(path,state,direction=2):
    if not path:return None
    try:im,states=dmi(path)
    except (FileNotFoundError,ValueError):missing[path]+=1;return None
    if state not in states:missing[(path,state)]+=1;return None
    offset,w,h,dirs=states[state]
    if dirs>1:offset += {2:0,1:1,4:2,8:3}.get(direction,0)
    x=offset%(im.width//w)*w;y=offset//(im.width//w)*h
    return im.crop((x,y,x+w,y+h))

blocked_prefixes=('/obj/structure/table','/obj/structure/closet','/obj/machinery/biomass_vat','/obj/machinery/vending','/obj/machinery/power/smes','/obj/machinery/r_n_d','/obj/structure/solar_panel_cart')
for z in range(2,10):
    floors={p for p,c in grid.items() if p[2]==z and '/turf/simulated/floor' in c}
    walk={p for p in floors if not any(b in grid[p] for b in blocked_prefixes)}
    start=(116,122,z);seen={start};todo=deque(seen)
    while todo:
        for p in neighbors(todo.popleft()):
            if p in walk and p not in seen:seen.add(p);todo.append(p)
    unreachable=walk-seen
    groups=[]
    while unreachable:
        first=next(iter(unreachable));part={first};todo=deque(part);unreachable.remove(first)
        while todo:
            for p in neighbors(todo.popleft()):
                if p in unreachable:unreachable.remove(p);part.add(p);todo.append(p)
        groups.append(part)
    print('z',z,'floor',len(floors),'reachable',len(seen),'disconnected',[(len(g),min(g)) for g in sorted(groups,key=len,reverse=True)[:12]])
    tiles={p:c for p,c in grid.items() if p[2]==z and '/area/os13/' in c}
    x1=min(p[0] for p in tiles)-1;x2=max(p[0] for p in tiles)+1
    y1=min(p[1] for p in tiles)-1;y2=max(p[1] for p in tiles)+1
    im=Image.new('RGBA',((x2-x1+1)*32,(y2-y1+1)*32+40),'#0a0b13')
    for p,c in tiles.items():
        x,y,_=p;px=(x-x1)*32;py=(y2-y)*32+40
        for part in reversed(re.split(r',\n',c)):
            path=part.split('{')[0].strip()
            if path.startswith('/area'):continue
            props=inherited(path).copy()
            for k,v in re.findall(r'(icon|icon_state)\s*=\s*[\'"](.*?)[\'"]',part):props[k]=v
            direction=int(re.search(r'\bdir\s*=\s*(\d+)',part)[1]) if re.search(r'\bdir\s*=\s*(\d+)',part) else 2
            if path=='/turf/simulated/wall/os13':
                mask=sum(bit for dx,dy,bit in [(0,1,1),(0,-1,2),(1,0,4),(-1,0,8)] if '/turf/simulated/wall' in grid.get((x+dx,y+dy,z),''))
                props={'icon':'icons/os13/turf/turf/wwalls.dmi','icon_state':f'rwall{mask}'}
            tile=sprite(props.get('icon'),props.get('icon_state',''),direction)
            if tile:im.alpha_composite(tile,(px,py+32-tile.height))
    d=ImageDraw.Draw(im)
    d.text((12,12),f'OS13 - template z={z} | static sprite composite | x {x1}-{x2}, y {y1}-{y2}',fill='white')
    for x in range(x1,x2+1,5):d.text(((x-x1)*32+2,26),str(x),fill='#aaaaaa')
    im.convert('RGB').save(OUT/f'deck-{z}.png')
print('Preview icon fallbacks:',missing.most_common(12))
