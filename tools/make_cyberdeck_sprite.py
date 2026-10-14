#!/usr/bin/env python3
"""Generate cyberdeck helmet sprites:
- item sprite 32x32 -> icons/obj/clothing/hats.dmi state 'cyberdeck'
- worn sprite 32x128 (S,N,E,W) -> icons/mob/onmob/head.dmi state 'cyberdeck'
- lefthand / righthand 32x32 -> onmob item hand dmis

Run: python tools/make_cyberdeck_sprite.py
"""
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

PAL = {
    ".": (0, 0, 0, 0),
    "O": (24, 24, 28, 255),        # outline
    "D": (44, 44, 52, 255),        # shell dark
    "M": (72, 72, 84, 255),        # shell mid
    "L": (112, 112, 128, 255),     # shell light
    "H": (144, 255, 255, 255),     # visor highlight
    "C": (0, 206, 209, 255),       # visor
    "c": (0, 140, 145, 255),       # visor dark
    "A": (70, 130, 200, 255),      # accent blue
}

def new_cell():
    img = Image.new("RGBA", (32, 32), PAL["."])
    return img

def put(px, x, y, c):
    if 0 <= x < 32 and 0 <= y < 32:
        px[x, y] = PAL[c]

def rect(px, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(px, x, y, c)

def rrect(px, x0, y0, x1, y1, c, r=1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            dx = max(x0 + r - 1 - x, x - (x1 - r + 1), 0)
            dy = max(y0 + r - 1 - y, y - (y1 - r + 1), 0)
            if dx * dx + dy * dy <= r * r:
                put(px, x, y, c)

def ellipse(px, cx, cy, rx, ry, c):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                put(px, x, y, c)

def mirror_x(px, src):
    for y in range(32):
        for x in range(32):
            src_px = src.load()
            src_img_copy = src.copy().load()
            px[31 - x, y] = src_img_copy[x, y]

def draw_front(px, antenna=True):
    """Forward-facing cyberdeck helmet, ~12x12 px centered on x=15.5."""
    rect(px, 10, 7, 21, 14, "O")          # body outline
    ellipse(px, 15.5, 7.5, 6.2, 5.2, "O") # dome outline
    ellipse(px, 15.5, 7.5, 5.2, 4.1, "M") # dome shell
    rect(px, 11, 8, 20, 13, "M")          # body shell
    ell = [(x, y) for y in range(32) for x in range(32)]
    # Antenna
    if antenna:
        rect(px, 15, 2, 16, 5, "O")
        rect(px, 15, 2, 16, 4, "D")
        px[15, 1] = PAL["L"]
        px[16, 1] = PAL["L"]
    # visor frame + glass
    rrect(px, 12, 7, 19, 12, "O", r=1)
    rect(px, 13, 8, 18, 11, "C")
    rect(px, 13, 8, 18, 8, "H")
    rect(px, 14, 10, 17, 10, "c")
    # chin plate
    rect(px, 13, 12, 18, 12, "D")
    # side technical nodes
    rect(px, 11, 9, 11, 10, "A")
    rect(px, 20, 9, 20, 10, "A")
    rect(px, 10, 13, 10, 13, "D")
    rect(px, 21, 13, 21, 13, "D")

def draw_back(px):
    """Rear of the helmet: ports and vents, no visor."""
    rect(px, 10, 7, 21, 14, "O")
    ellipse(px, 15.5, 7.5, 6.2, 5.2, "O")
    ellipse(px, 15.5, 7.5, 5.2, 4.1, "M")
    rect(px, 11, 8, 20, 13, "M")
    rect(px, 11, 9, 20, 10, "D")  # vent grille
    rect(px, 12, 9, 12, 9, "M")
    rect(px, 15, 9, 15, 9, "M")
    rect(px, 18, 9, 18, 9, "M")
    rect(px, 12, 11, 13, 12, "A")  # wire ports
    rect(px, 18, 11, 19, 12, "A")
    rect(px, 11, 13, 20, 13, "D")  # strap

def draw_side(px, facing_right=True):
    """Profile view. Visor band on the forward edge."""
    rect(px, 9, 7, 22, 13, "O")
    ellipse(px, 15.5, 7, 6.3, 4.9, "O")
    ellipse(px, 15.5, 7, 5.4, 4.0, "M")
    rect(px, 10, 8, 21, 12, "M")
    if facing_right:
        rrect(px, 18, 7, 22, 12, "O", r=1)
        rect(px, 19, 8, 21, 11, "C")
        rect(px, 19, 8, 21, 8, "H")
        rect(px, 20, 10, 21, 10, "c")
        rect(px, 9, 9, 10, 10, "A")   # rear node
    else:
        rrect(px, 9, 7, 13, 12, "O", r=1)
        rect(px, 10, 8, 12, 11, "C")
        rect(px, 10, 8, 12, 8, "H")
        rect(px, 11, 10, 12, 10, "c")
        rect(px, 21, 9, 22, 10, "A")
    rect(px, 9, 13, 22, 13, "D")  # chin strap

CHARS = {v: k for k, v in PAL.items()}

def ascii_preview(img):
    px = img.load()
    lines = []
    for y in range(32):
        row = ""
        for x in range(32):
            row += CHARS.get(px[x, y], "?")
        lines.append(row.strip(".") or ".")
    return "\n".join(lines)

def build_worn():
    sheet = Image.new("RGBA", (32, 128))
    cells = {}
    for d, name in enumerate(("S", "N", "E", "W")):
        img = new_cell()
        px = img.load()
        if name == "S":
            draw_front(px)
        elif name == "N":
            draw_back(px)
        elif name == "E":
            draw_side(px, facing_right=True)
        else:
            draw_side(px, facing_right=False)
        sheet.paste(img, (0, 32 * d))
        cells[name] = img
    return sheet, cells

def shift(img, dy):
    out = new_cell()
    if dy >= 0:
        out.paste(img, (0, dy))
    else:
        out.paste(img, (0, 0))
        out = out.crop((0, -dy, 32, 32))
        canvas = new_cell()
        canvas.paste(out, (0, 0))
        out = canvas
    return out

def build_hand(offset_x):
    """Hand sprite cell: small front-view helmet held at the bottom of the hand."""
    img = new_cell()
    px = img.load()
    x0, y0 = 11 + offset_x, 19
    # small dome
    rect(px, x0, y0 + 6, x0 + 9, y0 + 7, "O")
    ellipse(px, x0 + 4.5, y0 + 1.5, 3.6, 2.6, "O")
    ellipse(px, x0 + 4.5, y0 + 1.5, 2.6, 1.6, "M")
    rect(px, x0 + 1, y0 + 2, x0 + 8, y0 + 5, "M")
    rect(px, x0 + 3, y0 + 2, x0 + 6, y0 + 4, "C")
    rect(px, x0 + 3, y0 + 2, x0 + 6, y0 + 2, "H")
    rect(px, x0 + 2, y0 + 6, x0 + 7, y0 + 6, "D")
    return img

def build_hand_sheet(offset_x):
    sheet = Image.new("RGBA", (32, 128))
    for d in range(4):
        sheet.paste(build_hand(offset_x), (0, 32 * d))
    return sheet

def main():
    os.chdir(ROOT)

    # Item sprite: front view, shifted down to centre vertically
    front = new_cell()
    draw_front(front.load())
    item = shift(front, 8)

    print("=== ITEM sprite preview ===")
    print(ascii_preview(item))
    item.save("tools/cyberdeck_item.png")

    # Worn sprite
    worn, cells = build_worn()
    for name, cell in cells.items():
        print("\n=== WORN %s preview ===" % name)
        print(ascii_preview(cell))
    worn.save("tools/cyberdeck_worn.png")

    # Hand sprites (4-dir sheets); item sits slightly off-centre toward the body
    lh = build_hand_sheet(-2)
    rh = build_hand_sheet(2)
    print("\n=== LEFTHAND preview (dir S) ===")
    print(ascii_preview(lh.crop((0, 0, 32, 32))))
    print("\n=== RIGHTHAND preview (dir S) ===")
    print(ascii_preview(rh.crop((0, 0, 32, 32))))
    lh.save("tools/cyberdeck_lefthand.png")
    rh.save("tools/cyberdeck_righthand.png")

    print("\nSaved item/worn/lefthand/righthand PNGs in tools/")

if __name__ == "__main__":
    main()