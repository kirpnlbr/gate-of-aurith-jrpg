#!/usr/bin/env python3
"""Generate pixel art battle sprites for Gate of Aurith JRPG."""
from PIL import Image, ImageDraw
import os

SPRITE_DIR = os.path.join(os.path.dirname(__file__), "assets", "sprites", "battle")
os.makedirs(SPRITE_DIR, exist_ok=True)

# Palette
SKIN = (235, 200, 160)
SKIN_SHADOW = (200, 165, 130)
HAIR_BROWN = (90, 60, 40)
HAIR_DARK = (50, 35, 25)
EYE = (30, 30, 50)

# Mage colors
MAGE_ROBE = (70, 60, 160)
MAGE_ROBE_LIGHT = (100, 90, 200)
MAGE_ROBE_DARK = (45, 38, 110)
MAGE_HAT = (80, 65, 170)
MAGE_HAT_DARK = (55, 45, 130)
MAGE_STAFF = (120, 85, 50)
MAGE_STAFF_GEM = (100, 220, 255)
MAGE_STAFF_GLOW = (150, 240, 255)

# Gustave colors
GUST_ARMOR = (180, 50, 50)
GUST_ARMOR_LIGHT = (220, 80, 70)
GUST_ARMOR_DARK = (130, 35, 35)
GUST_METAL = (180, 185, 195)
GUST_METAL_DARK = (130, 135, 145)
GUST_SWORD = (200, 205, 215)
GUST_SWORD_EDGE = (230, 235, 245)
GUST_SHIELD = (160, 50, 45)
GUST_SHIELD_GOLD = (220, 180, 60)

# Sage colors
SAGE_ROBE = (50, 140, 70)
SAGE_ROBE_LIGHT = (70, 180, 90)
SAGE_ROBE_DARK = (35, 100, 50)
SAGE_BOOK = (140, 100, 60)
SAGE_BOOK_PAGE = (240, 230, 210)
SAGE_GLOW = (180, 255, 180)
SAGE_HAIR = (200, 180, 140)

# Enemy colors
GOB_SKIN = (90, 140, 70)
GOB_SKIN_DARK = (65, 110, 50)
GOB_EYES = (200, 200, 40)
GOB_CLOTH = (100, 80, 60)

WRAITH_BODY = (120, 70, 160)
WRAITH_LIGHT = (160, 100, 200)
WRAITH_DARK = (80, 40, 120)
WRAITH_EYES = (255, 80, 80)
WRAITH_GLOW = (180, 120, 220)

GOLEM_BODY = (140, 120, 95)
GOLEM_DARK = (100, 85, 65)
GOLEM_LIGHT = (170, 150, 125)
GOLEM_EYES = (200, 60, 30)
GOLEM_CRACK = (80, 65, 50)

BOSS_ARMOR = (40, 40, 55)
BOSS_ARMOR_LIGHT = (65, 65, 85)
BOSS_ARMOR_DARK = (25, 25, 35)
BOSS_VISOR = (180, 40, 40)
BOSS_CAPE = (60, 20, 25)
BOSS_CAPE_LIGHT = (90, 35, 40)
BOSS_SWORD = (160, 165, 180)
BOSS_SWORD_GLOW = (200, 80, 80)

T = None  # Transparent


def make_img(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(img, x, y, color):
    if color is None:
        return
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color + (255,) if len(color) == 3 else color)


def fill_rect(img, x, y, w, h, color):
    if color is None:
        return
    for dy in range(h):
        for dx in range(w):
            put(img, x + dx, y + dy, color)


def draw_pixels(img, ox, oy, data):
    """Draw pixel art from a list of (y_offset, list_of_(color, count) tuples)."""
    for row_y, row_data in data:
        x = ox
        for color, count in row_data:
            for i in range(count):
                put(img, x + i, oy + row_y, color)
            x += count


def scale_up(img, factor=3):
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def save(img, name, scale=3):
    scaled = scale_up(img, scale)
    path = os.path.join(SPRITE_DIR, name)
    scaled.save(path)
    print(f"  Saved {name} ({scaled.width}x{scaled.height})")


# ═══════════════════════════════════════════════════════════════════
# MAGE SPRITES
# ═══════════════════════════════════════════════════════════════════

def draw_mage_base(img, ox=0, oy=0):
    """Draw the mage - 20x28 pixels base."""
    # Hat top
    fill_rect(img, ox+7, oy+0, 4, 1, MAGE_HAT)
    fill_rect(img, ox+6, oy+1, 6, 1, MAGE_HAT)
    fill_rect(img, ox+7, oy+2, 5, 1, MAGE_HAT_DARK)
    # Hat brim
    fill_rect(img, ox+4, oy+3, 10, 1, MAGE_HAT)
    fill_rect(img, ox+3, oy+4, 12, 1, MAGE_HAT_DARK)
    # Face
    fill_rect(img, ox+6, oy+5, 6, 1, SKIN)
    fill_rect(img, ox+5, oy+6, 8, 1, SKIN)
    fill_rect(img, ox+5, oy+7, 8, 1, SKIN)
    # Eyes
    put(img, ox+7, oy+7, EYE)
    put(img, ox+10, oy+7, EYE)
    # Mouth area
    fill_rect(img, ox+6, oy+8, 6, 1, SKIN_SHADOW)
    # Robe top (shoulders)
    fill_rect(img, ox+4, oy+9, 10, 1, MAGE_ROBE)
    fill_rect(img, ox+3, oy+10, 12, 1, MAGE_ROBE)
    fill_rect(img, ox+3, oy+11, 12, 1, MAGE_ROBE_LIGHT)
    # Robe body
    fill_rect(img, ox+4, oy+12, 10, 1, MAGE_ROBE)
    fill_rect(img, ox+4, oy+13, 10, 1, MAGE_ROBE)
    fill_rect(img, ox+4, oy+14, 11, 1, MAGE_ROBE_DARK)
    fill_rect(img, ox+3, oy+15, 12, 1, MAGE_ROBE)
    fill_rect(img, ox+3, oy+16, 12, 1, MAGE_ROBE)
    fill_rect(img, ox+3, oy+17, 13, 1, MAGE_ROBE_LIGHT)
    fill_rect(img, ox+3, oy+18, 13, 1, MAGE_ROBE)
    # Robe bottom / skirt
    fill_rect(img, ox+2, oy+19, 14, 1, MAGE_ROBE_DARK)
    fill_rect(img, ox+2, oy+20, 14, 1, MAGE_ROBE)
    fill_rect(img, ox+3, oy+21, 12, 1, MAGE_ROBE)
    # Feet
    fill_rect(img, ox+4, oy+22, 4, 1, MAGE_ROBE_DARK)
    fill_rect(img, ox+10, oy+22, 4, 1, MAGE_ROBE_DARK)
    # Staff (left side)
    fill_rect(img, ox+1, oy+4, 2, 1, MAGE_STAFF_GEM)
    put(img, ox+1, oy+3, MAGE_STAFF_GLOW)
    put(img, ox+2, oy+3, MAGE_STAFF_GEM)
    fill_rect(img, ox+2, oy+5, 1, 18, MAGE_STAFF)


def make_mage_idle():
    img = make_img(20, 24)
    draw_mage_base(img, 0, 0)
    save(img, "mage_idle.png")


def make_mage_attack():
    """Mage casting - staff raised, magic particles."""
    img = make_img(28, 24)
    draw_mage_base(img, 4, 0)
    # Raised staff with glow
    fill_rect(img, 5, 2, 1, 14, MAGE_STAFF)
    put(img, 4, 0, MAGE_STAFF_GLOW)
    put(img, 5, 0, MAGE_STAFF_GEM)
    put(img, 6, 0, MAGE_STAFF_GLOW)
    put(img, 5, 1, MAGE_STAFF_GEM)
    # Magic particles on the right
    put(img, 22, 4, MAGE_STAFF_GEM)
    put(img, 24, 6, MAGE_STAFF_GLOW)
    put(img, 21, 8, MAGE_STAFF_GEM)
    put(img, 25, 5, MAGE_STAFF_GLOW)
    put(img, 23, 9, MAGE_STAFF_GEM)
    put(img, 26, 7, MAGE_STAFF_GLOW)
    # Fire element particles
    put(img, 22, 10, (255, 140, 40))
    put(img, 24, 8, (255, 180, 60))
    put(img, 23, 11, (255, 100, 30))
    save(img, "mage_attack.png")


def make_mage_skill():
    """Mage big spell - arms wide, large magic circle."""
    img = make_img(32, 28)
    draw_mage_base(img, 6, 2)
    # Magic circle effect around
    circle_color = (120, 200, 255)
    circle_dim = (70, 150, 220)
    for i, c in enumerate([circle_dim, circle_color, circle_dim]):
        put(img, 14+i, 0, c)
        put(img, 14+i, 27, c)
    for i, c in enumerate([circle_dim, circle_color, circle_dim]):
        put(img, 0, 12+i, c)
        put(img, 31, 12+i, c)
    # Corner sparkles
    for pos in [(3,3), (27,3), (3,24), (27,24)]:
        put(img, pos[0], pos[1], circle_color)
    # Raised arms (extend robe sides)
    fill_rect(img, 2, 11, 3, 2, MAGE_ROBE_LIGHT)
    fill_rect(img, 21, 11, 3, 2, MAGE_ROBE_LIGHT)
    # Hands glowing
    put(img, 1, 11, MAGE_STAFF_GLOW)
    put(img, 24, 11, MAGE_STAFF_GLOW)
    save(img, "mage_skill.png")


# ═══════════════════════════════════════════════════════════════════
# GUSTAVE SPRITES
# ═══════════════════════════════════════════════════════════════════

def draw_gustave_base(img, ox=0, oy=0):
    """Draw Gustave - 22x26 pixels, bulky knight."""
    # Hair / head top
    fill_rect(img, ox+7, oy+0, 6, 1, HAIR_BROWN)
    fill_rect(img, ox+6, oy+1, 8, 1, HAIR_BROWN)
    # Face
    fill_rect(img, ox+7, oy+2, 6, 1, SKIN)
    fill_rect(img, ox+6, oy+3, 8, 1, SKIN)
    fill_rect(img, ox+6, oy+4, 8, 1, SKIN)
    # Eyes + smirk
    put(img, ox+8, oy+3, EYE)
    put(img, ox+11, oy+3, EYE)
    put(img, ox+9, oy+4, SKIN_SHADOW)
    put(img, ox+10, oy+4, SKIN_SHADOW)
    # Chin
    fill_rect(img, ox+7, oy+5, 6, 1, SKIN_SHADOW)
    # Armor shoulders (wide)
    fill_rect(img, ox+2, oy+6, 16, 1, GUST_ARMOR)
    fill_rect(img, ox+1, oy+7, 18, 1, GUST_ARMOR)
    fill_rect(img, ox+1, oy+8, 18, 1, GUST_ARMOR_LIGHT)
    # Shoulder pads
    fill_rect(img, ox+1, oy+6, 4, 3, GUST_METAL)
    fill_rect(img, ox+15, oy+6, 4, 3, GUST_METAL)
    # Chest armor
    fill_rect(img, ox+3, oy+9, 14, 1, GUST_ARMOR)
    fill_rect(img, ox+3, oy+10, 14, 1, GUST_ARMOR_DARK)
    fill_rect(img, ox+4, oy+11, 12, 1, GUST_ARMOR)
    fill_rect(img, ox+4, oy+12, 12, 1, GUST_ARMOR_LIGHT)
    # Belt
    fill_rect(img, ox+4, oy+13, 12, 1, GUST_METAL_DARK)
    put(img, ox+9, oy+13, GUST_SHIELD_GOLD)
    put(img, ox+10, oy+13, GUST_SHIELD_GOLD)
    # Legs (armored)
    fill_rect(img, ox+4, oy+14, 5, 1, GUST_ARMOR)
    fill_rect(img, ox+11, oy+14, 5, 1, GUST_ARMOR)
    fill_rect(img, ox+4, oy+15, 5, 1, GUST_ARMOR_DARK)
    fill_rect(img, ox+11, oy+15, 5, 1, GUST_ARMOR_DARK)
    fill_rect(img, ox+4, oy+16, 5, 1, GUST_ARMOR)
    fill_rect(img, ox+11, oy+16, 5, 1, GUST_ARMOR)
    fill_rect(img, ox+5, oy+17, 4, 1, GUST_ARMOR_DARK)
    fill_rect(img, ox+11, oy+17, 4, 1, GUST_ARMOR_DARK)
    # Boots
    fill_rect(img, ox+4, oy+18, 5, 1, GUST_METAL_DARK)
    fill_rect(img, ox+11, oy+18, 5, 1, GUST_METAL_DARK)
    fill_rect(img, ox+4, oy+19, 5, 1, GUST_METAL)
    fill_rect(img, ox+11, oy+19, 5, 1, GUST_METAL)


def make_gustave_idle():
    """Gustave with greatsword resting on shoulder."""
    img = make_img(26, 22)
    draw_gustave_base(img, 3, 2)
    # Greatsword on right shoulder
    fill_rect(img, 20, 0, 2, 16, GUST_SWORD)
    put(img, 20, 0, GUST_SWORD_EDGE)
    put(img, 21, 0, GUST_SWORD_EDGE)
    fill_rect(img, 19, 16, 4, 1, GUST_METAL_DARK)  # guard
    fill_rect(img, 20, 17, 2, 3, GUST_ARMOR_DARK)  # grip
    save(img, "gustave_idle.png")


def make_gustave_attack():
    """Gustave swinging greatsword down."""
    img = make_img(32, 24)
    draw_gustave_base(img, 3, 2)
    # Sword swinging right - diagonal slash
    fill_rect(img, 22, 2, 2, 1, GUST_SWORD_EDGE)
    fill_rect(img, 23, 3, 2, 1, GUST_SWORD)
    fill_rect(img, 24, 4, 2, 1, GUST_SWORD)
    fill_rect(img, 25, 5, 2, 1, GUST_SWORD)
    fill_rect(img, 26, 6, 2, 1, GUST_SWORD)
    fill_rect(img, 27, 7, 2, 1, GUST_SWORD_EDGE)
    fill_rect(img, 28, 8, 2, 1, GUST_SWORD)
    fill_rect(img, 29, 9, 2, 1, GUST_SWORD)
    # Slash effect
    put(img, 30, 10, (255, 255, 200))
    put(img, 28, 11, (255, 255, 150))
    put(img, 26, 9, (255, 255, 200))
    # Extended arms
    fill_rect(img, 19, 8, 4, 2, SKIN)
    save(img, "gustave_attack.png")


def make_gustave_skill():
    """Gustave with shield raised, golden glow (Greatshield mode / taunt)."""
    img = make_img(28, 24)
    draw_gustave_base(img, 6, 2)
    # Large shield in front
    fill_rect(img, 0, 4, 6, 12, GUST_SHIELD)
    fill_rect(img, 1, 5, 4, 10, GUST_ARMOR)
    # Shield emblem
    put(img, 2, 8, GUST_SHIELD_GOLD)
    put(img, 3, 8, GUST_SHIELD_GOLD)
    put(img, 2, 9, GUST_SHIELD_GOLD)
    put(img, 3, 9, GUST_SHIELD_GOLD)
    # Golden glow around shield
    for y in range(3, 17):
        if y % 2 == 0:
            put(img, 0, y, GUST_SHIELD_GOLD)
    put(img, 1, 3, GUST_SHIELD_GOLD)
    put(img, 4, 3, GUST_SHIELD_GOLD)
    save(img, "gustave_skill.png")


# ═══════════════════════════════════════════════════════════════════
# SAGE SPRITES
# ═══════════════════════════════════════════════════════════════════

def draw_sage_base(img, ox=0, oy=0):
    """Draw Sage - 20x24, robed scholar."""
    # Hair
    fill_rect(img, ox+7, oy+0, 6, 1, SAGE_HAIR)
    fill_rect(img, ox+6, oy+1, 8, 1, SAGE_HAIR)
    # Glasses frames
    fill_rect(img, ox+6, oy+2, 8, 1, SKIN)
    fill_rect(img, ox+6, oy+3, 8, 1, SKIN)
    put(img, ox+7, oy+3, EYE)
    put(img, ox+8, oy+3, (120, 150, 200))  # glasses
    put(img, ox+10, oy+3, EYE)
    put(img, ox+11, oy+3, (120, 150, 200))  # glasses
    fill_rect(img, ox+6, oy+4, 8, 1, SKIN)
    fill_rect(img, ox+7, oy+5, 6, 1, SKIN_SHADOW)
    # Robe collar
    fill_rect(img, ox+5, oy+6, 10, 1, SAGE_ROBE_LIGHT)
    # Robe body
    fill_rect(img, ox+4, oy+7, 12, 1, SAGE_ROBE)
    fill_rect(img, ox+4, oy+8, 12, 1, SAGE_ROBE)
    fill_rect(img, ox+3, oy+9, 13, 1, SAGE_ROBE_LIGHT)
    fill_rect(img, ox+3, oy+10, 13, 1, SAGE_ROBE)
    fill_rect(img, ox+3, oy+11, 13, 1, SAGE_ROBE_DARK)
    fill_rect(img, ox+3, oy+12, 14, 1, SAGE_ROBE)
    fill_rect(img, ox+3, oy+13, 14, 1, SAGE_ROBE)
    fill_rect(img, ox+2, oy+14, 15, 1, SAGE_ROBE_LIGHT)
    fill_rect(img, ox+2, oy+15, 15, 1, SAGE_ROBE)
    fill_rect(img, ox+2, oy+16, 15, 1, SAGE_ROBE_DARK)
    fill_rect(img, ox+3, oy+17, 14, 1, SAGE_ROBE)
    # Feet
    fill_rect(img, ox+4, oy+18, 4, 1, SAGE_ROBE_DARK)
    fill_rect(img, ox+11, oy+18, 4, 1, SAGE_ROBE_DARK)
    # Book in left hand
    fill_rect(img, ox+0, oy+9, 3, 4, SAGE_BOOK)
    fill_rect(img, ox+1, oy+10, 2, 2, SAGE_BOOK_PAGE)


def make_sage_idle():
    img = make_img(20, 20)
    draw_sage_base(img, 0, 0)
    save(img, "sage_idle.png")


def make_sage_attack():
    """Sage summoning - book open, energy manifestation."""
    img = make_img(30, 24)
    draw_sage_base(img, 5, 2)
    # Open book, pages glowing
    fill_rect(img, 1, 11, 5, 5, SAGE_BOOK)
    fill_rect(img, 2, 12, 3, 3, SAGE_BOOK_PAGE)
    # Glow from book
    put(img, 2, 10, SAGE_GLOW)
    put(img, 4, 10, SAGE_GLOW)
    put(img, 3, 9, SAGE_GLOW)
    # Manifestation energy (right side)
    energy = (100, 255, 150)
    energy_dim = (60, 200, 100)
    # Phoenix-like shape
    put(img, 24, 4, energy)
    put(img, 23, 5, energy_dim)
    put(img, 25, 5, energy_dim)
    put(img, 22, 6, energy)
    put(img, 24, 6, energy)
    put(img, 26, 6, energy)
    put(img, 23, 7, energy_dim)
    put(img, 25, 7, energy_dim)
    put(img, 22, 8, energy)
    put(img, 26, 8, energy)
    put(img, 21, 9, energy_dim)
    put(img, 27, 9, energy_dim)
    save(img, "sage_attack.png")


def make_sage_skill():
    """Sage full manifestation - large energy creature above."""
    img = make_img(32, 28)
    draw_sage_base(img, 6, 8)
    # Large manifestation above sage
    g = (80, 255, 130)
    gd = (50, 200, 90)
    gb = (30, 150, 60)
    # Creature shape (phoenix/bird)
    fill_rect(img, 12, 0, 8, 1, gd)
    fill_rect(img, 10, 1, 12, 1, g)
    fill_rect(img, 9, 2, 14, 1, g)
    fill_rect(img, 8, 3, 16, 1, gd)
    fill_rect(img, 10, 4, 12, 1, gb)
    # Wings
    fill_rect(img, 4, 2, 4, 2, gd)
    fill_rect(img, 24, 2, 4, 2, gd)
    fill_rect(img, 2, 3, 3, 2, gb)
    fill_rect(img, 27, 3, 3, 2, gb)
    # Eyes of manifestation
    put(img, 13, 2, (255, 255, 200))
    put(img, 18, 2, (255, 255, 200))
    save(img, "sage_skill.png")


# ═══════════════════════════════════════════════════════════════════
# ENEMY SPRITES
# ═══════════════════════════════════════════════════════════════════

def make_goblin():
    img = make_img(16, 18)
    # Ears
    put(img, 2, 2, GOB_SKIN)
    put(img, 13, 2, GOB_SKIN)
    # Head
    fill_rect(img, 4, 1, 8, 1, GOB_SKIN)
    fill_rect(img, 3, 2, 10, 1, GOB_SKIN)
    fill_rect(img, 3, 3, 10, 1, GOB_SKIN)
    fill_rect(img, 4, 4, 8, 1, GOB_SKIN_DARK)
    # Eyes
    put(img, 5, 3, GOB_EYES)
    put(img, 9, 3, GOB_EYES)
    # Teeth
    put(img, 6, 4, (240, 240, 220))
    put(img, 8, 4, (240, 240, 220))
    # Body
    fill_rect(img, 4, 5, 8, 1, GOB_CLOTH)
    fill_rect(img, 3, 6, 10, 1, GOB_CLOTH)
    fill_rect(img, 3, 7, 10, 1, GOB_SKIN)
    fill_rect(img, 4, 8, 8, 1, GOB_CLOTH)
    fill_rect(img, 4, 9, 8, 1, GOB_CLOTH)
    fill_rect(img, 4, 10, 8, 1, GOB_SKIN_DARK)
    # Arms
    fill_rect(img, 1, 6, 2, 4, GOB_SKIN)
    fill_rect(img, 13, 6, 2, 4, GOB_SKIN)
    # Legs
    fill_rect(img, 4, 11, 3, 2, GOB_SKIN)
    fill_rect(img, 9, 11, 3, 2, GOB_SKIN)
    fill_rect(img, 5, 13, 2, 1, GOB_SKIN_DARK)
    fill_rect(img, 9, 13, 2, 1, GOB_SKIN_DARK)
    # Small dagger in right hand
    fill_rect(img, 14, 5, 1, 4, GUST_METAL)
    put(img, 14, 4, GUST_SWORD_EDGE)
    save(img, "goblin.png")


def make_wraith():
    img = make_img(18, 22)
    # Ghostly hood
    fill_rect(img, 5, 0, 8, 1, WRAITH_BODY)
    fill_rect(img, 4, 1, 10, 1, WRAITH_BODY)
    fill_rect(img, 3, 2, 12, 1, WRAITH_DARK)
    fill_rect(img, 3, 3, 12, 1, WRAITH_BODY)
    fill_rect(img, 3, 4, 12, 1, WRAITH_BODY)
    # Glowing eyes
    put(img, 6, 3, WRAITH_EYES)
    put(img, 7, 3, WRAITH_EYES)
    put(img, 10, 3, WRAITH_EYES)
    put(img, 11, 3, WRAITH_EYES)
    # Body (wispy)
    fill_rect(img, 4, 5, 10, 1, WRAITH_BODY)
    fill_rect(img, 3, 6, 12, 1, WRAITH_LIGHT)
    fill_rect(img, 3, 7, 12, 1, WRAITH_BODY)
    fill_rect(img, 2, 8, 14, 1, WRAITH_DARK)
    fill_rect(img, 2, 9, 14, 1, WRAITH_BODY)
    fill_rect(img, 3, 10, 12, 1, WRAITH_LIGHT)
    fill_rect(img, 3, 11, 12, 1, WRAITH_BODY)
    fill_rect(img, 2, 12, 14, 1, WRAITH_BODY)
    fill_rect(img, 3, 13, 12, 1, WRAITH_DARK)
    # Wispy tail (fades out)
    fill_rect(img, 4, 14, 10, 1, WRAITH_BODY)
    fill_rect(img, 5, 15, 8, 1, WRAITH_DARK)
    fill_rect(img, 6, 16, 6, 1, WRAITH_BODY)
    fill_rect(img, 7, 17, 4, 1, WRAITH_DARK)
    put(img, 8, 18, WRAITH_BODY)
    put(img, 9, 18, WRAITH_BODY)
    # Ghostly claws
    fill_rect(img, 0, 7, 2, 3, WRAITH_LIGHT)
    fill_rect(img, 16, 7, 2, 3, WRAITH_LIGHT)
    put(img, 0, 6, WRAITH_GLOW)
    put(img, 17, 6, WRAITH_GLOW)
    save(img, "wraith.png")


def make_golem():
    img = make_img(24, 26)
    # Head (blocky)
    fill_rect(img, 7, 0, 10, 2, GOLEM_LIGHT)
    fill_rect(img, 6, 2, 12, 3, GOLEM_BODY)
    fill_rect(img, 6, 5, 12, 1, GOLEM_DARK)
    # Eyes
    put(img, 9, 3, GOLEM_EYES)
    put(img, 10, 3, GOLEM_EYES)
    put(img, 13, 3, GOLEM_EYES)
    put(img, 14, 3, GOLEM_EYES)
    # Cracks on face
    put(img, 11, 2, GOLEM_CRACK)
    put(img, 12, 4, GOLEM_CRACK)
    # Massive body
    fill_rect(img, 3, 6, 18, 2, GOLEM_BODY)
    fill_rect(img, 2, 8, 20, 2, GOLEM_BODY)
    fill_rect(img, 2, 10, 20, 2, GOLEM_DARK)
    fill_rect(img, 3, 12, 18, 2, GOLEM_BODY)
    fill_rect(img, 3, 14, 18, 2, GOLEM_LIGHT)
    # Body cracks
    put(img, 10, 9, GOLEM_CRACK)
    put(img, 11, 10, GOLEM_CRACK)
    put(img, 15, 8, GOLEM_CRACK)
    put(img, 14, 11, GOLEM_CRACK)
    # Arms (massive)
    fill_rect(img, 0, 7, 3, 8, GOLEM_BODY)
    fill_rect(img, 21, 7, 3, 8, GOLEM_BODY)
    fill_rect(img, 0, 15, 3, 2, GOLEM_DARK)
    fill_rect(img, 21, 15, 3, 2, GOLEM_DARK)
    # Legs
    fill_rect(img, 4, 16, 7, 2, GOLEM_BODY)
    fill_rect(img, 13, 16, 7, 2, GOLEM_BODY)
    fill_rect(img, 4, 18, 7, 2, GOLEM_DARK)
    fill_rect(img, 13, 18, 7, 2, GOLEM_DARK)
    # Feet
    fill_rect(img, 3, 20, 8, 2, GOLEM_BODY)
    fill_rect(img, 13, 20, 8, 2, GOLEM_BODY)
    save(img, "golem.png")


def make_boss():
    """Dark Knight boss - larger, more detailed."""
    img = make_img(28, 30)
    # Helmet
    fill_rect(img, 9, 0, 10, 1, BOSS_ARMOR)
    fill_rect(img, 8, 1, 12, 1, BOSS_ARMOR)
    fill_rect(img, 7, 2, 14, 2, BOSS_ARMOR_LIGHT)
    fill_rect(img, 7, 4, 14, 1, BOSS_ARMOR)
    # Visor slit
    fill_rect(img, 10, 3, 3, 1, BOSS_VISOR)
    fill_rect(img, 15, 3, 3, 1, BOSS_VISOR)
    # Helmet point
    put(img, 13, 0, BOSS_ARMOR_LIGHT)
    put(img, 14, 0, BOSS_ARMOR_LIGHT)
    # Cape behind
    fill_rect(img, 5, 5, 3, 16, BOSS_CAPE)
    fill_rect(img, 20, 5, 3, 16, BOSS_CAPE)
    fill_rect(img, 4, 21, 4, 4, BOSS_CAPE_LIGHT)
    fill_rect(img, 20, 21, 4, 4, BOSS_CAPE_LIGHT)
    # Shoulders (large)
    fill_rect(img, 3, 5, 22, 1, BOSS_ARMOR)
    fill_rect(img, 2, 6, 24, 2, BOSS_ARMOR_LIGHT)
    # Shoulder spikes
    fill_rect(img, 2, 5, 3, 1, BOSS_ARMOR_LIGHT)
    fill_rect(img, 23, 5, 3, 1, BOSS_ARMOR_LIGHT)
    put(img, 1, 4, BOSS_ARMOR_LIGHT)
    put(img, 26, 4, BOSS_ARMOR_LIGHT)
    # Chest
    fill_rect(img, 6, 8, 16, 2, BOSS_ARMOR)
    fill_rect(img, 6, 10, 16, 2, BOSS_ARMOR_DARK)
    fill_rect(img, 7, 12, 14, 2, BOSS_ARMOR)
    fill_rect(img, 7, 14, 14, 1, BOSS_ARMOR_LIGHT)
    # Dark emblem on chest
    put(img, 13, 9, BOSS_VISOR)
    put(img, 14, 9, BOSS_VISOR)
    put(img, 13, 10, BOSS_VISOR)
    put(img, 14, 10, BOSS_VISOR)
    # Belt
    fill_rect(img, 7, 15, 14, 1, BOSS_ARMOR_DARK)
    # Legs
    fill_rect(img, 7, 16, 6, 3, BOSS_ARMOR)
    fill_rect(img, 15, 16, 6, 3, BOSS_ARMOR)
    fill_rect(img, 7, 19, 6, 2, BOSS_ARMOR_DARK)
    fill_rect(img, 15, 19, 6, 2, BOSS_ARMOR_DARK)
    # Boots
    fill_rect(img, 6, 21, 7, 2, BOSS_ARMOR)
    fill_rect(img, 15, 21, 7, 2, BOSS_ARMOR)
    # Sword (large, right side)
    fill_rect(img, 25, 0, 2, 3, BOSS_SWORD_GLOW)
    fill_rect(img, 25, 3, 2, 14, BOSS_SWORD)
    fill_rect(img, 24, 17, 4, 1, BOSS_ARMOR_DARK)  # guard
    fill_rect(img, 25, 18, 2, 3, BOSS_ARMOR)  # grip
    save(img, "boss_dark_knight.png")


# ═══════════════════════════════════════════════════════════════════
# EFFECT SPRITES
# ═══════════════════════════════════════════════════════════════════

def make_parry_ring():
    """Simple ring for parry indicator."""
    img = make_img(32, 32)
    draw = ImageDraw.Draw(img)
    # Outer ring
    draw.ellipse([1, 1, 30, 30], outline=(255, 255, 255, 200), width=2)
    # Inner target
    draw.ellipse([12, 12, 19, 19], outline=(255, 255, 100, 200), width=1)
    path = os.path.join(SPRITE_DIR, "..", "ui", "parry_ring.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    scaled = scale_up(img, 3)
    scaled.save(path)
    print(f"  Saved parry_ring.png ({scaled.width}x{scaled.height})")


# ═══════════════════════════════════════════════════════════════════
# GENERATE ALL
# ═══════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("Generating party sprites...")
    make_mage_idle()
    make_mage_attack()
    make_mage_skill()

    make_gustave_idle()
    make_gustave_attack()
    make_gustave_skill()

    make_sage_idle()
    make_sage_attack()
    make_sage_skill()

    print("\nGenerating enemy sprites...")
    make_goblin()
    make_wraith()
    make_golem()
    make_boss()

    print("\nGenerating UI sprites...")
    make_parry_ring()

    print("\nDone! All sprites generated.")
