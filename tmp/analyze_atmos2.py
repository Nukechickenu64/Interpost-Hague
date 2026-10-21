import zlib, struct

PATH = r'icons/os13/objects/objects/machines/atmos2.dmi'

def parse_dmi_desc(data):
    pos = 8
    desc = None
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        ctype = data[pos+4:pos+8]
        cdata = data[pos+8:pos+8+length]
        if ctype in (b'iTXt', b'zTXt', b'tEXt'):
            if ctype == b'tEXt':
                key, _, val = cdata.partition(b'\x00')
                if key == b'Description':
                    desc = val.decode('latin1', 'replace')
            else:
                key, _, rest = cdata.partition(b'\x00')
                if ctype == b'zTXt':
                    rest = rest[1:]
                    val = zlib.decompress(rest)
                else:
                    parts = rest.split(b'\x00')
                    flag, real_val = parts[0], parts[1]
                    val = zlib.decompress(real_val) if flag == b'\x01' else real_val
                if key == b'Description':
                    desc = val.decode('latin1', 'replace')
        pos += 12 + length
    return desc

def parse_dmi_states(desc):
    lines = desc.split('\n')
    states = []
    i = 0
    while i < len(lines):
        if lines[i].strip().startswith('state = '):
            name = lines[i].split('state = ')[1].strip().strip('"')
            dirs = int(lines[i+1].split('=')[1])
            frames = int(lines[i+2].split('=')[1])
            states.append({'name': name, 'dirs': dirs, 'frames': frames})
            i += 1
        i += 1
    return states

def decode_sheet(data):
    # Returns (width, height, list of rows of RGBA tuples or None)
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos = 8
    width = height = None
    color_type = None
    idat = b''
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        ctype = data[pos+4:pos+8]
        cdata = data[pos+8:pos+8+length]
        if ctype == b'IHDR':
            width, height = struct.unpack('>II', cdata[:8])
            color_type = cdata[9]
        elif ctype == b'IDAT':
            idat += cdata
        pos += 12 + length
    raw = zlib.decompress(idat)
    channels = {0:1, 2:3, 3:1, 4:2, 6:4}[color_type]
    stride = width * channels
    scan = []
    prev = bytearray(stride)
    idx = 0
    for y in range(height):
        filt = raw[idx]; idx += 1
        line = bytearray(raw[idx:idx+stride]); idx += stride
        if filt == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i-channels]) & 0xFF
        elif filt == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif filt == 3:
            for i in range(stride):
                a = line[i-channels] if i >= channels else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xFF
        elif filt == 4:
            for i in range(stride):
                a = line[i-channels] if i >= channels else 0
                b = prev[i]
                c = prev[i-channels] if i >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        scan.append(bytes(line))
        prev = line
    px = []
    for y in range(height):
        row = []
        for x in range(width):
            idx = x * channels
            if color_type == 6:
                r, g, b, a = scan[y][idx], scan[y][idx+1], scan[y][idx+2], scan[y][idx+3]
                row.append((r, g, b, a) if a else None)
            elif color_type == 2:
                r, g, b = scan[y][idx], scan[y][idx+1], scan[y][idx+2]
                row.append((r, g, b, 255))
            else:
                raise Exception('unsupported color type %s' % color_type)
        px.append(row)
    return width, height, px

def edge_counts(px):
    h = len(px)
    w = len(px[0])
    def cnt(cells):
        return sum(1 for c in cells if c and c[3] > 8)
    return dict(
        top=cnt(px[0]), bottom=cnt(px[h-1]),
        left=cnt([px[y][0] for y in range(h)]),
        right=cnt([px[y][w-1] for y in range(h)]),
        total=sum(1 for y in range(h) for c in px[y] if c and c[3] > 8))

data = open(PATH, 'rb').read()
desc = parse_dmi_desc(data)
states = parse_dmi_states(desc)
print('declared states:', [s['name'] for s in states])
total_frames = sum(s['dirs'] * s['frames'] for s in states)
print('total frames declared:', total_frames)

sheet_w, sheet_h, px = decode_sheet(data)
print('sheet dims:', sheet_w, sheet_h)

# Frame dimensions: assume 32x32 cells
frame_w, frame_h = 32, 32
cols = sheet_w // frame_w
rows = sheet_h // frame_h
print('frame count from sheet:', cols * rows)

for i, s in enumerate(states):
    for f in range(s['dirs'] * s['frames']):
        frame_index = sum(prev['dirs'] * prev['frames'] for prev in states[:i]) + f
        fx = (frame_index % cols) * frame_w
        fy = (frame_index // cols) * frame_h
        frame_px = [px[y][fx:fx+frame_w] for y in range(fy, fy+frame_h)]
        prof = edge_counts(frame_px)
        print("%s[%d]: T=%d B=%d L=%d R=%d N=%d" % (s['name'], f, prof['top'], prof['bottom'], prof['left'], prof['right'], prof['total']))