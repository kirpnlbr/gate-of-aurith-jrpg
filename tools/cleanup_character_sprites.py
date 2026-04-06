#!/usr/bin/env python3
"""
Character Sprite Cleanup Tool
==============================
Cleans up AI-generated character sprites by:
1. Removing magenta/pink artifact pixels (NOT recoloring — these are overlays, not content)
2. Removing dashed border lines at image edges
3. Removing thin dash segments (bounding box artifacts)
4. Removing fringing/halo pixels
5. Removing stray isolated pixel clusters
"""

import os
import sys
from PIL import Image
import numpy as np
from collections import deque

FRAMES_BASE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "assets", "sprites", "battle", "frames")

# All party member sprite directories
PARTY_SPRITE_DIRS = [
    # Gustave
    "gustave_idle", "gustave_idle_alt", "gustave_attack", "gustave_heavy_slash",
    "gustave_whirlwind", "gustave_taunt", "gustave_stance_switch",
    "gustave_stance_switch_back", "gustave_counter", "gustave_counter_alt",
    "gustave_parry", "gustave_parry_alt", "gustave_aegis_beam", "gustave_bulwark",
    # Mage
    "mage_idle", "mage_attack", "mage_counter", "mage_parry",
    "mage_fireball", "mage_ice_lance", "mage_inferno", "mage_lava_burst",
    "mage_thunder", "mage_tidal_wave",
    # Sage
    "sage_idle", "sage_attack", "sage_counter", "sage_parry", "sage_buff",
    "sage_basilisk", "sage_leviathan", "sage_phoenix", "sage_thunderbird",
]

FRINGE_ALPHA_MAX = 30
MIN_CLUSTER_SIZE = 6


def vectorized_rgb_to_hsv(rgb):
    """Vectorized RGB (0-255) to HSV (H: 0-360, S: 0-1, V: 0-1)."""
    r, g, b = rgb[:, :, 0] / 255.0, rgb[:, :, 1] / 255.0, rgb[:, :, 2] / 255.0
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    diff = mx - mn

    h = np.zeros_like(mx)
    mask_r = (mx == r) & (diff > 0)
    h[mask_r] = (60 * ((g[mask_r] - b[mask_r]) / diff[mask_r]) + 360) % 360
    mask_g = (mx == g) & (diff > 0) & ~mask_r
    h[mask_g] = (60 * ((b[mask_g] - r[mask_g]) / diff[mask_g]) + 120) % 360
    mask_b = (mx == b) & (diff > 0) & ~mask_r & ~mask_g
    h[mask_b] = (60 * ((r[mask_b] - g[mask_b]) / diff[mask_b]) + 240) % 360

    s = np.where(mx > 0, diff / mx, 0)
    return h, s, mx


def get_magenta_mask(arr):
    """Get mask of clearly magenta/pink artifact pixels.

    Conservative threshold for character sprites — only catches pixels that
    are clearly in the magenta hue range and cannot be natural character colors
    (skin, armor, clothing).
    """
    h, s, v = vectorized_rgb_to_hsv(arr[:, :, :3])
    visible = arr[:, :, 3] > 0

    # Saturated magenta: hue 280-340 with meaningful saturation
    # Wider range catches pink-magenta but avoids red (0) and blue (240)
    saturated_magenta = visible & (s > 0.15) & (h >= 280) & (h <= 340)

    # Very saturated broad pink-magenta: hue 260-360 with high saturation
    # This catches the intense magenta artifacts
    intense_magenta = visible & (s > 0.35) & (((h >= 260) & (h <= 360)) | ((h < 10) & (s > 0.4)))

    return saturated_magenta | intense_magenta


def get_strict_magenta_mask(arr):
    """Strict magenta mask matching the runtime shader threshold.
    Only pure magenta: R>217, G<51, B>217."""
    visible = arr[:, :, 3] > 0
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    return visible & (r > 217) & (g < 51) & (b > 217)


def remove_magenta_pixels(arr):
    """Remove magenta/pink artifact pixels by setting alpha to 0.

    Uses adaptive thresholds: if magenta is >25% of visible pixels (meaning
    the frame has intentional magenta VFX baked in), use strict shader-matching
    threshold only. Otherwise use broader detection.
    """
    visible = arr[:, :, 3] > 0
    total_visible = int(np.sum(visible))
    if total_visible == 0:
        return arr, 0

    # First check how much magenta there is with broad detection
    broad_mask = get_magenta_mask(arr)
    broad_count = int(np.sum(broad_mask))
    broad_ratio = broad_count / total_visible

    if broad_ratio > 0.25:
        # Heavy magenta = intentional VFX in the sprite. Only remove the
        # strictest magenta (matching the runtime shader) to clean artifacts
        # without destroying the intended effect.
        mask = get_strict_magenta_mask(arr)
    else:
        # Light magenta = artifacts only. Safe to use broader detection.
        mask = broad_mask

    count = int(np.sum(mask))
    arr[mask, 3] = 0
    return arr, count


def remove_fringing(arr):
    """Remove semi-transparent fringe pixels."""
    mask = (arr[:, :, 3] > 0) & (arr[:, :, 3] < FRINGE_ALPHA_MAX)
    count = int(np.sum(mask))
    arr[mask, 3] = 0
    return arr, count


def get_margin(img_size):
    return max(15, img_size // 25)


def remove_border_lines(arr):
    """Remove dark border lines near image edges."""
    h, w = arr.shape[:2]
    margin_y, margin_x = get_margin(h), get_margin(w)
    removed = 0

    for row in list(range(margin_y)) + list(range(h - margin_y, h)):
        visible_cols = np.where(arr[row, :, 3] > 0)[0]
        if len(visible_cols) < 2:
            continue
        span = visible_cols[-1] - visible_cols[0] + 1
        if span > w * 0.4:
            colors = arr[row, visible_cols, :3]
            avg_brightness = np.mean(colors.astype(int).sum(axis=1))
            dark_ratio = np.sum(colors.astype(int).sum(axis=1) < 100) / len(visible_cols)
            if avg_brightness < 150 or dark_ratio > 0.5:
                removed += len(visible_cols)
                arr[row, :, 3] = 0

    for col in list(range(margin_x)) + list(range(w - margin_x, w)):
        visible_rows = np.where(arr[:, col, 3] > 0)[0]
        if len(visible_rows) < 2:
            continue
        span = visible_rows[-1] - visible_rows[0] + 1
        if span > h * 0.4:
            colors = arr[visible_rows, col, :3]
            avg_brightness = np.mean(colors.astype(int).sum(axis=1))
            dark_ratio = np.sum(colors.astype(int).sum(axis=1) < 100) / len(visible_rows)
            if avg_brightness < 150 or dark_ratio > 0.5:
                removed += len(visible_rows)
                arr[:, col, 3] = 0

    return arr, removed


def remove_edge_strays(arr):
    """Remove pixel groups in edge margins disconnected from main content."""
    h, w = arr.shape[:2]
    margin_y, margin_x = get_margin(h), get_margin(w)

    edge_mask = np.zeros((h, w), dtype=bool)
    edge_mask[:margin_y, :] = True
    edge_mask[h - margin_y:, :] = True
    edge_mask[:, :margin_x] = True
    edge_mask[:, w - margin_x:] = True

    visible = arr[:, :, 3] > 0
    edge_visible = visible & edge_mask
    if not np.any(edge_visible):
        return arr, 0

    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
    components = []

    ys, xs = np.where(edge_visible)
    for i in range(len(ys)):
        y, x = int(ys[i]), int(xs[i])
        if labels[y, x] > 0:
            continue
        label_id += 1
        pixels = []
        reaches_interior = False
        queue = deque([(y, x)])
        labels[y, x] = label_id
        while queue:
            cy, cx = queue.popleft()
            pixels.append((cy, cx))
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
        components.append((pixels, reaches_interior))

    removed = 0
    for pixels, reaches_interior in components:
        if not reaches_interior:
            for py, px in pixels:
                arr[py, px, 3] = 0
            removed += len(pixels)
    return arr, removed


def remove_dash_segments(arr, max_area=100, max_fill=0.45):
    """Remove thin/sparse dash segments (bounding box border artifacts)."""
    h, w = arr.shape[:2]
    alpha = arr[:, :, 3] > 0
    if not np.any(alpha):
        return arr, 0

    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
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
                    min_y, max_y = min(min_y, cy), max(max_y, cy)
                    min_x, max_x = min(min_x, cx), max(max_x, cx)
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
                all_components.append((len(pixels), bbox_h, bbox_w, pixels))

    if not all_components:
        return arr, 0

    max_component_area = max(c[0] for c in all_components)
    removed = 0
    for area, bbox_h, bbox_w, pixels in all_components:
        if area == max_component_area or area > max_area:
            continue
        fill = area / max(bbox_h * bbox_w, 1)
        if fill <= max_fill:
            for py, px in pixels:
                arr[py, px, 3] = 0
            removed += area

    return arr, removed


def remove_stray_pixels(arr, min_size=MIN_CLUSTER_SIZE):
    """Remove small isolated pixel clusters."""
    alpha = arr[:, :, 3] > 0
    if not np.any(alpha):
        return arr, 0

    h, w = arr.shape[:2]
    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
    removed = 0

    for y in range(h):
        for x in range(w):
            if alpha[y, x] and labels[y, x] == 0:
                label_id += 1
                pixels = []
                queue = deque([(y, x)])
                labels[y, x] = label_id
                while queue:
                    cy, cx = queue.popleft()
                    pixels.append((cy, cx))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            if dy == 0 and dx == 0:
                                continue
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and labels[ny, nx] == 0:
                                labels[ny, nx] = label_id
                                queue.append((ny, nx))
                if len(pixels) < min_size:
                    for py, px in pixels:
                        arr[py, px, 3] = 0
                    removed += len(pixels)

    return arr, removed


def process_frame(frame_path, dry_run=False):
    """Process a single character sprite frame."""
    img = Image.open(frame_path).convert("RGBA")
    arr = np.array(img)
    original_visible = int(np.sum(arr[:, :, 3] > 0))
    if original_visible == 0:
        return [], 0, 0

    steps = []

    # Step 1: Remove magenta/pink artifacts
    arr, mag_count = remove_magenta_pixels(arr)
    if mag_count > 0:
        steps.append(f"magenta:-{mag_count}")

    # Step 2: Remove fringing
    arr, fringe_count = remove_fringing(arr)
    if fringe_count > 0:
        steps.append(f"fringe:-{fringe_count}")

    # Step 3: Remove dark border lines
    arr, line_count = remove_border_lines(arr)
    if line_count > 0:
        steps.append(f"lines:-{line_count}")

    # Step 4: Remove edge margin strays
    arr, edge_count = remove_edge_strays(arr)
    if edge_count > 0:
        steps.append(f"edge:-{edge_count}")

    # Step 5: Remove dash segments
    arr, dash_count = remove_dash_segments(arr)
    if dash_count > 0:
        steps.append(f"dashes:-{dash_count}")

    # Step 6: Remove stray pixel clusters
    arr, stray_count = remove_stray_pixels(arr)
    if stray_count > 0:
        steps.append(f"stray:-{stray_count}")

    final_visible = int(np.sum(arr[:, :, 3] > 0))

    if not dry_run and steps:
        out_img = Image.fromarray(arr, "RGBA")
        out_img.save(frame_path)

    return steps, original_visible, final_visible


def process_directory(sprite_name, dry_run=False):
    """Process all frames in a sprite directory."""
    sprite_dir = os.path.join(FRAMES_BASE, sprite_name)
    if not os.path.isdir(sprite_dir):
        return

    frames = sorted([f for f in os.listdir(sprite_dir)
                     if f.startswith("frame_") and f.endswith(".png")])

    any_changes = False
    for fname in frames:
        fpath = os.path.join(sprite_dir, fname)
        steps, orig, final = process_frame(fpath, dry_run)
        if steps:
            any_changes = True
            status = " (dry)" if dry_run else " OK"
            print(f"  {fname}: {' | '.join(steps)} [{orig}→{final}]{status}")

    if not any_changes:
        print(f"  (clean)")


def main():
    dry_run = "--dry-run" in sys.argv
    if dry_run:
        print("DRY RUN MODE\n")

    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    dirs = args if args else PARTY_SPRITE_DIRS

    for name in dirs:
        print(f"\n{name}/")
        process_directory(name, dry_run)

    print(f"\nDone!")


if __name__ == "__main__":
    main()
