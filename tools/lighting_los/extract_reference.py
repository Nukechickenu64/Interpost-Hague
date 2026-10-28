"""Extract original frames from the user's local Artemis recording using FFmpeg."""
import argparse
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("video", type=Path)
parser.add_argument("--ffmpeg", required=True, type=Path)
parser.add_argument("--output", required=True, type=Path)
parser.add_argument("--times", nargs="+", type=float, default=[60, 90, 180, 180.5, 181, 240, 300, 1080, 1320, 1380])
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
for seconds in args.times:
    destination = args.output / f"{seconds:07.1f}.png"
    subprocess.run([str(args.ffmpeg), "-hide_banner", "-loglevel", "error", "-ss", str(seconds),
                    "-i", str(args.video), "-frames:v", "1", "-y", str(destination)], check=True)
(args.output / "manifest.json").write_text(json.dumps({
    "source": str(args.video), "timestamps_seconds": args.times,
    "note": "Original decoded frames, without brightness or color correction."
}, indent=2) + "\n", encoding="utf-8")
print(f"Extracted {len(args.times)} reference frames to {args.output}")
