"""Extract timestamped evidence from the supplied local recording (no downloads)."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument("video", type=Path)
parser.add_argument("--ffmpeg", required=True)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--times", type=float, nargs="+")
parser.add_argument("--step", type=int, default=60)
parser.add_argument("--end", type=int, default=6149)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
times = args.times or list(range(0, args.end, args.step))

def extract(seconds):
    path = args.output / f"{seconds:07.1f}.jpg"
    if not path.exists():
        subprocess.run([args.ffmpeg, "-hide_banner", "-loglevel", "error", "-ss", str(seconds),
                        "-i", str(args.video), "-frames:v", "1", "-q:v", "2", "-y", str(path)],
                       check=True, capture_output=True)
    return path

with ThreadPoolExecutor(max_workers=4) as pool:
    paths = list(pool.map(extract, times))
for start in range(0, len(paths), 16):
    sheet = Image.new("RGB", (1920, 1168), "#151515")
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths[start:start + 16]):
        frame = Image.open(path)
        frame.thumbnail((480, 270))
        x, y = (i % 4) * 480, (i // 4) * 292
        sheet.paste(frame, (x, y + 22))
        t = times[start + i]
        draw.text((x + 5, y + 4), f"{int(t)//3600:02}:{int(t)//60%60:02}:{t%60:04.1f}", fill="white")
    sheet.save(args.output / f"sheet-{start//16:02}.jpg", quality=90)
print(f"Extracted {len(paths)} frames and {(len(paths)+15)//16} contact sheets to {args.output}")
