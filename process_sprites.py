#!/usr/bin/env python3
"""
Process sprite sheets: split into individual frames, remove magenta background.
Output structure:
  assets/sprites/battle/frames/<character>_<skill>/frame_0.png ... frame_8.png
  assets/sprites/battle/sheets_clean/<sheetname>_clean.png (magenta removed)
"""
from PIL import Image
import os
import sys

BATTLE_DIR = os.path.join(os.path.dirname(__file__), "assets", "sprites", "battle")
FRAMES_DIR = os.path.join(BATTLE_DIR, "frames")
CLEAN_DIR = os.path.join(BATTLE_DIR, "sheets_clean")

# Magenta removal tolerance
MAGENTA_FUZZ = 80  # how far from pure #FF00FF to still count as background


def is_magenta(r, g, b, fuzz=MAGENTA_FUZZ):
    """Check if a pixel is close to magenta #FF00FF."""
    return r > (255 - fuzz) and g < fuzz and b > (255 - fuzz)


def remove_magenta(img):
    """Remove magenta background, handling anti-aliased fringing."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if is_magenta(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
            # Also catch pinkish fringe pixels near magenta areas
            elif r > 180 and g < 100 and b > 180:
                pixels[x, y] = (0, 0, 0, 0)
    return img


def remove_watermark(img, corner_size=30):
    """Clear the bottom-right corner where Gemini puts its sparkle watermark."""
    pixels = img.load()
    w, h = img.size
    for y in range(h - corner_size, h):
        for x in range(w - corner_size, w):
            r, g, b, a = pixels[x, y]
            # If it's a light/white sparkle pixel on what should be magenta background
            if a > 0 and not is_magenta(r, g, b):
                # Check if it's likely a watermark (light colored, small area)
                brightness = (r + g + b) / 3
                if brightness > 180:
                    pixels[x, y] = (0, 0, 0, 0)
    return img


def split_sheet(img_path, grid_cols=3, grid_rows=3):
    """Split a sprite sheet into individual frame images."""
    img = Image.open(img_path).convert("RGBA")
    w, h = img.size
    cell_w = w // grid_cols
    cell_h = h // grid_rows

    frames = []
    for row in range(grid_rows):
        for col in range(grid_cols):
            x = col * cell_w
            y = row * cell_h
            frame = img.crop((x, y, x + cell_w, y + cell_h))
            frames.append(frame)
    return frames


def process_sheet(filename):
    """Process one sprite sheet: split, clean, save."""
    filepath = os.path.join(BATTLE_DIR, filename)
    base_name = filename.replace("_sheet.png", "").replace(".png", "")

    print(f"\n--- Processing: {filename} ---")
    print(f"    Base name: {base_name}")

    # Split into frames
    frames = split_sheet(filepath)
    print(f"    Split into {len(frames)} frames ({frames[0].size[0]}x{frames[0].size[1]} each)")

    # Create output directory for this sheet's frames
    frame_dir = os.path.join(FRAMES_DIR, base_name)
    os.makedirs(frame_dir, exist_ok=True)

    # Process and save each frame
    for i, frame in enumerate(frames):
        # Remove watermark from last frame (bottom-right)
        if i == len(frames) - 1:
            frame = remove_watermark(frame)

        # Remove magenta
        clean_frame = remove_magenta(frame)

        # Save individual frame
        frame_path = os.path.join(frame_dir, f"frame_{i}.png")
        clean_frame.save(frame_path)

    print(f"    Saved {len(frames)} frames to: frames/{base_name}/")

    # Also save a clean full sheet (magenta removed)
    os.makedirs(CLEAN_DIR, exist_ok=True)
    full_img = Image.open(filepath).convert("RGBA")

    # Remove watermark from bottom-right of full sheet
    full_img = remove_watermark(full_img)
    clean_full = remove_magenta(full_img)

    clean_path = os.path.join(CLEAN_DIR, f"{base_name}_clean.png")
    clean_full.save(clean_path)
    print(f"    Saved clean sheet: sheets_clean/{base_name}_clean.png")


def main():
    print("=" * 60)
    print("SPRITE SHEET PROCESSOR")
    print("=" * 60)

    # Find all sprite sheets
    sheets = sorted([
        f for f in os.listdir(BATTLE_DIR)
        if f.endswith("_sheet.png") and os.path.isfile(os.path.join(BATTLE_DIR, f))
    ])

    if not sheets:
        print("No sprite sheets found in", BATTLE_DIR)
        return

    print(f"Found {len(sheets)} sprite sheets to process:")
    for s in sheets:
        img = Image.open(os.path.join(BATTLE_DIR, s))
        print(f"  {s}: {img.width}x{img.height}")

    # Process each
    for sheet in sheets:
        process_sheet(sheet)

    # Summary
    print("\n" + "=" * 60)
    print("DONE!")
    print("=" * 60)
    print(f"\nIndividual frames saved to:")
    print(f"  {FRAMES_DIR}/")
    print(f"\nClean sheets saved to:")
    print(f"  {CLEAN_DIR}/")
    print(f"\nNow open Godot and check the frames/ folder.")
    print(f"Delete any bad frames you don't want.")
    print(f"The game will use whatever frames remain.")


if __name__ == "__main__":
    main()
