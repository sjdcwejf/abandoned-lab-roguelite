#!/usr/bin/env python3
import os
import struct
import zlib


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROPS_DIR = os.path.join(ROOT, "tiny_wizard", "assets", "art", "props")


def rgba(hex_color, alpha=255):
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def blank(width, height):
    return [[(0, 0, 0, 0) for _x in range(width)] for _y in range(height)]


def blend(dst, src):
    sa = src[3] / 255.0
    da = dst[3] / 255.0
    out_a = sa + da * (1.0 - sa)
    if out_a <= 0.0:
        return (0, 0, 0, 0)
    out = []
    for i in range(3):
        out.append(int(round((src[i] * sa + dst[i] * da * (1.0 - sa)) / out_a)))
    out.append(int(round(out_a * 255)))
    return tuple(out)


def set_px(img, x, y, color):
    if 0 <= y < len(img) and 0 <= x < len(img[0]):
        img[y][x] = blend(img[y][x], color)


def rect(img, x0, y0, x1, y1, color):
    for y in range(max(0, y0), min(len(img), y1)):
        for x in range(max(0, x0), min(len(img[0]), x1)):
            set_px(img, x, y, color)


def ellipse(img, cx, cy, rx, ry, color):
    if rx <= 0 or ry <= 0:
        return
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            dx = (x - cx) / rx
            dy = (y - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                set_px(img, x, y, color)


def point_in_poly(px, py, points):
    inside = False
    j = len(points) - 1
    for i, point in enumerate(points):
        xi, yi = point
        xj, yj = points[j]
        crosses = (yi > py) != (yj > py)
        if crosses:
            x_at_y = (xj - xi) * (py - yi) / (yj - yi + 0.000001) + xi
            if px < x_at_y:
                inside = not inside
        j = i
    return inside


def poly(img, points, color):
    min_x = int(min(p[0] for p in points))
    max_x = int(max(p[0] for p in points)) + 1
    min_y = int(min(p[1] for p in points))
    max_y = int(max(p[1] for p in points)) + 1
    for y in range(min_y, max_y):
        for x in range(min_x, max_x):
            if point_in_poly(x + 0.5, y + 0.5, points):
                set_px(img, x, y, color)


def line(img, x0, y0, x1, y1, color, thickness=1):
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        radius = max(0, thickness // 2)
        rect(img, x0 - radius, y0 - radius, x0 + radius + 1, y0 + radius + 1, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def write_png(path, img):
    height = len(img)
    width = len(img[0])
    raw = bytearray()
    for row in img:
        raw.append(0)
        for px in row:
            raw.extend(px)

    def chunk(kind, data):
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(png)


def hazard_stripes(img, x0, y0, width, height, bright, dark):
    rect(img, x0, y0, x0 + width, y0 + height, dark)
    for offset in range(-height, width, 7):
        line(img, x0 + offset, y0 + height - 1, x0 + offset + height, y0, bright, 2)


def draw_supply_cache(width, height, palette, opened=False):
    img = blank(width, height)
    metal = palette["metal"]
    metal_dark = palette["dark"]
    edge = palette["edge"]
    accent = palette["accent"]
    glow = palette["glow"]

    ellipse(img, width / 2, height - 8, width * 0.38, 4, rgba("05070a", 95))

    if opened:
        poly(img, [(8, 16), (38, 10), (45, 19), (14, 25)], edge)
        poly(img, [(11, 17), (37, 13), (41, 18), (14, 22)], metal)
        rect(img, 12, 20, width - 8, 35, metal_dark)
        rect(img, 15, 22, width - 11, 31, rgba("061b1d", 235))
        rect(img, 17, 24, width - 13, 29, glow)
        rect(img, 8, 29, width - 9, 40, metal)
        rect(img, 10, 30, width - 11, 36, metal_dark)
        hazard_stripes(img, 12, 37, width - 24, 3, accent, rgba("11151a", 255))
    else:
        poly(img, [(8, 12), (width - 9, 12), (width - 5, 20), (4, 20)], edge)
        poly(img, [(10, 14), (width - 11, 14), (width - 8, 19), (7, 19)], metal)
        rect(img, 5, 19, width - 6, 35, metal_dark)
        rect(img, 8, 21, width - 9, 32, metal)
        rect(img, 11, 23, width - 12, 30, rgba("1d2b33", 235))
        hazard_stripes(img, 9, 32, width - 18, 3, accent, rgba("0f1317", 255))
        rect(img, width // 2 - 4, 22, width // 2 + 5, 30, rgba("071316", 255))
        rect(img, width // 2 - 2, 24, width // 2 + 3, 28, glow)

    line(img, 5, 19, 8, 35, rgba("06080b", 180), 1)
    line(img, width - 6, 19, width - 10, 35, rgba("06080b", 160), 1)
    rect(img, 8, 35, width - 9, 38, rgba("07090c", 150))
    return img


def draw_entropy_tile(img, x, y, destroyed=False):
    ox = x * 63
    oy = y * 63
    ellipse(img, ox + 31, oy + 42, 23, 9, rgba("020405", 110))
    base = rgba("20252a", 255) if not destroyed else rgba("15191d", 185)
    edge = rgba("495057", 255) if not destroyed else rgba("30363b", 180)
    resin = rgba("2b3b32", 255) if not destroyed else rgba("1d2c25", 170)
    poly(img, [(13 + ox, 18 + oy), (26 + ox, 7 + oy), (47 + ox, 13 + oy), (55 + ox, 29 + oy), (46 + ox, 45 + oy), (20 + ox, 48 + oy), (8 + ox, 34 + oy)], edge)
    poly(img, [(16 + ox, 20 + oy), (27 + ox, 11 + oy), (44 + ox, 16 + oy), (51 + ox, 29 + oy), (43 + ox, 40 + oy), (22 + ox, 43 + oy), (13 + ox, 33 + oy)], base)
    poly(img, [(20 + ox, 22 + oy), (31 + ox, 14 + oy), (42 + ox, 19 + oy), (47 + ox, 29 + oy), (38 + ox, 36 + oy), (24 + ox, 38 + oy), (16 + ox, 31 + oy)], resin)
    line(img, ox + 18, oy + 30, ox + 30, oy + 26, rgba("72ff9d", 180), 2)
    line(img, ox + 34, oy + 16, ox + 38, oy + 34, rgba("5ce88e", 150), 1)
    line(img, ox + 23, oy + 40, ox + 45, oy + 30, rgba("89ffc1", 100), 1)
    if not destroyed:
        hazard_stripes(img, ox + 13, oy + 45, 36, 4, rgba("e3a93e", 210), rgba("141416", 220))
    else:
        ellipse(img, ox + 35, oy + 39, 12, 5, rgba("4dff8a", 80))
        rect(img, ox + 15, oy + 43, ox + 48, oy + 47, rgba("101518", 120))


def draw_breach_tile(img, x, y):
    ox = x * 63
    oy = y * 63
    rect(img, ox, oy, ox + 63, oy + 63, rgba("000000", 0))
    rect(img, ox + 4, oy + 4, ox + 59, oy + 59, rgba("071012", 220))
    rect(img, ox + 7, oy + 7, ox + 56, oy + 56, rgba("130c13", 230))
    top = y == 0
    bottom = y == 3
    left = x == 0
    right = x == 3
    if top:
        hazard_stripes(img, ox + 6, oy + 4, 51, 5, rgba("d79c34", 210), rgba("101215", 230))
    if bottom:
        hazard_stripes(img, ox + 6, oy + 54, 51, 5, rgba("d79c34", 185), rgba("101215", 230))
    if left:
        rect(img, ox + 4, oy + 7, ox + 9, oy + 56, rgba("324047", 235))
    if right:
        rect(img, ox + 54, oy + 7, ox + 59, oy + 56, rgba("324047", 235))
    for i in range(3):
        px = ox + 14 + i * 13 + ((x + y) % 2) * 2
        line(img, px, oy + 20 + i * 6, px + 8, oy + 18 + i * 6, rgba("52e7b7", 70), 1)
    if x == 1 and y == 1:
        ellipse(img, ox + 32, oy + 33, 14, 7, rgba("51ff8c", 32))


def draw_tileset():
    img = blank(315, 252)
    for y in range(4):
        for x in range(4):
            draw_breach_tile(img, x, y)
    draw_entropy_tile(img, 4, 1, False)
    draw_entropy_tile(img, 4, 2, True)
    return img


def main():
    normal = {
        "metal": rgba("33414a", 255),
        "dark": rgba("151d24", 255),
        "edge": rgba("596873", 255),
        "accent": rgba("d79b2e", 255),
        "glow": rgba("6effd5", 210),
    }
    sample = {
        "metal": rgba("aab3bb", 255),
        "dark": rgba("3d464f", 255),
        "edge": rgba("dce2e7", 255),
        "accent": rgba("e5a63a", 255),
        "glow": rgba("8affb6", 230),
    }
    write_png(os.path.join(PROPS_DIR, "sealed_supply_cache_closed.png"), draw_supply_cache(48, 44, normal, False))
    write_png(os.path.join(PROPS_DIR, "sealed_supply_cache_open.png"), draw_supply_cache(52, 49, normal, True))
    write_png(os.path.join(PROPS_DIR, "sample_safe_closed.png"), draw_supply_cache(48, 44, sample, False))
    write_png(os.path.join(PROPS_DIR, "sample_safe_open.png"), draw_supply_cache(52, 49, sample, True))
    write_png(os.path.join(PROPS_DIR, "entropy_breach_tileset.png"), draw_tileset())


if __name__ == "__main__":
    main()
