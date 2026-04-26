#!/usr/bin/env python3
"""
Clean residual pinkish-magenta border fringe from party defend frames.
The original flood-fill cleaner left ~400 light-magenta pixels along cell
edges in many frames — these are the grid-border artifacts where the flood
fill stopped at a dark line. Restricting cleanup to within EDGE_MARGIN
pixels of the border avoids touching sprite-interior purples.
"""

from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FRAMES_DIR = os.path.join(BASE_DIR, "assets", "sprites", "battle", "frames")

TARGET_FOLDERS = [
    "mage_defend",
    "sage_defend",
    "gustave_defend",
    "gustave_defend_alt",
]

EDGE_MARGIN = 14


def is_pinkish_magenta(r, g, b):
    if r < 150 or b < 150:
        return False
    if abs(r - b) > 50:
        return False
    if g >= min(r, b) - 20:
        return False
    return True


def is_light_gray(r, g, b):
    brightness = (r + g + b) / 3
    saturation = max(r, g, b) - min(r, g, b)
    if brightness > 200 and saturation < 40:
        return True
    return False


def clean_frame(path):
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    cleared = 0
    for y in range(h):
        for x in range(w):
            on_edge = (x < EDGE_MARGIN or x >= w - EDGE_MARGIN
                       or y < EDGE_MARGIN or y >= h - EDGE_MARGIN)
            if not on_edge:
                continue
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if is_pinkish_magenta(r, g, b) or is_light_gray(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                cleared += 1
    img.save(path)
    return cleared


def main():
    print("=" * 50)
    print("Defend Frame Border Cleaner")
    print("=" * 50)
    for folder in TARGET_FOLDERS:
        folder_path = os.path.join(FRAMES_DIR, folder)
        if not os.path.isdir(folder_path):
            print(f"  SKIP (not found): {folder}")
            continue
        frames = sorted(f for f in os.listdir(folder_path) if f.endswith(".png"))
        total = 0
        for fname in frames:
            total += clean_frame(os.path.join(folder_path, fname))
        print(f"  {folder}: {len(frames)} frames, {total} pixels cleared")
    print("\nDone.")


if __name__ == "__main__":
    main()
