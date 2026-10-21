#!/usr/bin/env python3
"""Report duplicated object dictionary entries across DMM files."""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
key_re = re.compile(r'^\s*"[A-Za-z0-9]+"\s*=\s*\((.+)\)\s*$')


def main():
    failures = 0
    for dirpath, _dirnames, filenames in os.walk(os.path.join(ROOT, "maps")):
        for filename in filenames:
            if not filename.endswith(".dmm"):
                continue
            path = os.path.join(dirpath, filename)
            seen = {}
            with io.open(path, "r", encoding="utf-8", errors="surrogateescape") as handle:
                for line in handle:
                    match = key_re.match(line)
                    if not match:
                        continue
                    value = match.group(1)
                    if value in seen:
                        print("%s: duplicate object entry (keys %r and %r)" % (
                            os.path.relpath(path, ROOT), seen[value], match.group(0).split("=")[0].strip()))
                        failures += 1
                    else:
                        seen[value] = match.group(0).split("=")[0].strip()
    if failures:
        print("%d duplicate object entries found." % failures)
        sys.exit(1)
    print("No duplicate object entries found.")


if __name__ == "__main__":
    main()