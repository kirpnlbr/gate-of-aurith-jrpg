#!/usr/bin/env python3
"""
Slice party defend sprite sheets (3x3 grids) into individual frame folders.
Source: assets/sprites/battle/party defend/
Output: assets/sprites/battle/frames/<name>/frame_0.png ... frame_8.png
"""

from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_DIR = os.path.join(BASE_DIR, "assets", "sprites", "battle", "party defend")
FRAMES_DIR = os.path.join(BASE_DIR, "assets", "sprites", "battle", "frames")

SPRITE_MAP = {
    "mage_defend.png":         "mage_defend",
    "sage_defend.png":         "sage_defend",
    "gustave_defend.png":      "gustave_defend",
    "gustave_defend_alt.png":  "gustave_defend_alt",
}


def split_sheet(img, grid_cols=3, grid_rows=3):
    w, h = img.size
    cell_w = w // grid_cols
    cell_h = h // grid_rows
    frames = []
    for row in range(grid_rows):
        for col in range(grid_cols):
            x0, y0 = col * cell_w, row * cell_h
            frames.append(img.crop((x0, y0, x0 + cell_w, y0 + cell_h)))
    return frames


def process(filename, folder_name):
    src = os.path.join(SOURCE_DIR, filename)
    if not os.path.exists(src):
        print(f"  SKIP (not found): {filename}")
        return
    out_dir = os.path.join(FRAMES_DIR, folder_name)
    os.makedirs(out_dir, exist_ok=True)
    img = Image.open(src).convert("RGBA")
    frames = split_sheet(img)
    for i, frame in enumerate(frames):
        frame.save(os.path.join(out_dir, f"frame_{i}.png"))
    print(f"  {filename} -> {folder_name}/ ({len(frames)} frames)")


def main():
    print("=" * 50)
    print("Party Defend Sheet Splitter")
    print("=" * 50)
    for filename, folder in SPRITE_MAP.items():
        process(filename, folder)
    print("\nDone. Run clean_frames.py next to remove magenta backgrounds.")


if __name__ == "__main__":
    main()
