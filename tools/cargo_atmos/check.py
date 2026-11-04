"""Check the native cargo atmosphere regression without trusting runtime counters."""
from pathlib import Path
import re
import sys

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("tmp/cargo-atmos/regression.log")
raw = path.read_bytes()
log = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")
assert "*** SUCCESS *** [MOB: Room breaths match lung thresholds]" in log, "Breathing regression did not pass"
assert "CARGO_ATMOS: 3 elevator occupants, 200 breathing/atmosphere cycles" in log, "Elevator regression did not finish"
assert "CARGO_ATMOS_RESULT: PASS runtimes=0" in log, "Regression did not pass cleanly"
assert not re.search(r"runtime error:|!!! FAILURE !!!|CARGO_ATMOS_RESULT: FAIL", log, re.I), "Native test failed or runtimed"
print("PASS: room-air breathing hazards and 200 occupied cargo elevator atmosphere cycles; no runtimes.")
