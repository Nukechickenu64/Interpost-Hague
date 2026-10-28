"""Check native dark-room exports without counting HUD pixels as light leaks."""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("before", type=Path)
parser.add_argument("after", type=Path)
args = parser.parse_args()


def pixels(folder, name, box=(112, 0, 570, 480), offset=(0, 0)):
    dx, dy = offset
    box = (box[0] + dx, box[1] + dy, box[2] + dx, box[3] + dy)
    source = Image.open(folder / f"{name}.png").convert("RGB")
    assert 0 <= box[0] < box[2] <= source.width and 0 <= box[1] < box[3] <= source.height
    return np.asarray(source.crop(box))


report = {}
# Native exports may include offscreen HUD backing in their canvas bounds.
# Register using the unchanged HUD, never by fitting the darkness under test.
hud_box = (12, 33, 106, 95)
hud = pixels(args.before, "lit", hud_box).astype(int)
registration = []
for dy in range(-128, 129, 32):
    for dx in range(-128, 129, 32):
        try:
            candidate = pixels(args.after, "lit", hud_box, (dx, dy)).astype(int)
        except AssertionError:
            continue
        registration.append((float(np.abs(candidate - hud).mean()), dx, dy))
error, dx, dy = min(registration)
assert error < 1, "Native exports have mismatched HUD scale or content"
report["hud_registration"] = {"offset": [dx, dy], "mean_error": error}
for label, folder in (("before", args.before), ("after", args.after)):
    for mode in ("dark-filtered", "dark-unfiltered"):
        data = pixels(folder, mode, offset=(dx, dy) if label == "after" else (0, 0))
        report[f"{label}_{mode}"] = {
            "max_channel": int(data.max()),
            "nonblack_pixels": int(np.count_nonzero(np.any(data != 0, axis=2))),
        }

# An illuminated floor patch away from the player and wall boundaries must
# retain brightness and contrast. Keep the pixel difference in the report:
# this statistical control does not claim identical rendered texture pixels.
lit_box = (225, 194, 255, 222)
before_lit = pixels(args.before, "lit", lit_box)
after_lit = pixels(args.after, "lit", lit_box, (dx, dy))
report["lit_floor_max_difference"] = int(np.abs(before_lit.astype(int) - after_lit).max())
report["lit_floor_mean_rgb_before"] = before_lit.mean(axis=(0, 1)).tolist()
report["lit_floor_mean_rgb_after"] = after_lit.mean(axis=(0, 1)).tolist()
report["lit_floor_mean_rgb_difference"] = float(np.abs(before_lit.mean(axis=(0, 1)) - after_lit.mean(axis=(0, 1))).max())
report["lit_floor_contrast_difference"] = float(np.abs(before_lit.std(axis=(0, 1)) - after_lit.std(axis=(0, 1))).max())
report["lit_floor_correlation"] = float(np.corrcoef(before_lit.flatten(), after_lit.flatten())[0, 1])
print(json.dumps(report, indent=2))
(args.after / "comparison.json").write_text(json.dumps(report, indent=2) + "\n")
assert report["before_dark-filtered"]["nonblack_pixels"] > 0, "Baseline did not reproduce the wall glow"
assert report["before_dark-unfiltered"]["nonblack_pixels"] == 0, "Baseline has a light leak unrelated to the filters"
assert report["after_dark-filtered"]["nonblack_pixels"] == 0, "Filtered darkness still exposes wall edges"
assert report["after_dark-unfiltered"]["nonblack_pixels"] == 0, "Unfiltered darkness regressed"
assert before_lit.max() > 0 and report["lit_floor_mean_rgb_difference"] <= 1, "Lit floor brightness changed"
assert report["lit_floor_contrast_difference"] <= 1 and report["lit_floor_correlation"] >= 0.9, "Lit floor contrast/texture changed materially"
print("PASS: native darkness is black with filters enabled; lit floor brightness is preserved.")
