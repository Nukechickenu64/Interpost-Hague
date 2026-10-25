"""Static unlit sprite QA for the manual map; not a live-client render."""
from pathlib import Path
from functools import lru_cache
from collections import Counter
import re
from PIL import Image, ImageChops
from waterchip_manual import read_map

ROOT = Path(__file__).resolve().parents[2]
# Reuse the existing static inheritance/DMI resolver without its map loading
# or topology-reporting main body. Include direction/color for these fixtures.
source = (ROOT/'tools/os13_map/inspect_map.py').read_text()
helpers = source[source.index('# Read static'):source.index('blocked_prefixes=')]
helpers = helpers.replace('icon|icon_state|parent_type', 'icon|icon_state|parent_type|dir|color')
exec(helpers)

grid = read_map((ROOT/'maps/os13/waterchip-manual.dmm').read_text())

def render(z,xmin,xmax,ymin,ymax,relative_out):
    canvas = Image.new('RGBA',((xmax-xmin+1)*64,(ymax-ymin+1)*64),'#15151b')
    for (x,y,level),cell in grid.items():
        if level!=z or not (xmin<=x<=xmax and ymin<=y<=ymax):
            continue
        for atom in sorted(cell,key=lambda a:0 if a.startswith('/turf') else 1):
            path=atom.split('{')[0].strip()
            if not path.startswith(('/turf','/obj')):
                continue
            props=inherited(path).copy()
            for k,v in re.findall(r'(icon|icon_state|dir|color)\s*=\s*([^;}]+)',atom):
                props[k]=v.strip().strip('"\'')
            direction=props.get('dir','2')
            direction={'NORTH':1,'SOUTH':2,'EAST':4,'WEST':8}.get(direction,direction)
            tile=sprite(props.get('icon'),props.get('icon_state',''),int(direction))
            if tile:
                color=props.get('color','')
                if color.startswith('#'):
                    tile=ImageChops.multiply(tile,Image.new('RGBA',tile.size,color))
                scale=1 if 'matrix(0.5' in atom else 2
                tile=tile.resize((tile.width*scale,tile.height*scale),Image.Resampling.NEAREST)
                offset=16 if scale==1 else 0
                canvas.alpha_composite(tile,((x-xmin)*64+offset,(ymax-y)*64+offset))
    out=ROOT/relative_out
    canvas.convert('RGB').save(out)
    print(f'{out}: static unlit preview only')

render(4,92,110,97,114,'maps/os13/waterchip-manual-preview.png')
render(4,103,109,102,109,'maps/os13/waterchip-locker-review.png')
render(4,112,117,108,115,'maps/os13/waterchip-stair-hall-review.png')
render(6,113,122,136,144,'maps/os13/waterchip-housing-review.png')
assert not missing, dict(missing)
