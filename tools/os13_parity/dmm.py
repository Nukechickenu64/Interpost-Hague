"""Read DMM cells without conflating case-sensitive BYOND map keys."""
from pathlib import Path
import re


def read_map(path):
    text = Path(path).read_text(encoding="utf-8")
    definitions = dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$', text, re.M | re.S))
    key_size = len(next(iter(definitions)))
    cells = {}
    for block in re.finditer(r'\((\d+),(\d+),(\d+)\)\s*=\s*\{"(.*?)"\}', text, re.S):
        x, y, z = map(int, block.group(1, 2, 3))
        rows = block[4].strip().splitlines()
        for row_index, row in enumerate(rows):
            if len(row) % key_size:
                raise ValueError("Incomplete DMM key")
            for column in range(0, len(row), key_size):
                position = x + column // key_size, y + len(rows) - row_index - 1, z
                if position in cells:
                    raise ValueError(f"Overlapping DMM blocks at {position}")
                cells[position] = definitions[row[column:column + key_size]]
    return text, definitions, cells
