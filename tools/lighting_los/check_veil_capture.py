"""Measure the fixed-junction native tile-glow comparison (608px map exports).

These coordinates are fixture-specific. They verify the additive contribution,
its strength control and occlusion, not pixel equality with the source video.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('folder',type=Path)
args=parser.parse_args()
images={n:Image.open(args.folder/f'aligned-{n}.png').convert('RGB') for n in ('0','128','255','dark')}
arrays={n:np.asarray(im,dtype=float) for n,im in images.items()}
assert all(im.size==images['0'].size for im in images.values())
assert images['0'].width==608, 'Fixture coordinates require a 608px native export.'
# Keep the occlusion sample inside the opaque shadow, away from its deliberately
# feathered edge (the edge already has nonzero pixels in the zero-glow capture).
regions={'white_floor':(354,226,380,252),'green_floor':(514,226,542,252),'occluded':(460,310,520,344)}
report={}
for name,(x1,y1,x2,y2) in regions.items():
    means={n:a[y1:y2,x1:x2].mean((0,1)) for n,a in arrays.items()}
    report[name]={n:v.tolist() for n,v in means.items()}
    full=means['255']-means['0'];half=means['128']-means['0']
    report[name]['added_rgb']=full.tolist()
    if name!='occluded':
        assert full.max()>5, (name,'no visible additive glow')
        assert np.max(np.abs(full-half*255/128))<3, (name,'strength control is not proportional')
    else:
        assert arrays['255'][y1:y2,x1:x2].max()==0, 'Glow leaked into the occluded region.'
report['junction_dark_max']=int(arrays['dark'][96:288,257:570].max())
report['note']='Junction dark maximum is recorded separately; enclosed-room zero-black verification uses its own fixture.'
room_path=args.folder/'room-dark.png'
if room_path.exists():
    room=np.asarray(Image.open(room_path).convert('RGB'))[40:440,112:570]
    report['enclosed_room_dark']={'max_channel':int(room.max()),'nonblack_pixels':int(np.any(room!=0,axis=2).sum())}
    assert room.max()==0, 'Enclosed room retained visible light with all lamps off.'
(args.folder/'veil-comparison.json').write_text(json.dumps(report,indent=2)+'\n')
out=Image.new('RGB',(1256,424),'#171717');draw=ImageDraw.Draw(out)
for j,(label,key) in enumerate((('Tile light only','0'),('Tile light + blurred glow','255'))):
    draw.text((j*628+12,8),label,fill='white')
    crop=images[key].crop((256,96,570,288)).resize((628,384),Image.Resampling.NEAREST)
    out.paste(crop,(j*628,32))
out.save(args.folder/'lighting-comparison.png')
print(json.dumps(report,indent=2))
