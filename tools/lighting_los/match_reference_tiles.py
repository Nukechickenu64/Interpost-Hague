"""Rank all opaque OS13 turf directions against a registered reference tile.

Correlation removes an unknown uniform lighting gain and bloom offset. It does
not establish lighting parity; inspect the returned residual and sprite first.
"""
import argparse
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def tiles(path):
    with Image.open(path) as source:
        meta = source.info.get('Description', '')
        if not re.search(r'\bwidth = 32\b', meta) or not re.search(r'\bheight = 32\b', meta):
            return
        source = source.convert('RGBA')
        columns = source.width // 32
        index = 0
        for block in re.split(r'\nstate = ', meta)[1:]:
            name = re.match(r'"(.*?)"', block)[1]
            directions = int(re.search(r'dirs = (\d+)', block)[1])
            frames = int(re.search(r'frames = (\d+)', block)[1])
            for direction in range(directions):
                i = index + direction
                x, y = i % columns * 32, i // columns * 32
                tile = source.crop((x, y, x+32, y+32))
                if tile.getchannel('A').getextrema() == (255, 255):
                    yield name, direction, tile.convert('RGB')
            index += directions * frames


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('frame', type=Path)
    parser.add_argument('--xy', type=int, nargs=2, required=True)
    parser.add_argument('--size', type=int, default=84)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    frame = Image.open(args.frame).convert('RGB')
    candidates = []
    for root in ('icons/os13/turf', 'icons/turf'):
        for path in Path(root).rglob('*.dmi'):
            candidates.extend((str(path), name, direction, tile) for name, direction, tile in tiles(path))
    def detail(image):
        # Remove broad illumination/bloom gradients before matching texture.
        high = np.asarray(image, float)-np.asarray(image.filter(ImageFilter.GaussianBlur(2)), float)
        return high[3:-3,3:-3].mean(2).ravel()
    data = np.array([detail(c[3]) for c in candidates])
    data -= data.mean(1, keepdims=True)
    data /= np.maximum(np.linalg.norm(data, axis=1, keepdims=True), 1e-10)
    positions = [(args.xy[0]+dx, args.xy[1]+dy) for dx in range(-10, 11) for dy in range(-10, 11)]
    patches = [frame.crop((x, y, x+args.size, y+args.size)).resize((32,32), Image.Resampling.BILINEAR) for x,y in positions]
    probes = np.array([detail(p) for p in patches])
    probes -= probes.mean(1, keepdims=True)
    probes /= np.maximum(np.linalg.norm(probes, axis=1, keepdims=True), 1e-10)
    scores = data @ probes.T
    indices = np.argsort(scores.max(1))[-12:][::-1]
    results = []
    sheet = Image.new('RGB', (6*250, 2*200), '#202020')
    draw = ImageDraw.Draw(sheet)
    for number, i in enumerate(indices):
        j = scores[i].argmax()
        path, state, direction, tile = candidates[i]
        original = np.asarray(tile,float)[3:-3,3:-3].reshape(-1,3)
        target = np.asarray(patches[j],float)[3:-3,3:-3].reshape(-1,3)
        gain = ((original-original.mean(0))*(target-target.mean(0))).sum(0)/np.maximum(((original-original.mean(0))**2).sum(0),1)
        offset = target.mean(0)-original.mean(0)*gain
        error = float(np.sqrt(np.mean((target-original*gain-offset)**2)))
        results.append(dict(path=path,state=state,direction_index=int(direction),xy=positions[j],correlation=float(scores[i,j]),gain=gain.tolist(),offset=offset.tolist(),rmse=error))
        x,y = number%6*250,number//6*200
        draw.text((x+2,y+2),f'{Path(path).name} {state}\ndir {direction}  r={scores[i,j]:.3f}',fill='white')
        sheet.paste(patches[j].resize((120,120)),(x,y+45))
        tinted = Image.fromarray(np.uint8(np.clip(np.asarray(tile,float)*gain+offset,0,255)))
        sheet.paste(tinted.resize((120,120)),(x+125,y+45))
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(results,indent=2)+'\n')
    sheet.save(args.output.with_suffix('.png'))
    print(json.dumps(results[:3],indent=2))


if __name__ == '__main__':
    main()
