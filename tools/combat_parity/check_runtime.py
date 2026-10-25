"""Validate the combat suites without trusting BYOND's runtime counter alone."""
import argparse
from pathlib import Path
import re


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    args = parser.parse_args()
    raw = args.log.read_bytes()
    text = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")
    marker = "## UNIT_TEST ##: Testing Started."
    if marker not in text:
        parser.exit(1, "FAIL: combat tests never started.\n")
    startup, tests = text.split(marker, 1)
    expected = {
        "Dice distribution and strength table",
        "Weapon, hand and unarmed action authority",
        "Shield, parry progression, facing and commitment",
        "Feint survives and affects the follow-up",
        "Damage type, single DR and anatomical consequences",
        "Effort lifetime and fatigue accounting",
        "Movement, kick and grab integration",
        "Styles, readiness and equipment boundaries",
    }
    passed = re.findall(r"\*\*\* SUCCESS \*\*\* \[COMBAT PARITY - ([^\]]+)\]", tests)
    errors = re.search(r"runtime error:|!!! FAILURE !!!|Unit Tests Failed|\*\*\* FAIL", tests, re.I)
    if (set(passed) != expected or len(passed) != len(expected) or errors
            or "**** All Unit Tests Passed [8] ****" not in tests
            or "Caught 0 Runtimes." not in tests):
        parser.exit(1, "FAIL: missing/duplicate suite, failed assertion, runtime, or incomplete summary.\n")
    print("PASS: all eight combat suites passed; no runtime errors after testing began.")
    startup_runtimes = len(re.findall(r"runtime error:", startup, re.I))
    if startup_runtimes:
        print(f"STARTUP: {startup_runtimes} runtime error(s) occurred before the suites; this is not a clean-world certification.")


if __name__ == "__main__":
    main()
