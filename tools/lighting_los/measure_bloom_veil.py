"""Measure gain and additive veil between two matching reference floor patches.

Uses the registered, stationary start of the 179.8-second junction sequence.
The positive intercept is consistent with bloom, but different authored tile
shading remains a confound. This does not recover an engine's filter settings.
"""
import argparse
import csv
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def measure(image, shift):
    dx, dy = shift
    patches = [image.crop((x+dx,y+dy,x+dx+60,y+dy+60)).convert('RGB')
               for x,y in ((506,427),(589,510))]
    a,b = [np.asarray(p,float) for p in patches]
    detail = [np.asarray(p,float)-np.asarray(p.filter(ImageFilter.GaussianBlur(5)),float) for p in patches]
    correlation = float(np.corrcoef(detail[0].mean(2).ravel(),detail[1].mean(2).ravel())[0,1])
    ac,bc = a-a.mean((0,1)),b-b.mean((0,1))
    gain = (ac*bc).sum((0,1))/np.maximum((ac*ac).sum((0,1)),1)
    offset = b.mean((0,1))-a.mean((0,1))*gain
    return dict(detail_correlation=correlation,gain_rgb=gain.tolist(),offset_rgb=offset.tolist(),
                rmse=float(np.sqrt(np.mean((b-a*gain-offset)**2))))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    measurements=[]
    with (args.folder/'frame-measurements.csv').open() as f:
        rows=list(csv.DictReader(f))
    for row in rows:
        # Stop before movement can change occlusion of the compared floor.
        if float(row['seconds'])>180.15:break
        if not row['lamp_x'] or float(row['correlation'])<.9:continue
        path=args.folder/f"frame_{int(row['frame'])+1:05d}.png"
        result=measure(Image.open(path),(int(row['lamp_x'])-687,int(row['lamp_y'])-434))
        result.update(seconds=float(row['seconds']),frame=path.name)
        if result['detail_correlation']>=.9:measurements.append(result)
    if not measurements:parser.exit(1,'No reliable matching patches.\n')
    offsets=np.array([m['offset_rgb'] for m in measurements])
    report=dict(frames=measurements,accepted=len(measurements),offset_rgb_median=np.median(offsets,axis=0).tolist(),
                offset_rgb_min=offsets.min(0).tolist(),offset_rgb_max=offsets.max(0).tolist(),
                caveat='Compatible with additive bloom; authored tile shading and compression are not independently known.')
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='frames'},indent=2))


if __name__=='__main__':main()
