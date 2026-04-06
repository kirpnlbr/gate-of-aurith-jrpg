#!/usr/bin/env python3
"""
Split 3x3 VFX sprite sheets into individual frame_N.png files.
Maps Gemini-generated filenames to their VFX folder names.
"""
from PIL import Image
import os

PROJECT_DIR = os.path.dirname(__file__)
VFX_SRC = os.path.join(PROJECT_DIR, "assets", "sprites", "battle", "vfx")
FRAMES_DST = os.path.join(PROJECT_DIR, "assets", "sprites", "battle", "frames", "vfx")

# Mapping: gemini filename (without extension) -> vfx folder name
SHEET_MAP = {
    "Gemini_Generated_Image_vxwirrvxwirrvxwi": "slash_arc",
    "Gemini_Generated_Image_g0v4c0g0v4c0g0v4": "proj_orb",
    "Gemini_Generated_Image_n5v8qrn5v8qrn5v8": "proj_shard",
    "Gemini_Generated_Image_sy8ylesy8ylesy8y": "wave_sweep",
    "Gemini_Generated_Image_wvs183wvs183wvs1": "eruption",
    "Gemini_Generated_Image_iggsv7iggsv7iggs": "impact_burst",
    "Gemini_Generated_Image_g4zbnjg4zbnjg4zb": "parry_spark",
    "Gemini_Generated_Image_aohkh5aohkh5aohk": "heal_shimmer",
    "Gemini_Generated_Image_noy89hnoy89hnoy8": "aura_buff",
    "Gemini_Generated_Image_mh7q34mh7q34mh7q": "summon_winged",
    "Gemini_Generated_Image_arzdm0arzdm0arzd": "summon_serpent",
    "Gemini_Generated_Image_w43btkw43btkw43b": "summon_beast",
}


def split_sheet(src_path: str, dst_folder: str) -> None:
    os.makedirs(dst_folder, exist_ok=True)
    img = Image.open(src_path)
    w, h = img.size
    cell_w = w // 3
    cell_h = h // 3

    for idx in range(9):
        row = idx // 3
        col = idx % 3
        left = col * cell_w
        top = row * cell_h
        cell = img.crop((left, top, left + cell_w, top + cell_h))
        # Convert to RGBA if not already
        if cell.mode != "RGBA":
            cell = cell.convert("RGBA")
        out_path = os.path.join(dst_folder, f"frame_{idx}.png")
        cell.save(out_path)
    print(f"  -> {dst_folder} ({cell_w}x{cell_h} per frame)")


def main():
    print("Splitting VFX sprite sheets...")
    for stem, folder_name in SHEET_MAP.items():
        src_path = os.path.join(VFX_SRC, stem + ".png")
        if not os.path.exists(src_path):
            print(f"  MISSING: {src_path}")
            continue
        dst_folder = os.path.join(FRAMES_DST, folder_name)
        split_sheet(src_path, dst_folder)
    print(f"\nDone! Split {len(SHEET_MAP)} sheets into {FRAMES_DST}")


if __name__ == "__main__":
    main()
