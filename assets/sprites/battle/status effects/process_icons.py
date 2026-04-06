#!/usr/bin/env python3
"""Process status effect icons: strip backgrounds, add ridged border, downscale."""

from PIL import Image
import os

ICON_SIZE = 32
BORDER = 2  # pixels for the ridged border
INNER_SIZE = ICON_SIZE - BORDER * 2  # icon art area

# Ridged border colors (outer highlight -> inner shadow, like Chrono Trigger / RuneScape)
RIDGE_OUTER_LIGHT = (200, 180, 140, 255)  # warm beige highlight
RIDGE_OUTER_DARK = (80, 60, 40, 255)      # dark brown shadow
RIDGE_INNER_LIGHT = (160, 140, 110, 255)  # mid highlight
RIDGE_INNER_DARK = (50, 38, 25, 255)      # deeper shadow

MAGENTA_THRESHOLD = 60  # how close to magenta a pixel must be

def is_magenta(r, g, b):
    """Check if pixel is close to magenta (#FF00FF)."""
    return r > 180 and g < MAGENTA_THRESHOLD and b > 180

def is_checkerboard_bg(img):
    """Detect if image has a checkerboard transparency pattern."""
    # Sample corners - checkerboard patterns alternate light/dark gray
    pixels = img.load()
    w, h = img.size
    corners = [(0, 0), (1, 0), (0, 1), (1, 1)]
    grays = 0
    for x, y in corners:
        r, g, b = pixels[x, y][:3]
        if abs(r - g) < 10 and abs(g - b) < 10 and 150 < r < 255:
            grays += 1
    return grays >= 3

def strip_checkerboard(img):
    """Remove checkerboard transparency pattern."""
    pixels = img.load()
    w, h = img.size
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    result_pixels = result.load()

    for y in range(h):
        for x in range(w):
            r, g, b = pixels[x, y][:3]
            a = pixels[x, y][3] if len(pixels[x, y]) > 3 else 255
            # Checkerboard cells are gray (~191 or ~204 alternating)
            is_light_gray = abs(r - g) < 15 and abs(g - b) < 15 and 180 < r < 220
            is_dark_gray = abs(r - g) < 15 and abs(g - b) < 15 and 140 < r < 180
            if is_light_gray or is_dark_gray:
                result_pixels[x, y] = (0, 0, 0, 0)
            else:
                result_pixels[x, y] = (r, g, b, a)
    return result

def strip_magenta(img):
    """Remove magenta background pixels."""
    pixels = img.load()
    w, h = img.size
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    result_pixels = result.load()

    for y in range(h):
        for x in range(w):
            r, g, b = pixels[x, y][:3]
            a = pixels[x, y][3] if len(pixels[x, y]) > 3 else 255
            if is_magenta(r, g, b):
                result_pixels[x, y] = (0, 0, 0, 0)
            else:
                result_pixels[x, y] = (r, g, b, a)
    return result

def add_ridged_border(img):
    """Add a 2px ridged border around the icon (Chrono Trigger / RuneScape style)."""
    w, h = img.size
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    result_pixels = result.load()

    # Copy original pixels into center
    for y in range(h):
        for x in range(w):
            result_pixels[x, y] = img.getpixel((x, y))

    # Draw outer border (pixel 0) - light on top/left, dark on bottom/right
    for x in range(w):
        result_pixels[x, 0] = RIDGE_OUTER_LIGHT        # top
        result_pixels[x, h - 1] = RIDGE_OUTER_DARK      # bottom
    for y in range(h):
        result_pixels[0, y] = RIDGE_OUTER_LIGHT          # left
        result_pixels[w - 1, y] = RIDGE_OUTER_DARK       # right
    # Corners: bottom-left and top-right get blended
    result_pixels[0, h - 1] = RIDGE_OUTER_DARK
    result_pixels[w - 1, 0] = RIDGE_OUTER_DARK

    # Draw inner border (pixel 1) - same pattern, slightly different shade
    for x in range(1, w - 1):
        result_pixels[x, 1] = RIDGE_INNER_LIGHT          # top inner
        result_pixels[x, h - 2] = RIDGE_INNER_DARK       # bottom inner
    for y in range(1, h - 1):
        result_pixels[1, y] = RIDGE_INNER_LIGHT           # left inner
        result_pixels[w - 2, y] = RIDGE_INNER_DARK        # right inner
    result_pixels[1, h - 2] = RIDGE_INNER_DARK
    result_pixels[w - 2, 1] = RIDGE_INNER_DARK

    return result

def process_icon(input_path, output_path):
    """Full pipeline: load, strip bg, downscale, add border."""
    img = Image.open(input_path).convert("RGBA")

    # Strip background
    if is_checkerboard_bg(img):
        print(f"  Detected checkerboard background: {os.path.basename(input_path)}")
        img = strip_checkerboard(img)
    else:
        img = strip_magenta(img)

    # Downscale to final size using nearest-neighbor to keep pixel art crisp
    img = img.resize((ICON_SIZE, ICON_SIZE), Image.NEAREST)

    # Add ridged border
    img = add_ridged_border(img)

    img.save(output_path)
    print(f"  Saved: {os.path.basename(output_path)} ({ICON_SIZE}x{ICON_SIZE})")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    icons = {
        "ablaze_raw.png": "ablaze.png",
        "chilled_raw.png": "chilled.png",
        "shocked_raw.png": "shocked.png",
        "soaked_raw.png": "soaked.png",
        "buff_atk_raw.png": "buff_atk.png",
        "buff_def_raw.png": "buff_def.png",
        "buff_spd_raw.png": "buff_spd.png",
        "debuff_def_raw.png": "debuff_def.png",
        "taunt_raw.png": "taunt.png",
    }

    for raw_name, final_name in icons.items():
        input_path = os.path.join(script_dir, raw_name)
        output_path = os.path.join(script_dir, final_name)
        if not os.path.exists(input_path):
            print(f"  SKIP (not found): {raw_name}")
            continue
        print(f"Processing {raw_name}...")
        process_icon(input_path, output_path)

if __name__ == "__main__":
    main()
