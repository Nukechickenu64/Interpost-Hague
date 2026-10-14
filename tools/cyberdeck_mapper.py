import re

path = 'maps/alpha/alpha.dmm'
data = open(path, encoding='utf-8', errors='replace').read()

midx = data.find('(1,1,1) =')
header = data[:midx - 1]  # exclude leading newline
rest = data[midx:]

keys = {}
for m in re.finditer(r'"([A-Za-z0-9]+)" = \(', header):
    key = m.group(1)
    start = header.find('(', m.end() - 1)
    depth = 0
    i = start
    while i < len(header):
        if header[i] == '(':
            depth += 1
        elif header[i] == ')':
            depth -= 1
            if depth == 0:
                break
        i += 1
    keys[key] = header[m.end():i]

keylen = len(next(iter(keys)))
print('num keys', len(keys), 'keylen', keylen)

# z groups: find marker positions
groups = [(z, rest.find('(1,1,%d) =' % z)) for z in range(1, 7)]
block = {}
for pi, (z, pos) in enumerate(groups):
    if pos < 0:
        continue
    end = groups[pi + 1][1] if pi + 1 < len(groups) else len(rest)
    block[z] = rest[pos:end]

z1 = block.get(1, '')
print('z1 chunk len', len(z1))
# strip header '(1,1,1) = {"\n' and trailing '"\n}'
m = re.search(r'\{"(.*)"\}', z1, re.S)
if not m:
    print('no body matched')
else:
    content = m.group(1)
    grid = {}
    y = 1
    for row in content.split('\n'):
        row = row.strip()
        if not row:
            continue
        for xi in range(0, len(row), keylen):
            key = row[xi:xi+keylen]
            if key in keys:
                grid[(xi // keylen + 1, y)] = key
        y += 1

    ys = sorted(set(py for (px, py) in grid))
    xs = sorted(set(px for (px, py) in grid))
    print('grid tiles', len(grid), 'x', xs[0], '-', xs[-1], 'y', ys[0], '-', ys[-1])

    def find_in_grid(pat, limit=60):
        hits = []
        matching_keys = set(k for k in keys if pat in keys[k])
        print('matching keys for', pat, ':', list(matching_keys)[:12])
        for py in ys:
            for px in xs:
                key = grid.get((px, py))
                if key in matching_keys:
                    hits.append((px, py))
                    if len(hits) >= limit:
                        return hits
        return hits

    print('RD CONSOLES:', find_in_grid('rdconsole', 20))
    print('chairs darkpurpleos:', find_in_grid('chair/office/dark', 40))
    print('plain floors:', find_in_grid('/turf/simulated/floor/tiled/darkpurpleos,/area/rnd/research', 40))
    print('waterchip:', find_in_grid('waterchip', 10))