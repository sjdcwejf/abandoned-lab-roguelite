from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "tiny_wizard" / "assets" / "art" / "greenhouse" / "rooms"

THIRD_PARTY_DIR = ROOT / "tiny_wizard" / "assets" / "third_party"


def first_existing(paths: list[Path]) -> Path:
    for path in paths:
        if path.exists():
            return path
    return paths[0]


VOID_FLOOR_PATH = first_existing([
    THIRD_PARTY_DIR / "void_lab_tileset" / "laboratory floor_ walls_ and borders tileset-4.png",
])
VOID_OBJECTS_PATH = first_existing([
    THIRD_PARTY_DIR / "void_lab_tileset" / "laboratory objects-1.png",
])
MARU_PATH = first_existing([
    THIRD_PARTY_DIR / "mars_greenhouse" / "tilesets.png",
])
LOP_STUFF_PATH = first_existing([
    THIRD_PARTY_DIR / "land_of_pixels_lab" / "32px" / "tilesStuff.png",
])
LOP_LIQUID_PATH = first_existing([
    THIRD_PARTY_DIR / "land_of_pixels_lab" / "32px" / "spriteSheet_tiledLiquids_32x32.png",
])

ROOM_SIZE = (1024, 600)
FLOOR_RECT = (64, 80, 960, 520)
TILE = 32


def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


VOID_FLOOR = load(VOID_FLOOR_PATH)
VOID_OBJECTS = load(VOID_OBJECTS_PATH)
MARU = load(MARU_PATH)
LOP_STUFF = load(LOP_STUFF_PATH)
LOP_LIQUID = load(LOP_LIQUID_PATH)


def crop(img: Image.Image, box: tuple[int, int, int, int], scale: int = 1) -> Image.Image:
    piece = img.crop(box).convert("RGBA")
    if scale != 1:
        piece = piece.resize((piece.width * scale, piece.height * scale), Image.Resampling.NEAREST)
    return piece


def trim(piece: Image.Image, padding: int = 0) -> Image.Image:
    alpha = piece.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return piece
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(piece.width, bbox[2] + padding)
    bottom = min(piece.height, bbox[3] + padding)
    return piece.crop((left, top, right, bottom))


def recolor(piece: Image.Image, brightness: float = 0.78, saturation: float = 0.58, alpha: float = 1.0) -> Image.Image:
    result = piece.convert("RGBA")
    rgb = Image.merge("RGB", result.split()[:3])
    rgb = ImageEnhance.Color(rgb).enhance(saturation)
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    result = Image.merge("RGBA", (*rgb.split(), result.getchannel("A")))
    if alpha < 1.0:
        a = result.getchannel("A").point(lambda v: int(v * alpha))
        result.putalpha(a)
    return result


def alpha_paste(base: Image.Image, piece: Image.Image, pos: tuple[int, int], anchor: str = "tl") -> None:
    x, y = pos
    if anchor == "center":
        x -= piece.width // 2
        y -= piece.height // 2
    base.alpha_composite(piece, (int(x), int(y)))


def tile_rect(base: Image.Image, tiles: list[Image.Image], rect: tuple[int, int, int, int], rng: random.Random) -> None:
    left, top, right, bottom = rect
    for y in range(top, bottom, TILE):
        for x in range(left, right, TILE):
            tile = rng.choice(tiles)
            base.alpha_composite(tile, (x, y))


def dark_tile(box: tuple[int, int, int, int], brightness: float = 0.42, saturation: float = 0.42) -> Image.Image:
    return recolor(crop(VOID_FLOOR, box), brightness=brightness, saturation=saturation)


FLOOR_TILES = [
    dark_tile((0, 32, 32, 64), 0.33, 0.36),
    dark_tile((32, 32, 64, 64), 0.31, 0.32),
    dark_tile((64, 32, 96, 64), 0.28, 0.28),
    dark_tile((96, 32, 128, 64), 0.30, 0.30),
]

WALL_TILE = recolor(crop(VOID_FLOOR, (0, 0, 64, 32)), brightness=0.38, saturation=0.32)
WALL_TILE_DARK = recolor(crop(VOID_FLOOR, (64, 0, 128, 32)), brightness=0.34, saturation=0.30)

MARU_TRAY = recolor(trim(crop(MARU, (16, 71, 48, 88), 2)), brightness=0.72, saturation=0.66)
MARU_PLANT_TRAY = recolor(trim(crop(MARU, (64, 72, 96, 88), 2)), brightness=0.68, saturation=0.72)
MARU_SMALL_PLANTS = [
    recolor(trim(crop(MARU, (16, 104, 32, 120), 2)), brightness=0.68, saturation=0.74),
    recolor(trim(crop(MARU, (48, 104, 64, 120), 2)), brightness=0.68, saturation=0.74),
    recolor(trim(crop(MARU, (80, 104, 96, 120), 2)), brightness=0.68, saturation=0.74),
    recolor(trim(crop(MARU, (16, 167, 32, 184), 2)), brightness=0.72, saturation=0.82),
]
MARU_GLASS_DOOR = recolor(trim(crop(MARU, (192, 24, 208, 56), 2)), brightness=0.70, saturation=0.48)
MARU_GREEN_TANK = recolor(trim(crop(MARU, (80, 22, 96, 49), 2)), brightness=0.72, saturation=0.62)
MARU_SCREEN = recolor(trim(crop(MARU, (48, 32, 64, 48), 2)), brightness=0.80, saturation=0.66)

VOID_TANK = recolor(trim(crop(VOID_OBJECTS, (197, 69, 219, 124)), 1), brightness=0.70, saturation=0.50)
VOID_BROKEN_PANEL = recolor(trim(crop(VOID_OBJECTS, (97, 132, 158, 157)), 1), brightness=0.58, saturation=0.35)
VOID_CONSOLE = recolor(trim(crop(VOID_OBJECTS, (131, 97, 157, 126)), 1), brightness=0.72, saturation=0.55)
VOID_TABLE = recolor(trim(crop(VOID_OBJECTS, (38, 4, 89, 30)), 1), brightness=0.58, saturation=0.30)

LOP_CONSOLE = recolor(trim(crop(LOP_STUFF, (740, 72, 798, 106))), brightness=0.54, saturation=0.45)
LOP_PIPE_STRIP = recolor(trim(crop(LOP_STUFF, (544, 144, 704, 180))), brightness=0.50, saturation=0.38)
LOP_WARNING = recolor(trim(crop(LOP_STUFF, (864, 32, 928, 64))), brightness=0.52, saturation=0.50, alpha=0.75)
LOP_GREEN_TUBE = recolor(trim(crop(LOP_STUFF, (986, 224, 1030, 336))), brightness=0.54, saturation=0.55)
LOP_WALL_SCREEN = recolor(trim(crop(LOP_STUFF, (480, 80, 736, 128))), brightness=0.42, saturation=0.35, alpha=0.82)
LOP_LIQUID = recolor(crop(LOP_LIQUID, (64, 0, 96, 32)), brightness=0.55, saturation=0.65, alpha=0.64)


def draw_room_shell(rng: random.Random) -> Image.Image:
    img = Image.new("RGBA", ROOM_SIZE, (5, 12, 14, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    tile_rect(img, FLOOR_TILES, FLOOR_RECT, rng)
    fx0, fy0, fx1, fy1 = FLOOR_RECT

    for x in range(0, ROOM_SIZE[0], 64):
        alpha_paste(img, WALL_TILE if x % 128 == 0 else WALL_TILE_DARK, (x, 0))
        alpha_paste(img, WALL_TILE_DARK if x % 128 == 0 else WALL_TILE, (x, 552))
    for y in range(32, ROOM_SIZE[1] - 32, 32):
        strip = WALL_TILE.resize((32, 32), Image.Resampling.NEAREST)
        alpha_paste(img, strip, (0, y))
        alpha_paste(img, strip.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (992, y))

    draw.rectangle((fx0 - 6, fy0 - 6, fx1 + 6, fy1 + 6), outline=(80, 104, 105, 255), width=4)
    draw.rectangle((fx0 - 2, fy0 - 2, fx1 + 2, fy1 + 2), outline=(24, 44, 46, 255), width=3)

    for x in range(fx0, fx1, TILE):
        if x % 96 == 0:
            draw.line((x, fy0, x, fy1), fill=(48, 62, 62, 72), width=1)
    for y in range(fy0, fy1, TILE):
        if y % 96 == 0:
            draw.line((fx0, y, fx1, y), fill=(48, 62, 62, 70), width=1)

    for _ in range(42):
        x = rng.randrange(fx0 + 18, fx1 - 18)
        y = rng.randrange(fy0 + 18, fy1 - 18)
        col = rng.choice([(64, 79, 77, 86), (92, 105, 100, 54), (44, 51, 50, 80), (97, 64, 32, 66)])
        if rng.random() < 0.55:
            draw.line((x, y, x + rng.randrange(-18, 20), y + rng.randrange(-10, 12)), fill=col, width=1)
        else:
            draw.rectangle((x, y, x + rng.randrange(2, 6), y + rng.randrange(1, 4)), fill=col)

    draw_door(img, "up")
    draw_door(img, "down")
    draw_door(img, "left")
    draw_door(img, "right")
    return img


def draw_door(img: Image.Image, direction: str) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    cx = ROOM_SIZE[0] // 2
    cy = ROOM_SIZE[1] // 2
    if direction == "up":
        rect = (cx - 84, 8, cx + 84, 86)
        open_rect = (cx - 54, 52, cx + 54, 86)
    elif direction == "down":
        rect = (cx - 84, 514, cx + 84, 592)
        open_rect = (cx - 54, 514, cx + 54, 548)
    elif direction == "left":
        rect = (8, cy - 72, 84, cy + 72)
        open_rect = (56, cy - 42, 84, cy + 42)
    else:
        rect = (940, cy - 72, 1016, cy + 72)
        open_rect = (940, cy - 42, 968, cy + 42)

    draw.rounded_rectangle(rect, radius=4, fill=(22, 31, 32, 255), outline=(91, 113, 112, 255), width=3)
    draw.rectangle(open_rect, fill=(17, 11, 7, 255), outline=(143, 90, 32, 255), width=2)
    if direction in ["up", "down"]:
        for x in (rect[0] + 18, rect[2] - 42):
            alpha_paste(img, LOP_WARNING.resize((48, 18), Image.Resampling.NEAREST), (x, rect[3] - 22 if direction == "up" else rect[1] + 4))
        alpha_paste(img, MARU_GLASS_DOOR, (cx - 16, rect[1] + 12))
    else:
        alpha_paste(img, MARU_GLASS_DOOR.rotate(90, expand=True), (rect[0] + 12, cy - 16))


def stain(img: Image.Image, center: tuple[int, int], radius: int, rng: random.Random, heavy: bool = False) -> None:
    layer = Image.new("RGBA", ROOM_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    cx, cy = center
    count = 16 if heavy else 8
    for _ in range(count):
        rx = radius + rng.randrange(-radius // 3, radius // 2)
        ry = max(8, radius // 3 + rng.randrange(-10, 16))
        x = cx + rng.randrange(-radius, radius)
        y = cy + rng.randrange(-radius // 2, radius // 2)
        draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(53, 120, 54, 22 if not heavy else 36))
    layer = layer.filter(ImageFilter.GaussianBlur(1.2))
    img.alpha_composite(layer)


def vines(img: Image.Image, start: tuple[int, int], length: int, rng: random.Random, direction: int = 1) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    x, y = start
    points = [(x, y)]
    for i in range(1, length):
        points.append((x + direction * i * 10, y + int(math.sin(i * 0.9) * 8) + rng.randrange(-4, 5)))
    draw.line(points, fill=(40, 83, 45, 170), width=3)
    draw.line(points, fill=(75, 124, 61, 82), width=1)
    for px, py in points[::3]:
        if rng.random() < 0.75:
            plant = rng.choice(MARU_SMALL_PLANTS)
            alpha_paste(img, plant, (px - plant.width // 2, py - plant.height // 2))


def paste_equipment(img: Image.Image, piece: Image.Image, pos: tuple[int, int], flip: bool = False, angle: int = 0) -> None:
    sprite = piece.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else piece
    if angle:
        sprite = sprite.rotate(angle, expand=True, resample=Image.Resampling.NEAREST)
    alpha_paste(img, sprite, pos, anchor="center")


def draw_culture_bay(img: Image.Image, center: tuple[int, int], rng: random.Random, mirror: bool = False, broken: bool = False) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    cx, cy = center
    w, h = 134, 196
    draw.rounded_rectangle((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2), radius=6, fill=(16, 28, 28, 230), outline=(67, 91, 88, 255), width=4)
    draw.rounded_rectangle((cx - w // 2 + 12, cy - h // 2 + 16, cx + w // 2 - 12, cy + h // 2 - 18), radius=4, fill=(23, 48, 43, 190), outline=(84, 132, 117, 210), width=2)
    for offset in [-58, -14, 30]:
        tray = MARU_PLANT_TRAY if rng.random() < 0.55 else MARU_TRAY
        if mirror:
            tray = tray.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        alpha_paste(img, tray.resize((96, 42), Image.Resampling.NEAREST), (cx - 48, cy + offset))
    for _ in range(6):
        px = cx + rng.randrange(-42, 44)
        py = cy + rng.randrange(-70, 72)
        alpha_paste(img, rng.choice(MARU_SMALL_PLANTS), (px, py), anchor="center")
    if broken:
        draw.line((cx - 46, cy - 58, cx + 34, cy + 62), fill=(166, 201, 186, 120), width=2)
        draw.line((cx - 18, cy + 58, cx + 48, cy - 42), fill=(166, 201, 186, 100), width=1)
        stain(img, (cx + rng.randrange(-20, 20), cy + 70), 40, rng, True)


def draw_floor_liquid_tiles(img: Image.Image, rect: tuple[int, int, int, int], rng: random.Random) -> None:
    left, top, right, bottom = rect
    for y in range(top, bottom, TILE):
        for x in range(left, right, TILE):
            tile = LOP_LIQUID.copy()
            if rng.random() < 0.5:
                tile = tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            alpha_paste(img, tile, (x, y))


def greenhouse_entry_room() -> Image.Image:
    rng = random.Random(2101)
    img = draw_room_shell(rng)
    draw_culture_bay(img, (184, 306), rng, False, False)
    draw_culture_bay(img, (840, 326), rng, True, True)
    paste_equipment(img, VOID_CONSOLE.resize((54, 60), Image.Resampling.NEAREST), (300, 190))
    paste_equipment(img, MARU_SCREEN, (330, 170))
    paste_equipment(img, LOP_PIPE_STRIP.resize((170, 38), Image.Resampling.NEAREST), (512, 116))
    paste_equipment(img, VOID_BROKEN_PANEL, (724, 444), flip=True)
    stain(img, (176, 428), 34, rng)
    stain(img, (854, 438), 44, rng)
    vines(img, (92, 102), 12, rng, 1)
    vines(img, (934, 142), 10, rng, -1)
    return img


def spore_contamination_room() -> Image.Image:
    rng = random.Random(2102)
    img = draw_room_shell(rng)
    draw_floor_liquid_tiles(img, (416, 360, 608, 424), rng)
    for pos in [(212, 220), (806, 218), (218, 438), (798, 426)]:
        draw_culture_bay(img, pos, rng, pos[0] > 512, rng.random() < 0.55)
    for pos in [(378, 230), (516, 306), (650, 412)]:
        stain(img, pos, 46, rng, True)
        for _ in range(4):
            alpha_paste(img, rng.choice(MARU_SMALL_PLANTS), (pos[0] + rng.randrange(-24, 24), pos[1] + rng.randrange(-18, 18)), anchor="center")
    paste_equipment(img, LOP_GREEN_TUBE, (520, 198))
    paste_equipment(img, VOID_TANK, (474, 458))
    vines(img, (120, 500), 14, rng, 1)
    vines(img, (922, 100), 14, rng, -1)
    return img


def cultivation_chamber_room() -> Image.Image:
    rng = random.Random(2103)
    img = draw_room_shell(rng)
    for x in [176, 304, 720, 846]:
        for y in [206, 334]:
            draw_culture_bay(img, (x, y), rng, x > 512, False)
    for x in [384, 448, 576, 640]:
        paste_equipment(img, MARU_GREEN_TANK, (x, 170))
        paste_equipment(img, MARU_GREEN_TANK, (x, 462), angle=180)
    paste_equipment(img, LOP_WALL_SCREEN.resize((230, 46), Image.Resampling.NEAREST), (512, 118))
    paste_equipment(img, LOP_PIPE_STRIP.resize((210, 44), Image.Resampling.NEAREST), (512, 494))
    stain(img, (214, 452), 30, rng)
    stain(img, (814, 150), 30, rng)
    vines(img, (98, 134), 15, rng, 1)
    vines(img, (924, 486), 15, rng, -1)
    return img


def greenhouse_reward_room() -> Image.Image:
    rng = random.Random(2104)
    img = draw_room_shell(rng)
    draw = ImageDraw.Draw(img, "RGBA")
    for pos in [(176, 176), (172, 430), (844, 184), (836, 422)]:
        draw_culture_bay(img, pos, rng, pos[0] > 512, rng.random() < 0.35)
    draw.rounded_rectangle((456, 238, 568, 342), radius=6, fill=(18, 27, 27, 230), outline=(118, 93, 45, 255), width=3)
    paste_equipment(img, VOID_TABLE.resize((78, 42), Image.Resampling.NEAREST), (512, 282))
    paste_equipment(img, LOP_CONSOLE, (610, 234))
    paste_equipment(img, VOID_CONSOLE.resize((44, 50), Image.Resampling.NEAREST), (412, 334))
    for pos in [(352, 184), (682, 420), (704, 176)]:
        alpha_paste(img, MARU_PLANT_TRAY.resize((96, 42), Image.Resampling.NEAREST), (pos[0] - 48, pos[1] - 18))
    stain(img, (180, 490), 28, rng)
    stain(img, (822, 104), 28, rng)
    vines(img, (130, 112), 12, rng, 1)
    vines(img, (914, 510), 12, rng, -1)
    return img


def greenhouse_boss_antechamber() -> Image.Image:
    rng = random.Random(2105)
    img = draw_room_shell(rng)
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((356, 152, 668, 226), radius=5, fill=(16, 23, 24, 232), outline=(82, 101, 98, 255), width=3)
    paste_equipment(img, LOP_CONSOLE.resize((86, 50), Image.Resampling.NEAREST), (512, 188))
    paste_equipment(img, MARU_SCREEN, (626, 188))
    for pos in [(166, 210), (858, 212), (184, 426), (840, 418)]:
        draw_culture_bay(img, pos, rng, pos[0] > 512, True)
    for x in [336, 368, 656, 688]:
        paste_equipment(img, LOP_GREEN_TUBE.resize((44, 108), Image.Resampling.NEAREST), (x, 374))
    draw.rounded_rectangle((438, 276, 586, 338), radius=4, fill=(15, 24, 24, 212), outline=(54, 86, 77, 190), width=2)
    alpha_paste(img, MARU_PLANT_TRAY.resize((96, 42), Image.Resampling.NEAREST), (464, 286))
    stain(img, (512, 380), 36, rng, False)
    vines(img, (92, 92), 18, rng, 1)
    vines(img, (928, 108), 18, rng, -1)
    vines(img, (102, 506), 13, rng, 1)
    vines(img, (914, 500), 13, rng, -1)
    return img


def greenhouse_weapon_cache_room() -> Image.Image:
    rng = random.Random(2106)
    img = draw_room_shell(rng)
    draw = ImageDraw.Draw(img, "RGBA")

    # Keep the center clear: the weapon pickup lands at roughly (512, 322).
    draw.rounded_rectangle((360, 136, 664, 208), radius=5, fill=(15, 24, 24, 235), outline=(83, 104, 101, 255), width=3)
    paste_equipment(img, LOP_CONSOLE.resize((92, 52), Image.Resampling.NEAREST), (512, 172))
    paste_equipment(img, MARU_SCREEN, (620, 172))
    alpha_paste(img, LOP_PIPE_STRIP.resize((248, 38), Image.Resampling.NEAREST), (388, 216))

    for pos in [(166, 254), (858, 250), (170, 436), (846, 434)]:
        draw_culture_bay(img, pos, rng, pos[0] > 512, rng.random() < 0.45)

    for pos in [(384, 398), (640, 398)]:
        draw.rounded_rectangle((pos[0] - 54, pos[1] - 22, pos[0] + 54, pos[1] + 22), radius=4, fill=(22, 32, 30, 220), outline=(80, 111, 92, 180), width=2)
        alpha_paste(img, MARU_PLANT_TRAY.resize((92, 38), Image.Resampling.NEAREST), (pos[0] - 46, pos[1] - 17))

    draw.rounded_rectangle((438, 278, 586, 352), radius=5, fill=(14, 22, 22, 190), outline=(120, 91, 41, 210), width=2)
    draw.line((456, 324, 568, 324), fill=(52, 196, 178, 120), width=3)
    draw.line((464, 334, 560, 334), fill=(172, 117, 46, 150), width=2)
    stain(img, (176, 510), 32, rng)
    stain(img, (850, 102), 30, rng)
    vines(img, (100, 116), 12, rng, 1)
    vines(img, (922, 488), 12, rng, -1)
    return img


def greenhouse_boss_nursery_room() -> Image.Image:
    rng = random.Random(2107)
    img = draw_room_shell(rng)
    draw = ImageDraw.Draw(img, "RGBA")

    # Boss arena: strong greenhouse identity at the edges, open combat space in the center.
    draw.rounded_rectangle((336, 118, 688, 196), radius=6, fill=(12, 24, 23, 238), outline=(76, 101, 96, 255), width=3)
    paste_equipment(img, LOP_WALL_SCREEN.resize((250, 46), Image.Resampling.NEAREST), (512, 154))
    paste_equipment(img, LOP_CONSOLE.resize((78, 48), Image.Resampling.NEAREST), (650, 156))

    for pos in [(172, 180), (852, 182), (164, 438), (860, 436)]:
        draw_culture_bay(img, pos, rng, pos[0] > 512, True)

    for pos in [(328, 250), (696, 250), (326, 438), (698, 438)]:
        paste_equipment(img, LOP_GREEN_TUBE.resize((44, 104), Image.Resampling.NEAREST), pos)

    # Faint containment floor ring, visual only; the boss still owns the center.
    layer = Image.new("RGBA", ROOM_SIZE, (0, 0, 0, 0))
    ring = ImageDraw.Draw(layer, "RGBA")
    ring.ellipse((392, 220, 632, 460), outline=(65, 128, 99, 80), width=5)
    ring.ellipse((432, 260, 592, 420), outline=(45, 88, 77, 56), width=2)
    for angle in range(0, 360, 45):
        px = 512 + math.cos(math.radians(angle)) * 120
        py = 340 + math.sin(math.radians(angle)) * 120
        ring.rectangle((px - 6, py - 6, px + 6, py + 6), fill=(70, 155, 113, 72))
    layer = layer.filter(ImageFilter.GaussianBlur(0.5))
    img.alpha_composite(layer)

    stain(img, (512, 438), 46, rng, True)
    stain(img, (210, 90), 30, rng)
    stain(img, (814, 510), 30, rng)
    vines(img, (88, 96), 18, rng, 1)
    vines(img, (936, 96), 18, rng, -1)
    vines(img, (116, 514), 13, rng, 1)
    vines(img, (906, 510), 13, rng, -1)
    return img


ROOM_BUILDERS = {
    "greenhouse_entry_room.png": greenhouse_entry_room,
    "spore_contamination_room.png": spore_contamination_room,
    "cultivation_chamber_room.png": cultivation_chamber_room,
    "greenhouse_reward_room.png": greenhouse_reward_room,
    "greenhouse_boss_antechamber.png": greenhouse_boss_antechamber,
    "greenhouse_weapon_cache_room.png": greenhouse_weapon_cache_room,
    "greenhouse_boss_nursery_room.png": greenhouse_boss_nursery_room,
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for filename, builder in ROOM_BUILDERS.items():
        out_path = OUT_DIR / filename
        builder().save(out_path)
        print(out_path.relative_to(ROOT))


if __name__ == "__main__":
    main()
