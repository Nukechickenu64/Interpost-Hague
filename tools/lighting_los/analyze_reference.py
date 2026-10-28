"""Make timestamped sheets of every extracted frame and inspect native DMI states.

This is a review aid, not a claim that a recording reveals hidden lamp parameters.
"""
import argparse
import csv
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def dmi_states(path):
    source = Image.open(path).convert("RGBA")
    metadata = Image.open(path).info.get("Description", "")
    width = int(re.search(r"\bwidth = (\d+)", metadata)[1])
    height = int(re.search(r"\bheight = (\d+)", metadata)[1])
    index = 0
    for block in re.split(r"\nstate = ", metadata)[1:]:
        name = re.match(r'"(.*?)"', block)[1]
        dirs = int(re.search(r"dirs = (\d+)", block)[1])
        frames = int(re.search(r"frames = (\d+)", block)[1])
        columns = source.width // width
        x, y = (index % columns) * width, (index // columns) * height
        yield name, source.crop((x, y, x + width, y + height))
        index += dirs * frames


def sheets(folder, start, fps):
    frames = sorted(folder.glob("frame_*.png"))
    for first in range(0, len(frames), 30):
        sheet = Image.new("RGB", (6 * 308, 5 * 294), "#202020")
        draw = ImageDraw.Draw(sheet)
        for offset, path in enumerate(frames[first:first + 30]):
            x, y = (offset % 6) * 308, (offset // 6) * 294
            frame = Image.open(path).crop((300, 240, 1068, 920))
            frame.thumbnail((308, 272))
            sheet.paste(frame, (x, y + 20))
            draw.text((x + 3, y + 3), f"{start + (first + offset) / fps:.4f}s  frame {first + offset}", fill="white")
        sheet.save(folder / f"sheet_{first:04d}.png")
    (folder / "manifest.json").write_text(json.dumps({
        "start_seconds": start, "fps": fps, "frames": len(frames),
        "source_crop": [256, 0, 1068, 1080],
        "sheet_crop_relative_to_source_crop": [300, 240, 768, 680],
        "note": "All consecutive decoded frames included; sheets resize only, without color correction."
    }, indent=2) + "\n")


def atlas(paths, output):
    items = [(path.stem, state, icon) for path in paths for state, icon in dmi_states(path)]
    for first in range(0, len(items), 120):
        sheet = Image.new("RGB", (12 * 112, 10 * 124), "#202020")
        draw = ImageDraw.Draw(sheet)
        for offset, (file, state, icon) in enumerate(items[first:first + 120]):
            x, y = (offset % 12) * 112, (offset // 12) * 124
            draw.text((x + 2, y + 2), file[:18], fill="white")
            draw.text((x + 2, y + 14), state[:18], fill="white")
            scaled = icon.resize((96, 96), Image.Resampling.NEAREST)
            sheet.paste(scaled, (x, y + 28), scaled)
        sheet.save(output / f"atlas_{first:04d}.png")


def track_lamp(folder, start, fps):
    """Track a visible fixed lamp as a camera-motion reference, with confidence."""
    frames = sorted(folder.glob("frame_*.png"))
    first = np.asarray(Image.open(frames[0]).convert("RGB"), dtype=float).mean(axis=2)
    x, y, width, height = 687, 434, 28, 38
    template = first[y:y+height, x:x+width]
    template = template - template.mean()
    norm = np.sqrt(np.sum(template ** 2))
    rows = []
    tracking = True
    for index, path in enumerate(frames):
        frame = np.asarray(Image.open(path).convert("RGB"), dtype=float)
        gray = frame.mean(axis=2)
        confidence = None
        if tracking:
            left, top = max(0, x-12), max(0, y-12)
            roi = gray[top:min(y+height+12, gray.shape[0]), left:min(x+width+12, gray.shape[1])]
            if roi.shape[0] >= height and roi.shape[1] >= width:
                windows = np.lib.stride_tricks.sliding_window_view(roi, (height, width))
                centered = windows - windows.mean(axis=(-2, -1), keepdims=True)
                scores = np.sum(centered * template, axis=(-2, -1)) / np.maximum(norm * np.sqrt(np.sum(centered ** 2, axis=(-2, -1))), 1)
                dy, dx = np.unravel_index(np.argmax(scores), scores.shape)
                confidence = float(scores[dy, dx])
                tracking = confidence >= 0.75
                if tracking:
                    x, y = left + int(dx), top + int(dy)
            else:
                tracking = False
        rows.append([index, start + index/fps, x if tracking else None, y if tracking else None,
                     confidence, float(np.mean(frame.max(axis=2) <= 3))])
    with (folder / "frame-measurements.csv").open("w", newline="") as output:
        writer = csv.writer(output)
        writer.writerow(["frame", "seconds", "lamp_x", "lamp_y", "correlation", "near_black_fraction"])
        writer.writerows(rows)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path)
    parser.add_argument("--start", type=float, default=179.8)
    parser.add_argument("--fps", type=float, default=60)
    parser.add_argument("--dmi", nargs="*", type=Path, default=[])
    parser.add_argument("--track-lamp", action="store_true")
    args = parser.parse_args()
    sheets(args.frames, args.start, args.fps)
    if args.dmi:
        atlas(args.dmi, args.frames)
    if args.track_lamp:
        track_lamp(args.frames, args.start, args.fps)
