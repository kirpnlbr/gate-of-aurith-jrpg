#!/usr/bin/env python3
"""
Re-process Dark Knight sprites from new uploads.
Uses edge flood-fill with conservative thresholds to preserve dark purple armor.
Handles text labels, grid borders, watermarks.
"""
import os
import numpy as np
from PIL import Image
from collections import deque

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS_DIR = os.path.join(BASE, "assets", "sprites", "battle", "new dark knight")
FRAMES_DIR = os.path.join(BASE, "assets", "sprites", "battle", "frames")

# Map sheet filenames -> output folder names
SHEET_MAP = {
    "dark knight idle": "dark_knight_idle",
    "dark knight combo": "dark_knight_blade_combo",
    "dark knight dark cleave": "dark_knight_dark_cleave",
    "dark knight feint": "dark_knight_delayed_thrust",
    "dark knight shadow rend": "dark_knight_shadow_rend",
    "dark knight abyssal onslaught": "dark_knight_onslaught",
}


def is_propagate(r, g, b, a):
    """Check if pixel should be cleared during flood fill.
    Does NOT match dark near-black pixels — those could be armor outlines."""
    if a == 0:
        return True
    brightness = (r + g + b) / 3
    saturation = max(r, g, b) - min(r, g, b)

    # Bright magenta background
    if r > 150 and b > 150 and g < 80 and brightness > 100:
        return True

    # Medium magenta fringe (anti-aliasing at sprite edge)
    if r > 100 and b > 100 and g < 60 and brightness > 80:
        return True

    # Near-white / light gray (grid lines, text on bg)
    if brightness > 180 and saturation < 50:
        return True

    # Pinkish anti-aliasing fringe
    if r > 80 and b > 80 and g < 40 and brightness > 55:
        return True

    return False


def strip_grid_border(img, border_px=8):
    """Clear the dark grid border pixels around the edge of each cell.
    These are near-black artifacts from the sprite sheet grid."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for i in range(border_px):
        for x in range(w):
            pixels[x, i] = (0, 0, 0, 0)
            pixels[x, h - 1 - i] = (0, 0, 0, 0)
        for y in range(h):
            pixels[i, y] = (0, 0, 0, 0)
            pixels[w - 1 - i, y] = (0, 0, 0, 0)

    return img


def flood_fill_remove_bg(img):
    """Flood fill from edges using 8-connectivity, removing background pixels."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    visited = [[False] * h for _ in range(w)]
    to_clear = []

    queue = deque()
    # Seed from all edges
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(1, h - 1):
        queue.append((0, y))
        queue.append((w - 1, y))

    neighbors = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        if visited[x][y]:
            continue
        visited[x][y] = True

        r, g, b, a = pixels[x, y]
        if is_propagate(r, g, b, a):
            to_clear.append((x, y))
            for dx, dy in neighbors:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                    queue.append((nx, ny))

    for x, y in to_clear:
        pixels[x, y] = (0, 0, 0, 0)

    return img


def remove_non_main_clusters(img, min_keep_ratio=0.05):
    """Remove all pixel clusters except the largest one (the sprite body).
    This cleans up text labels and other floating artifacts after bg removal."""
    img = img.convert("RGBA")
    arr = np.array(img)
    alpha = arr[:, :, 3] > 0
    h, w = alpha.shape

    if not np.any(alpha):
        return img

    # Label connected components with 8-connectivity
    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
    component_sizes = {}

    for sy in range(h):
        for sx in range(w):
            if alpha[sy, sx] and labels[sy, sx] == 0:
                label_id += 1
                size = 0
                queue = deque([(sy, sx)])
                labels[sy, sx] = label_id
                while queue:
                    cy, cx = queue.popleft()
                    size += 1
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            if dy == 0 and dx == 0:
                                continue
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and labels[ny, nx] == 0:
                                labels[ny, nx] = label_id
                                queue.append((ny, nx))
                component_sizes[label_id] = size

    if not component_sizes:
        return img

    # Keep only the largest cluster
    main_label = max(component_sizes, key=component_sizes.get)
    main_size = component_sizes[main_label]

    # Remove clusters that are small relative to the main body
    removed = 0
    for lid, size in component_sizes.items():
        if lid != main_label and size < main_size * min_keep_ratio:
            mask = labels == lid
            arr[mask, 3] = 0
            removed += size

    if removed > 0:
        return Image.fromarray(arr, "RGBA")
    return img


def remove_watermark(img, corner_size=50):
    """Remove Gemini sparkle watermark from bottom-right."""
    pixels = img.load()
    w, h = img.size
    for y in range(max(0, h - corner_size), h):
        for x in range(max(0, w - corner_size), w):
            r, g, b, a = pixels[x, y]
            if a > 0:
                brightness = (r + g + b) / 3
                if brightness > 150:
                    neighbor_alpha = 0
                    count = 0
                    for dy in [-2, -1, 0, 1, 2]:
                        for dx in [-2, -1, 0, 1, 2]:
                            nx, ny2 = x + dx, y + dy
                            if 0 <= nx < w and 0 <= ny2 < h and (dy != 0 or dx != 0):
                                neighbor_alpha += pixels[nx, ny2][3]
                                count += 1
                    if count > 0 and neighbor_alpha / count < 100:
                        pixels[x, y] = (0, 0, 0, 0)
    return img


def clean_stray_pixels(img, threshold=6):
    """Remove tiny isolated pixel clusters."""
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
            for ddx, ddy in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]:
                q.append((cx + ddx, cy + ddy))
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


def process_sheet(sheet_filename, out_folder):
    """Split a 3x3 sheet and clean each frame."""
    sheet_path = os.path.join(SHEETS_DIR, f"{sheet_filename}.png")
    if not os.path.exists(sheet_path):
        print(f"  SKIP {sheet_filename}: not found")
        return

    img = Image.open(sheet_path).convert("RGBA")
    w, h = img.size
    cell_w = w // 3
    cell_h = h // 3

    out_dir = os.path.join(FRAMES_DIR, out_folder)
    os.makedirs(out_dir, exist_ok=True)

    print(f"  {sheet_filename} -> {out_folder}/")

    for idx in range(9):
        row, col = divmod(idx, 3)
        x = col * cell_w
        y = row * cell_h
        frame = img.crop((x, y, x + cell_w, y + cell_h))

        # 1. Strip dark grid border, then flood fill magenta bg
        frame = strip_grid_border(frame, border_px=8)
        frame = flood_fill_remove_bg(frame)

        # 2. Remove watermark on last frame
        if idx == 8:
            frame = remove_watermark(frame)

        # 3. Remove non-main clusters (text labels, floating artifacts)
        frame = remove_non_main_clusters(frame)

        # 4. Clean remaining stray pixels
        frame = clean_stray_pixels(frame)

        frame_path = os.path.join(out_dir, f"frame_{idx}.png")
        frame.save(frame_path)

    print(f"    -> 9 frames saved")


def main():
    print("Re-processing Dark Knight sprites\n")
    for sheet_name, folder_name in SHEET_MAP.items():
        process_sheet(sheet_name, folder_name)
    print("\nDone!")


if __name__ == "__main__":
    main()
