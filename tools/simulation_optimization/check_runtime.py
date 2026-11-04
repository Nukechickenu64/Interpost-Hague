"""Validate the complete focused optimization run, including actual runtime text."""
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
passed = re.findall(r"\*\*\* SUCCESS \*\*\* \[([^\]]+)\]", tests)
required = {
    "OPTIMIZATION - Atmos equivalence and vent lifecycle",
    "OPTIMIZATION - Cached shadow masks match original sampling",
    "OPTIMIZATION - Director telemetry equivalence",
}
if (len(set(passed)) != 19 or not required.issubset(passed)
        or "All Unit Tests Passed [19]" not in tests
        or "Caught 0 Runtimes." not in tests
        or re.search(r"runtime error:|!!! FAILURE !!!|Unit Tests Failed|--- SKIPPED ---", tests, re.I)):
    parser.exit(1, "FAIL: missing suite, skipped test, failure, runtime, or incomplete summary.\n")
print("PASS: all 19 optimization, atmosphere and Artemis suites; no test-phase runtimes.")
startup_runtimes = len(re.findall("runtime error:", startup, re.I))
print(f"Startup runtime errors: {startup_runtimes}.")
if startup_runtimes:
    parser.exit(1, "FAIL: startup contained runtime errors.\n")
for line in tests.splitlines():
    if "---  DEBUG  --- [OPTIMIZATION" in line:
        print(line.split("]: ", 1)[-1])
