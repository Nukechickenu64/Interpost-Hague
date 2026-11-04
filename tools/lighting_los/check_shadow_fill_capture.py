"""Check paired native exports with identical light and masked/unmasked shadows."""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("folder", type=Path)
args = parser.parse_args()
folder = args.folder
images = {
    name: Image.open(folder / f"{name}.png").convert("RGB")
    for name in ("away-unmasked", "away-masked", "aimed-unmasked", "aimed-masked", "dark")
}
assert all(image.size == (608, 480) for image in images.values()), "Unexpected native export dimensions"
# Keep the caster, HUD, and animated lens pixels out of the floor measurement.
receiver = (320, 256, 352, 280)
control = (160, 192, 304, 320)
terrain = (112, 64, 570, 440)
smoothed = {name: np.asarray(image.filter(ImageFilter.GaussianBlur(2)), dtype=np.int16)
            for name, image in images.items()}


def crop(array, box):
    left, top, right, bottom = box
    return array[top:bottom, left:right]


report = {"receiver_region": receiver, "control_region": control, "terrain_region": terrain}
for aim in ("away", "aimed"):
    delta = smoothed[f"{aim}-masked"] - smoothed[f"{aim}-unmasked"]
    floor = crop(delta, receiver)
    controls = crop(delta, control)
    report[aim] = {
        "receiver_brightened_pixels_over_3": int((floor.max(axis=2) > 3).sum()),
        "receiver_darkened_pixels_over_3": int((floor.min(axis=2) < -3).sum()),
        "receiver_maximum_brightening": int(floor.max()),
        "control_maximum_absolute_change": int(np.abs(controls).max()),
    }
dark = crop(np.asarray(images["dark"]), terrain)
report["dark_maximum"] = int(dark.max())
report["dark_nonblack_pixels"] = int(np.any(dark, axis=2).sum())
(folder / "comparison.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
assert report["away"]["receiver_brightened_pixels_over_3"] < 5, "A beam aimed away removed the shadow"
assert report["aimed"]["receiver_brightened_pixels_over_3"] > 30, "A beam aimed at the floor failed to remove the shadow"
assert all(report[aim]["receiver_darkened_pixels_over_3"] < 5 for aim in ("away", "aimed")), "Cancellation added darkness"
assert all(report[aim]["control_maximum_absolute_change"] <= 3 for aim in ("away", "aimed")), "Illumination changed between paired exports"
assert report["dark_maximum"] == 0, "Unlit terrain retained a nonblack pixel"
# Display the actual captured pixels enlarged with nearest-neighbor sampling.
panel = Image.new("RGB", (640, 360), "#181818")
draw = ImageDraw.Draw(panel)
for row, aim in enumerate(("away", "aimed")):
    for column, mode in enumerate(("unmasked", "masked")):
        left, top = column * 320, row * 180
        draw.text((left + 8, top + 8), f"Lamp {aim}: {mode}", fill="white")
        panel.paste(images[f"{aim}-{mode}"].crop((304, 224, 368, 272)).resize((192, 144), Image.Resampling.NEAREST), (left + 64, top + 28))
panel.save(folder / "comparison.png")
print("PASS: aimed light removes the floor shadow; away-facing light preserves it; blackout is exact zero.")
