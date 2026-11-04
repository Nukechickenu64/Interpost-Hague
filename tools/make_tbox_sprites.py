#!/usr/bin/env python3
"""Generate icons/obj/tbox.dmi: T-box game console, CRT television,
controller and cartridge sprites.

States:
- tbox       : console, empty cartridge slot
- tbox_on    : console with cartridge inserted (lit LED + cart visible)
- tv_off     : CRT television, dark screen
- tv_static  : CRT television, animated static (3 frames)
- tv_on      : CRT television, glowing picture
- tbox_cart  : game cartridge item
- tbox_pad   : controller item

Run: python tools/make_tbox_sprites.py
"""
import os
import random

from PIL import Image, PngImagePlugin

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "icons", "obj", "tbox.dmi")

T = (0, 0, 0, 0)

# palette
OUTLINE = (20, 16, 14, 255)
WOOD_D = (62, 42, 26, 255)
WOOD_M = (92, 62, 38, 255)
WOOD_L = (122, 86, 52, 255)
BEZEL = (40, 38, 36, 255)
BEZEL_L = (66, 62, 58, 255)
SCREEN_OFF = (18, 22, 24, 255)
SCREEN_OFF_HL = (34, 42, 46, 255)
KNOB = (180, 170, 150, 255)
GREY_D = (48, 50, 56, 255)
GREY_M = (74, 78, 86, 255)
GREY_L = (104, 110, 120, 255)
LED_OFF = (60, 24, 24, 255)
LED_ON = (60, 220, 90, 255)
CART_BODY = (120, 124, 134, 255)
CART_DARK = (84, 88, 98, 255)
LABEL_BG = (255, 241, 232, 255)
LABEL_RED = (255, 0, 77, 255)
LABEL_BLUE = (41, 173, 255, 255)
PAD_BTN_A = (255, 0, 77, 255)
PAD_BTN_B = (41, 173, 255, 255)
DPAD = (30, 32, 36, 255)
GLOW_1 = (0, 110, 90, 255)
GLOW_2 = (0, 170, 140, 255)
GLOW_3 = (120, 240, 210, 255)

STATIC_COLS = [
    (40, 40, 44, 255), (90, 90, 96, 255), (150, 150, 158, 255),
    (210, 210, 216, 255), (60, 60, 66, 255),
]


def new_cell():
    return Image.new("RGBA", (32, 32), T)


def rect(px, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < 32 and 0 <= y < 32:
                px[x, y] = c


def outline_rect(px, x0, y0, x1, y1, c):
    for x in range(x0, x1 + 1):
        px[x, y0] = c
        px[x, y1] = c
    for y in range(y0, y1 + 1):
        px[x0, y] = c
        px[x1, y] = c


SCREEN = (6, 7, 21, 20)  # x0, y0, x1, y1 of the tube glass


def tv_base():
    img = new_cell()
    px = img.load()
    # feet
    rect(px, 4, 29, 7, 30, OUTLINE)
    rect(px, 24, 29, 27, 30, OUTLINE)
    # cabinet
    rect(px, 2, 3, 29, 28, WOOD_M)
    outline_rect(px, 2, 3, 29, 28, OUTLINE)
    rect(px, 3, 4, 28, 5, WOOD_L)
    rect(px, 3, 26, 28, 27, WOOD_D)
    # bezel around tube
    rect(px, 4, 5, 23, 22, BEZEL)
    outline_rect(px, 4, 5, 23, 22, OUTLINE)
    rect(px, 5, 6, 22, 6, BEZEL_L)
    # screen
    x0, y0, x1, y1 = SCREEN
    rect(px, x0, y0, x1, y1, SCREEN_OFF)
    # rounded tube corners
    for cx, cy in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        px[cx, cy] = BEZEL
    # control panel
    rect(px, 25, 6, 28, 22, WOOD_D)
    px[26, 8] = KNOB
    px[27, 8] = KNOB
    px[26, 12] = KNOB
    px[27, 12] = KNOB
    rect(px, 26, 16, 27, 16, GREY_L)
    rect(px, 26, 18, 27, 18, GREY_L)
    rect(px, 26, 20, 27, 20, GREY_L)
    # speaker grille
    rect(px, 5, 24, 22, 24, WOOD_D)
    rect(px, 5, 26, 22, 26, WOOD_D)
    return img


def tv_off():
    img = tv_base()
    px = img.load()
    x0, y0, _, _ = SCREEN
    # faint reflection
    rect(px, x0 + 2, y0 + 1, x0 + 5, y0 + 2, SCREEN_OFF_HL)
    px[x0 + 2, y0 + 3] = SCREEN_OFF_HL
    return img


def tv_static(seed):
    img = tv_base()
    px = img.load()
    rng = random.Random(seed)
    x0, y0, x1, y1 = SCREEN
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = rng.choice(STATIC_COLS)
    return img


def tv_on():
    img = tv_base()
    px = img.load()
    x0, y0, x1, y1 = SCREEN
    rect(px, x0, y0, x1, y1, GLOW_1)
    rect(px, x0 + 1, y0 + 1, x1 - 1, y1 - 1, GLOW_2)
    # simple "game" picture: ground, sprite blob, hud dots
    rect(px, x0 + 1, y1 - 2, x1 - 1, y1 - 1, GLOW_1)
    rect(px, x0 + 5, y1 - 5, x0 + 7, y1 - 3, GLOW_3)
    px[x0 + 6, y1 - 6] = GLOW_3
    rect(px, x0 + 10, y0 + 4, x0 + 12, y0 + 5, GLOW_3)
    px[x0 + 2, y0 + 1] = GLOW_3
    px[x0 + 4, y0 + 1] = GLOW_3
    px[x0 + 6, y0 + 1] = GLOW_3
    # scanline
    for x in range(x0 + 1, x1):
        if x % 2 == 0:
            px[x, y0 + 7] = GLOW_1
    return img


def console(with_cart):
    img = new_cell()
    px = img.load()
    # body
    rect(px, 5, 18, 26, 27, GREY_M)
    outline_rect(px, 5, 18, 26, 27, OUTLINE)
    rect(px, 6, 19, 25, 20, GREY_L)
    rect(px, 6, 26, 25, 26, GREY_D)
    # cartridge slot
    rect(px, 9, 21, 20, 23, GREY_D)
    outline_rect(px, 9, 21, 20, 23, OUTLINE)
    if with_cart:
        # cartridge sticking out of the slot
        rect(px, 11, 15, 18, 21, CART_BODY)
        outline_rect(px, 11, 15, 18, 21, OUTLINE)
        rect(px, 12, 16, 17, 18, LABEL_BG)
        rect(px, 12, 16, 17, 16, LABEL_RED)
    # LED
    px[23, 22] = LED_ON if with_cart else LED_OFF
    # controller ports
    rect(px, 7, 24, 8, 25, OUTLINE)
    rect(px, 10, 24, 11, 25, OUTLINE)
    # big T logo
    rect(px, 14, 24, 16, 24, GREY_L)
    px[15, 25] = GREY_L
    return img


def cartridge():
    img = new_cell()
    px = img.load()
    rect(px, 10, 9, 21, 23, CART_BODY)
    outline_rect(px, 10, 9, 21, 23, OUTLINE)
    rect(px, 11, 10, 20, 10, GREY_L)
    # grip notches
    rect(px, 11, 21, 20, 21, CART_DARK)
    rect(px, 11, 23, 20, 23, CART_DARK)
    # label
    rect(px, 12, 12, 19, 18, LABEL_BG)
    outline_rect(px, 12, 12, 19, 18, CART_DARK)
    rect(px, 13, 13, 18, 14, LABEL_RED)
    rect(px, 13, 16, 16, 17, LABEL_BLUE)
    return img


def controller():
    img = new_cell()
    px = img.load()
    # cable
    px[15, 8] = OUTLINE
    px[14, 9] = OUTLINE
    px[15, 10] = OUTLINE
    px[16, 11] = OUTLINE
    # body
    rect(px, 7, 12, 24, 21, GREY_M)
    outline_rect(px, 7, 12, 24, 21, OUTLINE)
    rect(px, 8, 13, 23, 13, GREY_L)
    rect(px, 8, 20, 23, 20, GREY_D)
    # d-pad
    rect(px, 10, 15, 12, 17, DPAD)
    rect(px, 11, 14, 11, 18, DPAD)
    # start/select
    rect(px, 15, 17, 16, 17, GREY_D)
    # buttons
    px[20, 17] = PAD_BTN_B
    px[21, 17] = PAD_BTN_B
    px[22, 15] = PAD_BTN_A
    px[23, 15] = PAD_BTN_A
    return img


def write_dmi(path, states):
    """states: list of (name, frames:list[Image], delay or None)"""
    tiles = []
    description = "# BEGIN DMI\nversion = 4.0\n\twidth = 32\n\theight = 32\n"
    for name, frames, delay in states:
        description += 'state = "%s"\n\tdirs = 1\n\tframes = %d\n' % (name, len(frames))
        if delay:
            description += "\tdelay = %s\n" % ",".join(str(d) for d in delay)
        tiles.extend(frames)
    description += "# END DMI\n"
    columns = max(1, int(len(tiles) ** 0.5))
    while columns * columns < len(tiles):
        columns += 1
    rows = (len(tiles) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * 32, rows * 32), T)
    for index, tile in enumerate(tiles):
        sheet.paste(tile, (index % columns * 32, index // columns * 32))
    info = PngImagePlugin.PngInfo()
    info.add_text("Description", description, zip=True)
    sheet.save(path, format="PNG", pnginfo=info)
    print("wrote %s (%d states, %d tiles)" % (path, len(states), len(tiles)))


def main():
    states = [
        ("tbox", [console(False)], None),
        ("tbox_on", [console(True)], None),
        ("tv_off", [tv_off()], None),
        ("tv_static", [tv_static(1), tv_static(2), tv_static(3)], [2, 2, 2]),
        ("tv_on", [tv_on()], None),
        ("tbox_cart", [cartridge()], None),
        ("tbox_pad", [controller()], None),
    ]
    write_dmi(OUT, states)


if __name__ == "__main__":
    main()
