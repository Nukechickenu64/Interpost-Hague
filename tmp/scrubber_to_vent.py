#!/usr/bin/env python3
"""Convert mapped air scrubbers into equivalent vents.

Preserves every other byte of the file: the type occurs inside object
dictionaries, and we only rewrite the matched type segment plus its tag
block. Tags that only make sense on scrubbers (icon_state, use_power) are
replaced with vent equivalents instead of being carried over unchanged,
so no duplicate object dictionaries are produced.

- vent_scrubber/on (scrubbing, powered) -> vent_pump/on filtered by modcon.
- vent_scrubber      (off)             -> vent_pump with use_power = 0.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAPS = [
    "maps/alpha/alpha.dmm",
    "maps/away/bearcat/bearcat.dmm",
    "maps/away/blueriver/blueriver.dmm",
    "maps/away/casino/casino.dmm",
    "maps/away/errant_pisces/errant_pisces.dmm",
    "maps/away/icarus/icarus.dmm",
    "maps/away/lost_supply_base/lost_supply_base.dmm",
    "maps/away/magshield/magshield.dmm",
    "maps/away/slavers/slavers_base.dmm",
    "maps/away/yacht/yacht.dmm",
    "maps/derelict/derelict.dmm",
    "maps/dreyfus/dreyfus.dmm",
    "maps/example/example.dmm",
    "maps/frontier/frontier.dmm",
    "maps/gen1234/gen1234.dmm",
    "maps/neoderelict/neoderelict.dmm",
    "maps/overmap_example/bearcat/bearcat.dmm",
]

SCRUBBER_RE = re.compile(
    r"/obj/machinery/atmospherics/unary/vent_scrubber(/on)?(\{([^{}]*)\})?"
)

TAG_RE = re.compile(
    r'\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*("[^"]*"|[^{};]+)\s*'
)


def convert_segment(match):
    is_on = match.group(1) == "/on"
    blocks = match.group(3) if match.group(3) is not None else ""
    new_tags = []
    for tag_match in TAG_RE.finditer(blocks):
        key = tag_match.group(1)
        if key in ("icon_state", "use_power"):
            continue
        new_tags.append(tag_match.group(0).strip())
    if is_on:
        new_tags.append('engineering_mode = "FILTER"')
    else:
        new_tags.append('engineering_mode = "FILTER"')
        new_tags.append("use_power = 0")
    suffix = ""
    if new_tags:
        suffix = "{" + "; ".join(new_tags) + "}"
    path = "/obj/machinery/atmospherics/unary/vent_pump"
    if is_on:
        path += "/on"
    return path + suffix


def convert_file(path):
    with io.open(path, "r", encoding="utf-8", errors="surrogateescape", newline="") as handle:
        content = handle.read()
    if "vent_scrubber" not in content:
        return 0

    replacements = []
    for match in SCRUBBER_RE.finditer(content):
        replacements.append((match.start(), match.end(), convert_segment(match)))

    new_content = list(content)
    for start, end, replacement in reversed(replacements):
        new_content[start:end] = replacement
    new_content = "".join(new_content)

    if "vent_scrubber" in new_content:
        raise RuntimeError("%s still contains scrubber references after conversion" % path)

    with io.open(path, "w", encoding="utf-8", errors="surrogateescape", newline="") as handle:
        handle.write(new_content)
    return len(replacements)


def main():
    total = 0
    for rel in MAPS:
        path = os.path.join(ROOT, rel.replace("/", os.sep))
        if not os.path.isfile(path):
            print("%s: MISSING" % rel)
            sys.exit(1)
        count = convert_file(path)
        print("%s: %d scrubber(s) converted" % (rel, count))
        total += count
    print("Total conversions: %d" % total)
    if total == 0:
        sys.exit(1)


if __name__ == "__main__":
    main()