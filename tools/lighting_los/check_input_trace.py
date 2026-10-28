"""Validate a native-client normal-input replay, independently of direct Move tests."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
args = parser.parse_args()
raw = args.log.read_bytes()
text = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")
if text.count("ARTEMIS_INPUT complete") != 1 or re.search(r"ARTEMIS_INPUT_FAILURE|runtime error:", text):
    parser.exit(1, "FAIL: replay incomplete/duplicated, movement failure, or runtime error.\n")
rows = [json.loads(line.split("ARTEMIS_INPUT ", 1)[1]) for line in text.splitlines()
        if "ARTEMIS_INPUT {" in line]
for phase in ("before-1", "before-2", "before-3", "start-1", "start-2", "start-3", "stop"):
    assert sum(row["phase"] == phase for row in rows) == 1, f"Missing or duplicated phase: {phase}"
for step in range(1, 4):
    before = next(row for row in rows if row["phase"] == f"before-{step}")
    start = next(row for row in rows if row["phase"] == f"start-{step}")
    samples = [row for row in rows if row["phase"] == f"glide-{step}"]
    assert start["x"] == before["x"] and start["y"] == before["y"] - 1, "Wrong movement destination"
    assert start["target_x"] == start["x"] and start["target_y"] == start["y"], "LOS target missed actual input movement"
    assert abs(start["eye_x"] - before["x"]) < 0.001 and abs(start["eye_y"] - before["y"]) < 0.001, "Step began with a snapped eye"
    assert start["ends"] > start["started"], "Normal input produced no glide"
    assert samples, "No intermediate journey samples"
    last_y = before["y"]
    for sample in samples:
        assert sample["depth"] == 0, "Movement nesting leaked"
        assert abs(sample["ends"] - start["ends"]) < 0.001, "Refresh restarted journey"
        assert start["y"] - 0.001 <= sample["eye_y"] <= last_y + 0.001, "Glide reversed or overshot"
        last_y = sample["eye_y"]
    assert abs(last_y - start["y"]) < 0.001, "Glide stopped short"
stop = next(row for row in rows if row["phase"] == "stop")
rest = [row for row in rows if row["phase"] == "rest"]
assert len(rest) == 10, "Missing stop samples"
for row in rest:
    assert row["x"] == stop["x"] and row["y"] == stop["y"], "Body moved after stop"
    assert row["eye_x"] == stop["x"] and row["eye_y"] == stop["y"], "Eye moved after stop"
    assert row["ends"] == stop["ends"], "Stationary refresh restarted stopped journey"
print(f"PASS: three normal-input steps and ten stationary refreshes; {len(rows)} motion samples.")
print("Glide durations (deciseconds):", [row["ends"] - row["started"] for row in rows if row["phase"].startswith("start-")])
