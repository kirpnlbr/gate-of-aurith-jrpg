#!/usr/bin/env python3
"""
Split 3x3 sprite sheets into individual frames and place them in the correct folders.
Handles flipping and text cleanup.
"""

from PIL import Image, ImageDraw
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_DIR = os.path.join(BASE_DIR, "assets", "sprites", "battle", "new enemy sprites")
FRAMES_DIR = os.path.join(BASE_DIR, "assets", "sprites", "battle", "frames")

# Map source filename -> output folder name
SPRITE_MAP = {
    "goblin_idle.png": "goblin_idle",
    "goblin_slash.png": "goblin_slash",
    "goblin_double_strike.png": "goblin_double_strike",
    "wraith_idle.png": "wraith_idle",
    "wraith_spectral_claw.png": "wraith_spectral_claw",
    "wraith_delayed_haunt.png": "wraith_delayed_haunt",
    "golem_idle.png": "golem_idle",
    "golem_ground_slam.png": "golem_ground_slam",
    "golem_boulder_toss.png": "golem_boulder_toss",
    "golem_earthquake.png": "golem_earthquake",
    "dark_knight_idle.png": "dark_knight_idle",
    "dark_knight_blade_combo.png": "dark_knight_blade_combo",
    "dark_knight_delayed_thrust.png": "dark_knight_delayed_thrust",
    "dark_knight_dark_cleave.png": "dark_knight_dark_cleave",
    "dark_knight_shadow_rend.png": "dark_knight_shadow_rend",
    "dark_knight_onslaught.png": "dark_knight_onslaught",
}

# Sprites that need horizontal flipping (facing right, should face left)
FLIP_SPRITES = {
    "golem_idle", "golem_ground_slam", "golem_boulder_toss", "golem_earthquake",
    "dark_knight_idle", "dark_knight_blade_combo", "dark_knight_delayed_thrust",
    "dark_knight_dark_cleave", "dark_knight_shadow_rend", "dark_knight_onslaught",
}

# Sprites with text that needs to be cleaned (paint over with magenta)
TEXT_CLEANUP = {
    "dark_knight_dark_cleave.png",
}

MAGENTA = (255, 0, 255, 255)
MAGENTA_RGB = (255, 0, 255)


def is_near_magenta(pixel, fuzz=60):
    """Check if a pixel is close to magenta."""
    if len(pixel) == 4:
        r, g, b, a = pixel
        if a < 30:
            return True
    else:
        r, g, b = pixel
    return r > (255 - fuzz) and g < fuzz and b > (255 - fuzz)


def clean_text_from_frame(img):
    """
    Remove text from a frame by detecting non-magenta, non-sprite pixels
    in the bottom portion and replacing them with magenta.
    Text appears as white/gray pixels on the magenta background.
    """
    pixels = img.load()
    w, h = img.size

    # Text is typically in the bottom third of each cell
    # Scan for pixels that are text-like (light colored, not part of dark sprite)
    # Strategy: find connected regions of light pixels near the bottom that aren't
    # part of the main sprite. Simple approach: any pixel in bottom 30% that is
    # light (high brightness) and not magenta -> replace with magenta
    text_zone_start = int(h * 0.55)

    for y in range(text_zone_start, h):
        for x in range(w):
            p = pixels[x, y]
            r, g, b = p[0], p[1], p[2]
            a = p[3] if len(p) == 4 else 255

            if is_near_magenta(p):
                continue

            # Check if this is likely text (white, light gray, or light colored)
            brightness = (r + g + b) / 3
            if brightness > 150 and a > 100:
                # Check if it's isolated from dark sprite pixels above
                # (text tends to be at the very bottom with magenta around it)
                is_text = True
                # Sample pixels above - if there's magenta above, this is likely text
                for check_y in range(max(0, y - 8), y):
                    cp = pixels[x, check_y]
                    if not is_near_magenta(cp):
                        cr, cg, cb = cp[0], cp[1], cp[2]
                        c_bright = (cr + cg + cb) / 3
                        if c_bright < 100:  # dark sprite pixel above
                            is_text = False
                            break

                if is_text:
                    if len(p) == 4:
                        pixels[x, y] = MAGENTA
                    else:
                        pixels[x, y] = MAGENTA_RGB

    return img


def split_sheet(img, grid_cols=3, grid_rows=3):
    """Split a sprite sheet into individual frame images, detecting borders."""
    w, h = img.size

    # Detect border lines by finding vertical/horizontal lines that are mostly dark
    # Simple approach: divide evenly, then adjust for borders
    cell_w = w // grid_cols
    cell_h = h // grid_rows

    frames = []
    for row in range(grid_rows):
        for col in range(grid_cols):
            x0 = col * cell_w
            y0 = row * cell_h
            x1 = x0 + cell_w
            y1 = y0 + cell_h

            frame = img.crop((x0, y0, x1, y1))

            # Trim 1-2px border lines if present (detect dark edges)
            frame = trim_borders(frame)

            frames.append(frame)

    return frames


def trim_borders(img, max_trim=4):
    """Trim dark border lines from edges of a frame."""
    pixels = img.load()
    w, h = img.size

    def is_border_row(y):
        dark_count = 0
        for x in range(w):
            p = pixels[x, y]
            r, g, b = p[0], p[1], p[2]
            if r < 40 and g < 40 and b < 40:
                dark_count += 1
        return dark_count > w * 0.7

    def is_border_col(x):
        dark_count = 0
        for y in range(h):
            p = pixels[x, y]
            r, g, b = p[0], p[1], p[2]
            if r < 40 and g < 40 and b < 40:
                dark_count += 1
        return dark_count > h * 0.7

    top = 0
    bottom = h
    left = 0
    right = w

    for i in range(min(max_trim, h // 4)):
        if is_border_row(top):
            top += 1
        if is_border_row(bottom - 1):
            bottom -= 1
        if is_border_col(left):
            left += 1
        if is_border_col(right - 1):
            right -= 1

    if top > 0 or bottom < h or left > 0 or right < w:
        return img.crop((left, top, right, bottom))
    return img


def process_sprite(filename, folder_name):
    """Process a single sprite sheet: clean, split, flip if needed, save frames."""
    src_path = os.path.join(SOURCE_DIR, filename)
    if not os.path.exists(src_path):
        print(f"  SKIP (not found): {filename}")
        return False

    out_dir = os.path.join(FRAMES_DIR, folder_name)
    os.makedirs(out_dir, exist_ok=True)

    img = Image.open(src_path).convert("RGBA")
    print(f"  Loaded: {filename} ({img.size[0]}x{img.size[1]})")

    # Clean text if needed
    if filename in TEXT_CLEANUP:
        print(f"  Cleaning text from {filename}...")
        img = clean_text_from_frame(img)

    # Split into frames
    frames = split_sheet(img)
    print(f"  Split into {len(frames)} frames")

    # Flip if needed
    if folder_name in FLIP_SPRITES:
        print(f"  Flipping horizontally (was facing right)")
        frames = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in frames]

    # Save frames
    for i, frame in enumerate(frames):
        frame_path = os.path.join(out_dir, f"frame_{i}.png")
        frame.save(frame_path)

    print(f"  Saved {len(frames)} frames to {folder_name}/")
    return True


def main():
    print("=" * 60)
    print("Enemy Sprite Sheet Processor")
    print("=" * 60)
    print(f"Source: {SOURCE_DIR}")
    print(f"Output: {FRAMES_DIR}")
    print()

    if not os.path.exists(SOURCE_DIR):
        print(f"ERROR: Source directory not found: {SOURCE_DIR}")
        sys.exit(1)

    success = 0
    total = len(SPRITE_MAP)

    for filename, folder_name in SPRITE_MAP.items():
        print(f"\nProcessing: {filename} -> {folder_name}/")
        if process_sprite(filename, folder_name):
            success += 1

    print(f"\n{'=' * 60}")
    print(f"Done: {success}/{total} sprites processed successfully")
    print("=" * 60)


if __name__ == "__main__":
    main()
