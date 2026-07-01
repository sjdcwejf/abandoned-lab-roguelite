from __future__ import annotations

import random
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tiny_wizard" / "assets" / "art" / "greenhouse"


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


class Canvas:
    def __init__(self, width: int, height: int, color: tuple[int, int, int, int] = (0, 0, 0, 0)) -> None:
        self.width = width
        self.height = height
        self.pixels = [color for _ in range(width * height)]

    def set(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y * self.width + x] = color

    def rect(self, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, color)

    def border(self, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int], thickness: int = 1) -> None:
        self.rect(x, y, w, thickness, color)
        self.rect(x, y + h - thickness, w, thickness, color)
        self.rect(x, y, thickness, h, color)
        self.rect(x + w - thickness, y, thickness, h, color)

    def line(self, x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
        dx = abs(x1 - x0)
        sx = 1 if x0 < x1 else -1
        dy = -abs(y1 - y0)
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.set(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def circle(self, cx: int, cy: int, r: int, color: tuple[int, int, int, int]) -> None:
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
                    self.set(x, y, color)

    def save_png(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        raw = bytearray()
        for y in range(self.height):
            raw.append(0)
            for x in range(self.width):
                raw.extend(self.pixels[y * self.width + x])
        png = bytearray(b"\x89PNG\r\n\x1a\n")
        png.extend(_chunk(b"IHDR", struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0)))
        png.extend(_chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        png.extend(_chunk(b"IEND", b""))
        path.write_bytes(png)


def _chunk(kind: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(kind)
    crc = zlib.crc32(data, crc)
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc & 0xFFFFFFFF)


def draw_floor_overlay() -> None:
    rng = random.Random(1129)
    c = Canvas(768, 384, rgba("#182226", 225))
    tile_a = rgba("#1d2a2e", 232)
    tile_b = rgba("#202f33", 232)
    seam = rgba("#2a3b40", 190)
    crack = rgba("#0d1517", 210)
    moss = rgba("#285e32", 190)
    glow = rgba("#54c55d", 115)
    rust = rgba("#875b28", 145)

    for y in range(0, c.height, 32):
        for x in range(0, c.width, 32):
            c.rect(x, y, 32, 32, tile_a if ((x // 32 + y // 32) % 2 == 0) else tile_b)
            c.border(x, y, 32, 32, seam, 1)

    for _ in range(70):
        x = rng.randrange(12, c.width - 12)
        y = rng.randrange(12, c.height - 12)
        c.line(x, y, x + rng.randrange(-28, 29), y + rng.randrange(-18, 19), crack)

    for base_x in (0, 38, c.width - 98, c.width - 44):
        for _ in range(75):
            x = base_x + rng.randrange(0, 96)
            y = rng.randrange(8, c.height - 8)
            c.rect(x, y, rng.randrange(2, 7), rng.randrange(2, 9), moss)
            if rng.random() < 0.34:
                c.rect(x + 1, y + 1, 1, 1, glow)

    for base_y in (0, c.height - 78):
        for _ in range(65):
            x = rng.randrange(4, c.width - 4)
            y = base_y + rng.randrange(0, 78)
            c.rect(x, y, rng.randrange(2, 8), rng.randrange(2, 6), moss)

    for _ in range(22):
        x = rng.randrange(120, c.width - 120)
        y = rng.randrange(64, c.height - 64)
        c.rect(x, y, rng.randrange(3, 14), 2, rust)

    c.save_png(OUT / "greenhouse_floor_overlay.png")


def draw_culture_pod(path: str, broken: bool = False) -> None:
    rng = random.Random(902 if not broken else 903)
    c = Canvas(72, 108)
    shadow = rgba("#071012", 150)
    frame_dark = rgba("#1b2429")
    frame_mid = rgba("#4e666b")
    frame_hi = rgba("#8fcbd0")
    glass = rgba("#183d3e", 210)
    fluid = rgba("#3baa48", 190)
    glow = rgba("#8cff70", 160)
    warning = rgba("#ca8a2d")

    c.rect(8, 96, 56, 8, shadow)
    c.rect(14, 12, 44, 82, frame_dark)
    c.border(14, 12, 44, 82, frame_mid, 3)
    c.rect(20, 20, 32, 60, glass)
    c.rect(23, 50, 26, 27, fluid)
    c.line(26, 28, 44, 24, frame_hi)
    c.line(25, 36, 48, 34, rgba("#63aeb0", 210))
    c.rect(18, 6, 36, 9, frame_dark)
    c.border(18, 6, 36, 9, frame_mid, 2)
    c.rect(20, 86, 32, 10, frame_dark)
    c.border(20, 86, 32, 10, warning, 2)
    for _ in range(18):
        c.rect(rng.randrange(24, 48), rng.randrange(42, 78), 2, 2, glow)
    for _ in range(8):
        x = rng.randrange(22, 49)
        y = rng.randrange(26, 76)
        c.line(x, y, x + rng.randrange(-8, 9), y + rng.randrange(-10, 11), rgba("#2d7034", 230))

    if broken:
        c.rect(18, 26, 36, 38, rgba("#121819", 170))
        c.line(18, 31, 52, 57, rgba("#c9ffff", 220))
        c.line(26, 21, 46, 75, rgba("#c9ffff", 210))
        c.rect(8, 78, 36, 12, fluid)
        for _ in range(18):
            c.rect(rng.randrange(2, 66), rng.randrange(75, 102), 2, 2, rgba("#b8ffff", 160))

    c.save_png(OUT / path)


def draw_vine_clump() -> None:
    rng = random.Random(388)
    c = Canvas(128, 64)
    c.rect(6, 40, 112, 12, rgba("#07120d", 150))
    for _ in range(22):
        x = rng.randrange(4, 124)
        y = rng.randrange(12, 52)
        c.line(x, y, x + rng.randrange(-26, 27), y + rng.randrange(-16, 17), rgba("#14331d"))
        c.circle(x, y, rng.randrange(2, 5), rgba("#316c35"))
        if rng.random() < 0.45:
            c.circle(x + 2, y - 1, 1, rgba("#8ee15f", 210))
    c.save_png(OUT / "vine_clump.png")


def draw_bio_liquid_pool() -> None:
    rng = random.Random(512)
    c = Canvas(160, 80)
    dark = rgba("#0b1c14", 125)
    pool = rgba("#2ba543", 155)
    rim = rgba("#8cff65", 145)
    c.rect(20, 36, 116, 22, dark)
    for x, y, w, h in [(28, 22, 86, 36), (58, 16, 74, 34), (82, 34, 52, 28), (18, 38, 56, 24)]:
        c.rect(x, y, w, h, pool)
        c.border(x, y, w, h, rim, 1)
    for _ in range(24):
        c.circle(rng.randrange(28, 134), rng.randrange(22, 58), rng.randrange(1, 3), rgba("#d1ff8a", 180))
    c.save_png(OUT / "bio_liquid_pool.png")


def draw_pipe_debris() -> None:
    c = Canvas(96, 48)
    metal = rgba("#34464b")
    dark = rgba("#151d20")
    blue = rgba("#57d6dd", 210)
    rust = rgba("#bf7a2f")
    c.rect(6, 20, 84, 12, dark)
    c.rect(10, 16, 52, 10, metal)
    c.rect(34, 26, 44, 10, metal)
    c.border(10, 16, 52, 10, rgba("#78969a"), 1)
    c.border(34, 26, 44, 10, rgba("#78969a"), 1)
    c.line(8, 8, 86, 40, rust)
    c.line(18, 38, 80, 8, blue)
    c.save_png(OUT / "pipe_debris.png")


def draw_wall_vines() -> None:
    rng = random.Random(991)
    c = Canvas(192, 96)
    for _ in range(36):
        x = rng.randrange(0, 192)
        y = rng.randrange(0, 96)
        c.line(x, y, x + rng.randrange(-18, 19), y + rng.randrange(12, 34), rgba("#15351d", 230))
        c.circle(x, y, rng.randrange(2, 5), rgba("#2f6331", 230))
    c.save_png(OUT / "wall_vines.png")


def draw_glass_shards() -> None:
    rng = random.Random(66)
    c = Canvas(96, 64)
    for _ in range(30):
        x = rng.randrange(6, 90)
        y = rng.randrange(8, 56)
        c.line(x, y, x + rng.randrange(-7, 8), y + rng.randrange(-5, 6), rgba("#9bd2d4", 170))
    c.save_png(OUT / "glass_shards.png")


def draw_entry_floor_overlay() -> None:
    rng = random.Random(2401)
    c = Canvas(768, 384)
    base_a = rgba("#1a262a", 232)
    base_b = rgba("#1f2d31", 232)
    seam = rgba("#31464b", 180)
    crack = rgba("#0c1315", 220)
    moss = rgba("#244f2e", 175)
    glow = rgba("#6fd66a", 120)
    cyan = rgba("#45bac4", 140)
    amber = rgba("#a86921", 180)

    for y in range(0, c.height, 32):
        for x in range(0, c.width, 32):
            c.rect(x, y, 32, 32, base_a if ((x // 32 + y // 32) % 2 == 0) else base_b)
            c.border(x, y, 32, 32, seam, 1)

    # Keep the main combat lane clean, then add only subtle quarantine lane markings.
    for x in range(252, 516, 32):
        c.rect(x, 68, 14, 2, cyan)
        c.rect(x + 12, 314, 14, 2, cyan)
    for y in range(122, 262, 32):
        c.rect(364, y, 2, 14, rgba("#345b60", 140))
        c.rect(402, y + 12, 2, 14, rgba("#345b60", 120))

    for _ in range(44):
        x = rng.randrange(20, c.width - 20)
        y = rng.randrange(22, c.height - 22)
        if 240 < x < 528 and 96 < y < 288 and rng.random() < 0.72:
            continue
        c.line(x, y, x + rng.randrange(-24, 25), y + rng.randrange(-18, 19), crack)

    # Keep spores as subdued stains. Distinct vine silhouettes are handled by
    # dedicated CC0-derived prop sprites, so the floor no longer reads as noise.
    for zone_x in (18, c.width - 92):
        for _ in range(18):
            x = zone_x + rng.randrange(0, 72)
            y = rng.randrange(34, c.height - 34)
            c.rect(x, y, rng.randrange(5, 13), rng.randrange(3, 8), moss)
            if rng.random() < 0.22:
                c.rect(x + 2, y + 1, 2, 1, glow)

    for zone_y in (16, c.height - 48):
        for _ in range(12):
            x = rng.randrange(48, c.width - 48)
            y = zone_y + rng.randrange(0, 36)
            c.rect(x, y, rng.randrange(4, 11), rng.randrange(2, 5), moss)

    for x in range(202, 284, 22):
        c.rect(x, 46, 14, 3, amber)
    for x in range(490, 572, 22):
        c.rect(x, 335, 14, 3, amber)

    c.save_png(OUT / "greenhouse_entry_floor_overlay.png")


def draw_entry_culture_bay() -> None:
    rng = random.Random(2402)
    c = Canvas(128, 224)
    shadow = rgba("#051011", 145)
    dark = rgba("#111d20")
    metal = rgba("#40565b")
    metal_hi = rgba("#7da2a4")
    glass = rgba("#17383a", 210)
    fluid = rgba("#2f8d42", 190)
    plant = rgba("#3a7d35", 230)
    glow = rgba("#9dff7c", 150)
    cyan = rgba("#51d1da", 210)
    amber = rgba("#c07a25", 230)

    c.rect(12, 204, 104, 10, shadow)
    c.rect(10, 16, 108, 186, dark)
    c.border(10, 16, 108, 186, metal, 4)
    c.rect(18, 26, 92, 6, metal_hi)
    c.rect(18, 188, 92, 6, metal_hi)

    for y in (40, 118):
        c.rect(24, y, 80, 58, rgba("#0b1718"))
        c.border(24, y, 80, 58, metal, 3)
        c.rect(30, y + 8, 68, 42, glass)
        c.rect(34, y + 28, 58, 18, fluid)
        for _ in range(18):
            x = rng.randrange(36, 94)
            yy = rng.randrange(y + 12, y + 48)
            c.circle(x, yy, rng.randrange(1, 4), plant)
            if rng.random() < 0.25:
                c.circle(x, yy, 1, glow)
        c.line(34, y + 14, 88, y + 10, rgba("#8ee6e4", 150))

    c.rect(4, 78, 14, 62, dark)
    c.border(4, 78, 14, 62, metal, 2)
    c.rect(110, 76, 14, 70, dark)
    c.border(110, 76, 14, 70, metal, 2)
    c.rect(50, 104, 28, 8, amber)
    c.rect(42, 108, 44, 3, rgba("#20170c"))
    c.rect(46, 164, 36, 6, cyan)

    for _ in range(12):
        x = rng.randrange(16, 112)
        y = rng.randrange(16, 204)
        c.line(x, y, x + rng.randrange(-10, 11), y + rng.randrange(-16, 17), rgba("#1f4c26", 230))

    c.save_png(OUT / "greenhouse_entry_culture_bay.png")


def draw_entry_console() -> None:
    c = Canvas(80, 72)
    c.rect(14, 54, 52, 8, rgba("#061011", 150))
    c.rect(22, 14, 36, 44, rgba("#152326"))
    c.border(22, 14, 36, 44, rgba("#4f6c70"), 3)
    c.rect(28, 20, 24, 16, rgba("#1d4245"))
    c.rect(31, 23, 18, 2, rgba("#73e2de"))
    c.rect(31, 29, 12, 2, rgba("#74b86e"))
    c.rect(26, 42, 28, 7, rgba("#2b383b"))
    c.rect(30, 44, 5, 3, rgba("#c07a25"))
    c.rect(39, 44, 5, 3, rgba("#4fc7d1"))
    c.rect(48, 44, 3, 3, rgba("#7ece5d"))
    c.save_png(OUT / "greenhouse_entry_console.png")


def main() -> None:
    draw_floor_overlay()
    draw_entry_floor_overlay()
    draw_entry_culture_bay()
    draw_entry_console()
    draw_culture_pod("culture_pod.png", False)
    draw_culture_pod("broken_culture_pod.png", True)
    draw_vine_clump()
    draw_bio_liquid_pool()
    draw_pipe_debris()
    draw_wall_vines()
    draw_glass_shards()


if __name__ == "__main__":
    main()
