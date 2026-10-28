"""Fit a uniform light multiplier to known floor textures in a reference frame.

Search a small registration neighborhood. Report residuals, rather than treating
compression, bloom, texture mismatches or an arbitrary lamp setup as exact parity.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

from analyze_reference import dmi_states


def fit_tile(frame, x, y, candidates):
    results = []
    for name, icon in candidates:
        best = None
        for size in (82, 83, 84, 85, 86):
            for sampling in (Image.Resampling.NEAREST, Image.Resampling.BILINEAR):
                texture = np.asarray(icon.convert("RGB").resize((size, size), sampling), dtype=float)[8:-8, 8:-8]
                texture = texture.reshape(-1, 3)
                for dx in range(-3, 4):
                    for dy in range(-3, 4):
                        patch = frame[y+dy+8:y+dy+size-8, x+dx+8:x+dx+size-8].reshape(-1, 3)
                        gain = (texture * patch).sum(axis=0) / np.maximum((texture * texture).sum(axis=0), 1)
                        residual = patch - texture * gain
                        error = float(np.mean(residual ** 2))
                        if best is None or error < best[0]:
                            best = (error, {"state": name, "xy": [x+dx, y+dy], "size": size,
                                           "sampling": sampling.name, "gain_rgb": gain.tolist(),
                                           "rmse_rgb_255": error ** 0.5,
                                           "usable_for_calibration": error ** 0.5 <= 5})
        results.append(best)
    return [entry[1] for entry in sorted(results, key=lambda entry: entry[0])[:3]]


if __name__ == "__main__":
    source = Path("tmp/artemis-lighting/reference/00180.0.png")
    frame = np.asarray(Image.open(source).convert("RGB"), dtype=float)
    candidates = []
    for path in Path("icons").rglob("*.dmi"):
        if "floor" not in str(path).lower() and "newmaintenance" not in str(path).lower():
            continue
        try:
            candidates.extend((f"{path.as_posix()}:{name}", icon) for name, icon in dmi_states(path)
                              if icon.size == (32, 32) and icon.getchannel("A").getextrema() == (255, 255))
        except (TypeError, AttributeError):
            continue
    # Rank all floor textures coarsely before the expensive registration search.
    templates = np.stack([np.asarray(icon.convert("RGB").resize((84, 84), Image.Resampling.BILINEAR), dtype=float)[8:-8, 8:-8].reshape(-1, 3)
                          for _, icon in candidates])
    template_power = np.maximum((templates * templates).sum(axis=1), 1)
    samples = {"white_south": [918, 499], "white_southwest": [834, 499],
               "white_west": [834, 415], "green_east": [1170, 415],
               "green_south": [1086, 499], "white_far_west": [750, 415]}
    output = {}
    for name, (x, y) in samples.items():
        patch = frame[y+8:y+76, x+8:x+76].reshape(-1, 3)
        gains = (templates * patch[None, :, :]).sum(axis=1) / template_power
        errors = np.mean((templates * gains[:, None, :] - patch[None, :, :]) ** 2, axis=(1, 2))
        selected = [candidates[i] for i in np.argsort(errors)[:12]]
        output[name] = fit_tile(frame, x, y, selected)
    destination = Path("tmp/artemis-lighting/frame-study/tile-fits.json")
    destination.write_text(json.dumps({"source": str(source), "samples": output}, indent=2) + "\n")
    print(json.dumps(output, indent=2))
