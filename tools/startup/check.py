"""Check a completed full-map startup capture and optionally rank its proc profile."""
import argparse
import json
from pathlib import Path
import re


def read_text(path):
    raw = path.read_bytes()
    return raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--log", type=Path, default=Path("tmp/startup-benchmark.log"))
parser.add_argument("--timings", type=Path, default=Path("tmp/startup-timings.json"))
parser.add_argument("--profile", type=Path)
args = parser.parse_args()
log = read_text(args.log)
timings = json.loads(read_text(args.timings))
lighting = re.search(r"STARTUP_LIGHTING_CHECK: (\d+) tiles, 0 failures", log)
if ("STARTUP_BENCHMARK_READY:" not in log
        or not lighting or int(lighting[1]) == 0
        or "STARTUP_STARLIGHT_CHECK: 0 failures" not in log
        or re.search(r"runtime error:|!!! FAILURE !!!", log, re.I)
        or timings["total_seconds"] <= 0
        or not {"Mapping", "Atoms", "Air", "Lighting"}.issubset(timings["subsystems"])):
    parser.exit(1, "FAIL: incomplete startup, runtime, or invalid initial lighting.\n")
print(f"PASS: {int(lighting[1]):,} initial light samples and all space starlight boundaries; no runtimes.")
print(f"Subsystem initialization: {timings['total_seconds']:.3f} seconds")
for name, seconds in sorted(timings["subsystems"].items(), key=lambda row: row[1], reverse=True)[:8]:
    print(f"  {name:24s} {seconds:8.3f} s")
if args.profile:
    profile = json.loads(read_text(args.profile))
    rows = [profile[i:i + 6] for i in range(6, len(profile), 6)]
    print("Most expensive procs (self CPU seconds; profiling adds overhead):")
    for name, own, total, real, overtime, calls in sorted(rows, key=lambda row: row[1], reverse=True)[:20]:
        print(f"  {own:8.3f} s {calls:9d} calls  {name}")
