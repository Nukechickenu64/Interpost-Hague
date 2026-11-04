"""Compare stationary 608x480 native exports from drop_shadow_capture=1.

Copy the capture sequence to before.png, after.png and dark.png in one folder.
This checks the enclosed-room fixture, not arbitrary gameplay screenshots.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("folder", type=Path)
args = parser.parse_args()
images = {name: Image.open(args.folder / f"{name}.png").convert("RGB")
          for name in ("before", "after", "dark")}
assert all(image.size == (608, 480) for image in images.values()), "Wrong viewport"
# The upper strip contains the map's hover-name HUD, not terrain pixels.
region = (112, 64, 570, 440)
pixels = {name: np.asarray(image.crop(region)).astype(int)
          for name, image in images.items()}
delta = pixels["after"] - pixels["before"]
# Animated screen grain can remain on HUD copies. Detect broad illumination
# changes after a fixed two-pixel blur; keep the displayed images untouched.
smoothed = {name: np.asarray(image.filter(ImageFilter.GaussianBlur(2))).astype(int)
            for name, image in images.items()}
smooth_delta = smoothed["after"] - smoothed["before"]
x0, y0, x1, y1 = region
map_delta = smooth_delta[y0:y1, x0:x1]
# Both boxes start on the row south of their caster's occupied tile.
cross_tile = {
    "character_south_tile": (320, 256, 370, 284),
    "crate_south_tile": (288, 224, 336, 244),
}
cross_counts = {}
for name, (left, top, right, bottom) in cross_tile.items():
    cross_counts[name] = int(np.any(smooth_delta[top:bottom, left:right] < -3, axis=2).sum())
report = {
    "map_region": region,
    "darkened_pixels_over_3": int(np.any(delta < -3, axis=2).sum()),
    "brightened_pixels_over_3": int(np.any(delta > 3, axis=2).sum()),
    "maximum_darkening": int(-delta.min()),
    "dark_maximum": int(pixels["dark"].max()),
    "dark_nonblack_pixels": int(np.any(pixels["dark"] != 0, axis=2).sum()),
    "smoothed_maximum_darkening": int(-map_delta.min()),
    "smoothed_brightened_pixels_over_3": int(np.any(map_delta > 3, axis=2).sum()),
    "cross_tile_darkened_pixels_over_3": cross_counts,
}
assert report["darkened_pixels_over_3"] > 100, "No visible shadow contribution"
assert report["smoothed_brightened_pixels_over_3"] < 20, "Scene moved or changed between captures"
assert all(count > 25 for count in cross_counts.values()), "Shadow disappears on a neighbouring floor tile"
assert report["dark_maximum"] == 0, "Enclosed blackout is not black"
(args.folder / "comparison.json").write_text(json.dumps(report, indent=2) + "\n")
crop = (210, 130, 440, 330)
canvas = Image.new("RGB", (940, 440), "#17191c")
draw = ImageDraw.Draw(canvas)
for i, (name, label) in enumerate((("before", "Without projected shadows"),
                                   ("after", "With projected shadows"))):
    draw.text((10 + i * 470, 12), label, fill="white")
    canvas.paste(images[name].crop(crop).resize((460, 400), Image.Resampling.NEAREST),
                 (i * 470, 35))
canvas.save(args.folder / "comparison.png")
print(json.dumps(report, indent=2))
