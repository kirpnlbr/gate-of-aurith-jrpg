#!/usr/bin/env python3
"""
Deep-clean all sprite frames v3:
  - Two-pass flood fill: strict seeds from edges, then propagate through
    borderline pixels only if they connect back to confirmed background
  - Preserves dark sprite outlines that look similar to dark magenta
  - Removes gray borders, magenta background, watermarks, stray pixels
"""
from PIL import Image
import os
from collections import deque

FRAMES_DIR = os.path.join(
    os.path.dirname(__file__), "assets", "sprites", "battle", "frames"
)

SKIP_PREFIXES = ("goblin", "wraith", "golem", "boss_", "dark_knight")


def is_definite_background(r, g, b, a):
    """Pixels that are DEFINITELY background — safe to seed flood fill from."""
    if a == 0:
        return True
    brightness = (r + g + b) / 3

    # Bright magenta (#FF00FF and near)
    if r > 150 and b > 150 and g < 80:
        return True

    # Medium magenta (desaturated, like grid lines ~rgba(170,60,170))
    if r > 120 and b > 120 and g < ((r + b) / 2) * 0.45 and brightness > 100:
        return True

    # Light gray / white / off-white
    saturation = max(r, g, b) - min(r, g, b)
    if brightness > 200 and saturation < 35:
        return True

    # Neutral gray (grid border lines ~brightness 115-130, sat < 15)
    if brightness > 100 and saturation < 15:
        return True

    return False


def is_propagate_background(r, g, b, a):
    """Pixels that are background IF they're connected to definite background.
    This catches dark magenta fringe that's contiguous with the background
    but would be dangerous to classify standalone (looks like dark outlines)."""
    if a == 0:
        return True
    if is_definite_background(r, g, b, a):
        return True

    brightness = (r + g + b) / 3
    saturation = max(r, g, b) - min(r, g, b)

    # Dark magenta fringe: R and B present, G very low, dark
    # These sit between bright magenta bg and the sprite's black outline
    if brightness < 80 and g <= 5 and r > 3 and b > 3:
        rb_avg = (r + b) / 2
        if rb_avg > 10:
            return True

    # Pinkish/purplish anti-aliasing fringe
    if r > 80 and b > 80 and g < 50 and brightness < 100:
        return True

    # Very light desaturated anything
    if brightness > 180 and saturation < 45:
        return True

    return False


def flood_fill_background(img):
    """Two-tier flood fill: seed from edges with strict check,
    propagate through borderline pixels."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    visited = set()
    to_clear = []

    queue = deque()
    # Seed all edge pixels
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(1, h - 1):
        queue.append((0, y))
        queue.append((w - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        key = (x, y)
        if key in visited:
            continue
        visited.add(key)

        r, g, b, a = pixels[x, y]

        # First pixel from edge must be definite background
        # But once we're propagating from confirmed bg, use the softer check
        # The trick: if this pixel is reachable from the edge through background,
        # it IS background. We use the propagation check for all pixels in the fill.
        if is_propagate_background(r, g, b, a):
            to_clear.append((x, y))
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))

    for x, y in to_clear:
        pixels[x, y] = (0, 0, 0, 0)

    return img


def remove_watermark(img, corner_size=45):
    """Clear Gemini sparkle watermark from bottom-right corner."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for y in range(max(0, h - corner_size), h):
        for x in range(max(0, w - corner_size), w):
            r, g, b, a = pixels[x, y]
            if a > 0:
                brightness = (r + g + b) / 3
                if brightness > 160:
                    neighbor_alpha = 0
                    count = 0
                    for dy in [-2, -1, 0, 1, 2]:
                        for dx in [-2, -1, 0, 1, 2]:
                            nx, ny2 = x + dx, y + dy
                            if 0 <= nx < w and 0 <= ny2 < h and (dy != 0 or dx != 0):
                                neighbor_alpha += pixels[nx, ny2][3]
                                count += 1
                    if count > 0 and neighbor_alpha / count < 80:
                        pixels[x, y] = (0, 0, 0, 0)

    return img


def clean_stray_pixels(img, threshold=4):
    """Remove tiny isolated pixel clusters floating in transparent space."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    visited = set()

    def flood_count(sx, sy):
        cluster = []
        q = deque([(sx, sy)])
        while q:
            cx, cy = q.popleft()
            if (cx, cy) in visited or cx < 0 or cx >= w or cy < 0 or cy >= h:
                continue
            if pixels[cx, cy][3] == 0:
                continue
            visited.add((cx, cy))
            cluster.append((cx, cy))
            if len(cluster) > threshold:
                return cluster
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                q.append((cx + dx, cy + dy))
        return cluster

    for y in range(h):
        for x in range(w):
            if (x, y) in visited or pixels[x, y][3] == 0:
                continue
            cluster = flood_count(x, y)
            if len(cluster) <= threshold:
                for cx, cy in cluster:
                    pixels[cx, cy] = (0, 0, 0, 0)

    return img


def strip_edge_border(img, border_px=4):
    """Pre-pass: clear low-saturation pixels along frame edges.
    These are grid border remnants that may block flood fill propagation."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for i in range(border_px):
        # Top and bottom rows
        for x in range(w):
            for row in [i, h - 1 - i]:
                r, g, b, a = pixels[x, row]
                if a > 0:
                    sat = max(r, g, b) - min(r, g, b)
                    bright = (r + g + b) / 3
                    # Gray/neutral border or dark magenta fringe at edges
                    if sat < 30 and bright > 80:
                        pixels[x, row] = (0, 0, 0, 0)
                    elif sat < 30 and bright < 20:
                        pixels[x, row] = (0, 0, 0, 0)
                    # Magenta-tinted at edge
                    elif r > 80 and b > 80 and g < 30 and bright < 80:
                        pixels[x, row] = (0, 0, 0, 0)
        # Left and right columns
        for y in range(h):
            for col in [i, w - 1 - i]:
                r, g, b, a = pixels[col, y]
                if a > 0:
                    sat = max(r, g, b) - min(r, g, b)
                    bright = (r + g + b) / 3
                    if sat < 30 and bright > 80:
                        pixels[col, y] = (0, 0, 0, 0)
                    elif sat < 30 and bright < 20:
                        pixels[col, y] = (0, 0, 0, 0)
                    elif r > 80 and b > 80 and g < 30 and bright < 80:
                        pixels[col, y] = (0, 0, 0, 0)

    return img


def clean_frame(img, is_last_frame=False):
    """Full cleaning pipeline for one frame."""
    img = img.convert("RGBA")
    # Pre-pass: strip border lines at edges so flood fill can reach background
    img = strip_edge_border(img, border_px=4)
    # Main pass: flood fill from edges
    img = flood_fill_background(img)
    if is_last_frame:
        img = remove_watermark(img)
    img = clean_stray_pixels(img, threshold=4)
    return img


def process_folder(folder_name):
    """Clean all frames in a folder."""
    folder_path = os.path.join(FRAMES_DIR, folder_name)
    if not os.path.isdir(folder_path):
        return

    frames = sorted([
        f for f in os.listdir(folder_path)
        if f.startswith("frame_") and f.endswith(".png")
        and not f.endswith(".import")
    ])

    if not frames:
        return

    print(f"  {folder_name}: {len(frames)} frames", end="", flush=True)

    for i, fname in enumerate(frames):
        fpath = os.path.join(folder_path, fname)
        img = Image.open(fpath).convert("RGBA")
        is_last = (i == len(frames) - 1)
        clean = clean_frame(img, is_last_frame=is_last)
        clean.save(fpath)

    print(f" -> done")


def main():
    print("=" * 60)
    print("DEEP FRAME CLEANER v3")
    print("=" * 60)

    folders = sorted([
        d for d in os.listdir(FRAMES_DIR)
        if os.path.isdir(os.path.join(FRAMES_DIR, d))
        and not d.startswith(".")
        and not any(d.startswith(p) for p in SKIP_PREFIXES)
    ])

    print(f"Found {len(folders)} animation folders to clean:\n")

    for folder in folders:
        process_folder(folder)

    print(f"\n{'=' * 60}")
    print("DONE! All frames cleaned.")
    print("=" * 60)


if __name__ == "__main__":
    main()
