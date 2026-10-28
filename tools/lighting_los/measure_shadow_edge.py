"""Measure LOS feathering by dividing two registered views of the same floor.

Using the earlier visible floor as the baseline cancels its unknown texture and
lighting. Measurements are rejected when the baseline is dark or the edge is not
monotonic. This avoids fitting a shader to mismatched repository floor sprites.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def registration(base, later, box, radius=120, expected_dy=None):
    x0, y0, x1, y1 = box
    template = base[y0:y1, x0:x1].mean(axis=2)
    template -= template.mean()
    h, w = template.shape
    top = max(0, y0-radius if expected_dy is None else y0+expected_dy-8)
    bottom = y1+5 if expected_dy is None else y1+expected_dy+8
    left = max(0, x0-5)
    roi = later[top:bottom, left:x1+5].mean(axis=2)
    windows = np.lib.stride_tricks.sliding_window_view(roi, (h, w))
    centered = windows - windows.mean(axis=(-2, -1), keepdims=True)
    scores = np.sum(centered * template, axis=(-2, -1)) / np.maximum(
        np.sqrt(np.sum(centered**2, axis=(-2, -1)) * np.sum(template**2)), 1)
    dy, dx = np.unravel_index(np.argmax(scores), scores.shape)
    return left + int(dx) - x0, top + int(dy) - y0, float(scores[dy, dx])


def measure(base_path, later_path, box, columns, rows, tile_size, output, expected_dy=None):
    base = np.asarray(Image.open(base_path).convert("RGB"), dtype=float)
    later = np.asarray(Image.open(later_path).convert("RGB"), dtype=float)
    dx, dy, confidence = registration(base, later, box, expected_dy=expected_dy)
    if confidence < 0.9:
        raise ValueError(f"Registration confidence too low: {confidence}")
    y0, y1 = rows
    results = []
    for x in range(*columns, 4):
        baseline = base[y0:y1, x-2:x+3].sum(axis=2)
        moved = later[y0+dy:y1+dy, x-2+dx:x+3+dx].sum(axis=2)
        ratios = moved / np.maximum(baseline, 1)
        profile = np.median(ratios, axis=1)
        bright = np.median(baseline, axis=1) > 45
        # Lit above, concealed below. Exclude texture/noise and any second edge.
        crossings = []
        for threshold in (0.9, 0.5, 0.1):
            hits = np.flatnonzero((profile[:-1] >= threshold) & (profile[1:] < threshold) & bright[:-1] & bright[1:])
            crossings.append(hits)
        if any(len(hits) != 1 for hits in crossings):
            continue
        positions = []
        for threshold, hits in zip((0.9, 0.5, 0.1), crossings):
            i = int(hits[0])
            positions.append(y0 + i + (profile[i]-threshold)/(profile[i]-profile[i+1]))
        if positions[0] < positions[1] < positions[2] and 1 < positions[2]-positions[0] < tile_size/2:
            results.append({"x": x, "y90": positions[0], "y50": positions[1], "y10": positions[2],
                            "vertical_width": positions[2]-positions[0]})
    report = {"base": str(base_path), "later": str(later_path), "registration": [dx, dy],
              "registration_correlation": confidence, "tile_pixels": tile_size, "samples": results}
    if len(results) >= 4:
        slope, intercept = np.polyfit([r["x"] for r in results], [r["y50"] for r in results], 1)
        widths = np.array([r["vertical_width"] for r in results]) / np.sqrt(1+slope*slope)
        report.update(edge_slope=float(slope), median_width_pixels=float(np.median(widths)),
                      median_width_source_pixels=float(np.median(widths)*32/tile_size))
    output.write_text(json.dumps(report, indent=2)+"\n")
    print(json.dumps({k:v for k,v in report.items() if k != "samples"}, indent=2))
    print("Accepted edge profiles:", len(results))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", type=Path)
    parser.add_argument("later", type=Path)
    parser.add_argument("--template", nargs=4, type=int, required=True)
    parser.add_argument("--columns", nargs=2, type=int, required=True)
    parser.add_argument("--rows", nargs=2, type=int, required=True)
    parser.add_argument("--tile-size", type=float, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--expected-dy", type=int)
    args = parser.parse_args()
    measure(args.base, args.later, args.template, args.columns, args.rows, args.tile_size, args.output, args.expected_dy)
