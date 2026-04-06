#!/usr/bin/env python3
"""
VFX Border Artifact Removal
============================
Removes rectangular bounding-box border artifacts from AI-generated VFX sprites.
These appear as dark/black dashed or solid lines near image edges.
"""

import os
import sys
from PIL import Image
import numpy as np
from collections import deque

VFX_BASE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "assets", "sprites", "battle", "frames", "vfx")


def get_margin(img_size):
    """Adaptive margin based on image size."""
    return max(15, img_size // 25)


def remove_border_lines(arr):
    """Remove border line artifacts from edge margins.

    Detects rows/columns near the edges that form lines spanning a large
    portion of the image, and clears them. Also clears residual dark pixels
    in the edge margin that aren't connected to the main content.
    """
    h, w = arr.shape[:2]
    margin_y = get_margin(h)
    margin_x = get_margin(w)
    removed = 0

    # Step 1: Clear border ROWS (horizontal dark lines near top/bottom)
    edge_rows = list(range(margin_y)) + list(range(h - margin_y, h))
    for row in edge_rows:
        visible_cols = np.where(arr[row, :, 3] > 0)[0]
        if len(visible_cols) < 2:
            continue
        span = visible_cols[-1] - visible_cols[0] + 1
        count = len(visible_cols)
        # A border line: spans > 40% of width AND pixels are predominantly dark
        if span > w * 0.4:
            colors = arr[row, visible_cols, :3]
            avg_brightness = np.mean(colors.astype(int).sum(axis=1))
            dark_ratio = np.sum(colors.astype(int).sum(axis=1) < 100) / count
            # Only clear if mostly dark pixels (border artifact, not content)
            if avg_brightness < 150 or dark_ratio > 0.5:
                arr[row, :, 3] = 0
                removed += count

    # Step 2: Clear border COLUMNS (vertical dark lines near left/right)
    edge_cols = list(range(margin_x)) + list(range(w - margin_x, w))
    for col in edge_cols:
        visible_rows = np.where(arr[:, col, 3] > 0)[0]
        if len(visible_rows) < 2:
            continue
        span = visible_rows[-1] - visible_rows[0] + 1
        count = len(visible_rows)
        # A border line: spans > 40% of height AND pixels are predominantly dark
        if span > h * 0.4:
            colors = arr[visible_rows, col, :3]
            avg_brightness = np.mean(colors.astype(int).sum(axis=1))
            dark_ratio = np.sum(colors.astype(int).sum(axis=1) < 100) / count
            if avg_brightness < 150 or dark_ratio > 0.5:
                arr[:, col, 3] = 0
                removed += count

    # Step 3: Clear remaining dark pixels in corner regions
    # Corner regions are where border artifacts concentrate
    corner_size = margin_y
    corners = [
        (slice(0, corner_size), slice(0, corner_size)),               # top-left
        (slice(0, corner_size), slice(w - corner_size, w)),           # top-right
        (slice(h - corner_size, h), slice(0, corner_size)),           # bottom-left
        (slice(h - corner_size, h), slice(w - corner_size, w)),       # bottom-right
    ]
    for ys, xs in corners:
        region = arr[ys, xs]
        # Clear dark pixels (near-black) in corners
        dark_mask = (region[:, :, 3] > 0) & \
                    (region[:, :, 0].astype(int) + region[:, :, 1].astype(int) + region[:, :, 2].astype(int) < 30)
        removed += int(np.sum(dark_mask))
        region[dark_mask, 3] = 0
        arr[ys, xs] = region

    return arr, removed


def remove_edge_margin_strays(arr):
    """Remove small isolated pixel groups in edge margins that are disconnected
    from the main central content."""
    h, w = arr.shape[:2]
    margin_y = get_margin(h)
    margin_x = get_margin(w)

    # Create a mask of the edge margin region
    edge_mask = np.zeros((h, w), dtype=bool)
    edge_mask[:margin_y, :] = True
    edge_mask[h - margin_y:, :] = True
    edge_mask[:, :margin_x] = True
    edge_mask[:, w - margin_x:] = True

    # Find visible pixels in the edge margin
    visible = arr[:, :, 3] > 0
    edge_visible = visible & edge_mask

    if not np.any(edge_visible):
        return arr, 0

    # For each connected component in the edge region, check if it connects to
    # the interior. If not, it's an isolated border artifact — remove it.
    # Use BFS from each edge pixel to see if it reaches a non-edge pixel
    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
    components = []

    ys, xs = np.where(edge_visible)
    for i in range(len(ys)):
        y, x = ys[i], xs[i]
        if labels[y, x] > 0:
            continue
        label_id += 1
        component_pixels = []
        reaches_interior = False
        queue = deque([(y, x)])
        labels[y, x] = label_id

        while queue:
            cy, cx = queue.popleft()
            component_pixels.append((cy, cx))
            if not edge_mask[cy, cx]:
                reaches_interior = True
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dy == 0 and dx == 0:
                        continue
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h and 0 <= nx < w and visible[ny, nx] and labels[ny, nx] == 0:
                        labels[ny, nx] = label_id
                        queue.append((ny, nx))

        components.append((component_pixels, reaches_interior))

    # Remove edge components that don't connect to interior
    removed = 0
    for pixels, reaches_interior in components:
        if not reaches_interior:
            for y, x in pixels:
                arr[y, x, 3] = 0
            removed += len(pixels)

    return arr, removed


def remove_dash_segments(arr, max_area=100, min_aspect=1.0, max_fill=0.45):
    """Remove thin elongated dashed-line clusters that form bounding box artifacts.

    These are small connected components with high aspect ratio and low fill,
    characteristic of dashed rectangular borders drawn around AI-generated subjects.
    """
    h, w = arr.shape[:2]
    alpha = arr[:, :, 3] > 0

    if not np.any(alpha):
        return arr, 0

    # Find connected components
    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
    to_remove = []

    # Find the largest component (main content body) first — never remove it
    all_components = []

    for y in range(h):
        for x in range(w):
            if alpha[y, x] and labels[y, x] == 0:
                label_id += 1
                pixels = []
                min_y = max_y = y
                min_x = max_x = x
                queue = deque([(y, x)])
                labels[y, x] = label_id
                while queue:
                    cy, cx = queue.popleft()
                    pixels.append((cy, cx))
                    min_y = min(min_y, cy)
                    max_y = max(max_y, cy)
                    min_x = min(min_x, cx)
                    max_x = max(max_x, cx)
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            if dy == 0 and dx == 0:
                                continue
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and labels[ny, nx] == 0:
                                labels[ny, nx] = label_id
                                queue.append((ny, nx))

                bbox_h = max_y - min_y + 1
                bbox_w = max_x - min_x + 1
                area = len(pixels)
                all_components.append((label_id, area, bbox_h, bbox_w, pixels))

    if not all_components:
        return arr, 0

    # Find max area (main body) — never remove it
    max_component_area = max(c[1] for c in all_components)

    removed = 0
    for lid, area, bbox_h, bbox_w, pixels in all_components:
        if area == max_component_area:
            continue  # Never remove the main body
        if area > max_area:
            continue  # Too large to be a border dash

        aspect = max(bbox_w, bbox_h) / max(min(bbox_w, bbox_h), 1)
        fill = area / max(bbox_h * bbox_w, 1)

        # Thin elongated dash segment with low fill = border artifact
        if aspect >= min_aspect and fill <= max_fill:
            for py, px in pixels:
                arr[py, px, 3] = 0
            removed += area

    return arr, removed


def process_frame(frame_path, dry_run=False):
    """Process a single frame."""
    img = Image.open(frame_path).convert("RGBA")
    arr = np.array(img)
    original_visible = int(np.sum(arr[:, :, 3] > 0))

    if original_visible == 0:
        return [], 0, 0

    steps = []

    # Step 1: Remove dark border lines at image edges
    arr, line_count = remove_border_lines(arr)
    if line_count > 0:
        steps.append(f"lines:-{line_count}")

    # Step 2: Remove edge margin strays disconnected from main content
    arr, stray_count = remove_edge_margin_strays(arr)
    if stray_count > 0:
        steps.append(f"edge-strays:-{stray_count}")

    # Step 3: Remove thin dashed-line border segments around figures
    arr, dash_count = remove_dash_segments(arr)
    if dash_count > 0:
        steps.append(f"dashes:-{dash_count}")

    final_visible = int(np.sum(arr[:, :, 3] > 0))

    if not dry_run and steps:
        out_img = Image.fromarray(arr, "RGBA")
        out_img.save(frame_path)

    return steps, original_visible, final_visible


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("DRY RUN MODE - no files will be modified\n")

    vfx_dirs = sorted([d for d in os.listdir(VFX_BASE)
                       if os.path.isdir(os.path.join(VFX_BASE, d))])

    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    if args:
        vfx_dirs = args

    total_fixed = 0
    for vfx_name in vfx_dirs:
        vfx_dir = os.path.join(VFX_BASE, vfx_name)
        frames = sorted([f for f in os.listdir(vfx_dir)
                         if f.startswith("frame_") and f.endswith(".png")])

        print(f"\n{vfx_name}/")
        for fname in frames:
            fpath = os.path.join(vfx_dir, fname)
            steps, orig, final = process_frame(fpath, dry_run)
            if steps:
                total_fixed += 1
                status = " (dry)" if dry_run else " OK"
                print(f"  {fname}: {' | '.join(steps)} [{orig}→{final}]{status}")

    print(f"\nDone! Fixed {total_fixed} frames.")


if __name__ == "__main__":
    main()
