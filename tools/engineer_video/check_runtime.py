"""Check focused test output, including errors missed by BYOND's runtime counter."""
import re
import sys
from pathlib import Path

log = Path(sys.argv[1] if len(sys.argv) > 1 else
           "tmp/engineer-video-check/native-atmos-runtime.log")
text = log.read_text(encoding="utf-8-sig")
marker = "## UNIT_TEST ##: Testing Started."
assert marker in text, "Focused tests never started"
tests = text.split(marker, 1)[1]
assert "**** All Unit Tests Passed [10] ****" in tests, "Ten suites did not pass"
assert tests.count("*** SUCCESS *** [ENGINEER VIDEO - ") == 10, "Missing suite results"
assert "Caught 0 Runtimes." in tests, "Runtime counter is not zero"
assert not re.search(r"runtime error:|\*\*\* FAIL", tests, re.IGNORECASE), \
    "Test output contains an error despite the final summary"
print("PASS: all ten engineer suites passed with no runtime errors after testing began.")
