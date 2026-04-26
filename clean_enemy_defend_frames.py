#!/usr/bin/env python3
"""
Clean magenta backgrounds from enemy defend frame folders.
Uses strict flood-fill only (no dark-fringe propagation) to preserve
dark enemy outlines.
"""

from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FRAMES_DIR = os.path.join(BASE_DIR, "assets", "sprites", "battle", "frames")

TARGET_FOLDERS = [
    "goblin_defend",
    "golem_defend",
    "wraith_defend",
    "dark_knight_defend",
]


def is_background(r, g, b, a):
    if a == 0:
        return True
    brightness = (r + g + b) / 3
    # Bright/medium magenta
    if r > 150 and b > 150 and g < 80:
        return True
    if r > 120 and b > 120 and g < ((r + b) / 2) * 0.45 and brightness > 100:
        return True
    # Light gray / white / off-white grid borders
    saturation = max(r, g, b) - min(r, g, b)
    if brightness > 200 and saturation < 35:
        return True
    # Neutral gray grid lines
    if brightness > 100 and saturation < 15:
        return True
    return False


def clean_frame(path):
    # Enemy sheets have a thin dark border around each cell that blocks edge
    # flood fill, so we do a direct pass over all pixels instead.
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    count = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if is_background(r, g, b, a):
                pixels[x, y] = (0, 0, 0, 0)
                count += 1
    img.save(path)
    return count


def main():
    print("=" * 50)
    print("Enemy Defend Frame Cleaner")
    print("=" * 50)
    for folder in TARGET_FOLDERS:
        folder_path = os.path.join(FRAMES_DIR, folder)
        if not os.path.isdir(folder_path):
            print(f"  SKIP (not found): {folder}")
            continue
        frames = sorted(f for f in os.listdir(folder_path) if f.endswith(".png"))
        total_cleared = 0
        for fname in frames:
            fpath = os.path.join(folder_path, fname)
            total_cleared += clean_frame(fpath)
        print(f"  {folder}: {len(frames)} frames, {total_cleared} pixels cleared")
    print("\nDone.")


if __name__ == "__main__":
    main()
