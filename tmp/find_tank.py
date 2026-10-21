import re

data = open('maps/alpha/alpha.dmm', encoding='utf-8', errors='replace').read()

# DMM grid: header with map size, then a key dictionary, then grid rows.
# Find the tile key definition for asw (contains station_gas_tank).
idx = data.find('"asw" = ')
print('--- key definition ---')
print(data[idx:idx+400])

# Find every occurrence of "asw" in the grid section (after "END_OF_KEYS" or the key dict).
# DMM format: after the key dict block, coordinates start as (x,y,z) = "..."
grid_start = data.rfind('(1,1,')
tail = data[grid_start:]

# Parse grid: lines like (x,y,z) = "aaab..."
# Determine map dims from header.
header = data[:2000]
hdr_matches = re.search(r'\((\d+),(\d+),(\d+)\) = \{"', data)
print('first grid line:', data[data.find('(1,1,'):data.find('(1,1,')+80])

lines = re.findall(r'\((\d+),(\d+),(\d+)\) = \{"([^\"]*)\"\}', tail)
print('grid lines parsed:', len(lines))

found = []
for x, y, z, cells in lines:
    for i, ch in enumerate(cells):
        if ch == 'a':
            found.append((int(x), int(y), int(z), i, cells))
            break

print('occurrences of cell key "a":', len(found))
for f in found[:40]:
    print(f)

# Map dimensions estimate
import collections
maxx = max(int(l[0]) for l in lines)
maxy = max(int(l[1]) for l in lines)
print('max x,y:', maxx, maxy)