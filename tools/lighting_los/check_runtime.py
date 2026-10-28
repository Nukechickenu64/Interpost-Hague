"""Check every focused suite and scan actual runtime text, not just BYOND's counter."""
import argparse
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
args = parser.parse_args()
raw = args.log.read_bytes()
text = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")
marker = "## UNIT_TEST ##: Testing Started."
if marker not in text:
    parser.exit(1, "FAIL: tests never started.\n")
startup, tests = text.split(marker, 1)
expected = {
    "Cardinal and diagonal shadow projection",
    "Door and moving blocker invalidation",
    "Colored light falloff and door occlusion",
    "Shifted camera retains body line of sight",
    "Continuous mesh motion and viewer isolation",
    "Exposure spectrum and smooth light boundary",
    "Floor lamp bloom follows power and damage",
    "Projected silhouettes follow actual light",
}
passed = re.findall(r"\*\*\* SUCCESS \*\*\* \[ARTEMIS - ([^\]]+)\]", tests)
if (set(passed) != expected or len(passed) != len(expected)
        or re.search(r"runtime error:|!!! FAILURE !!!|Unit Tests Failed", tests, re.I)
        or f"All Unit Tests Passed [{len(expected)}]" not in tests or "Caught 0 Runtimes." not in tests):
    parser.exit(1, "FAIL: missing suite, assertion failure, runtime, or incomplete summary.\n")
print(f"PASS: all {len(expected)} Artemis lighting/LOS suites; no test-phase runtimes.")
count = len(re.findall("runtime error:", startup, re.I))
print(f"Startup runtime errors: {count} (separate from test results).")
