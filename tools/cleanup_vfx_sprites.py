#!/usr/bin/env python3
"""
VFX Sprite Cleanup Tool
=======================
Cleans up AI-generated VFX sprites by:
1. Removing opaque backgrounds (gray + magenta fill)
2. Recoloring magenta/pink pixels to intended VFX colors
3. Removing stray isolated pixel clusters
4. Cleaning fringing/halo artifacts
"""

import os
import sys
from PIL import Image
import numpy as np
from collections import deque

VFX_BASE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "assets", "sprites", "battle", "frames", "vfx")

# Target color palettes for each VFX type
# Hue: 0=red, 30=orange, 60=yellow, 120=green, 180=cyan, 240=blue, 270=purple
VFX_COLOR_MAP = {
    "aura_buff":      {"hue": 45,  "sat_scale": 1.1, "desc": "golden yellow glow"},
    "eruption":       {"hue": 15,  "sat_scale": 1.2, "desc": "orange-red fire"},
    "heal_shimmer":   {"hue": 140, "sat_scale": 0.8, "desc": "green healing"},
    "impact_burst":   {"hue": 50,  "sat_scale": 0.5, "desc": "white-yellow flash"},
    "parry_spark":    {"hue": 50,  "sat_scale": 0.3, "desc": "white-silver spark"},
    "proj_orb":       {"hue": 40,  "sat_scale": 1.0, "desc": "yellow-orange orb"},
    "proj_shard":     {"hue": 195, "sat_scale": 1.0, "desc": "ice blue shard"},
    "slash_arc":      {"hue": 210, "sat_scale": 0.3, "desc": "white-silver slash"},
    "summon_beast":   {"hue": 25,  "sat_scale": 1.1, "desc": "amber energy beast"},
    "summon_serpent":  {"hue": 165, "sat_scale": 0.9, "desc": "teal-green serpent"},
    "summon_winged":  {"hue": 35,  "sat_scale": 1.0, "desc": "golden fire phoenix"},
    "wave_sweep":     {"hue": 210, "sat_scale": 1.0, "desc": "blue water wave"},
}

MIN_CLUSTER_SIZE = 8
FRINGE_ALPHA_MAX = 30
MAGENTA_BG_THRESHOLD = 0.70  # If >70% of visible pixels are magenta after bg removal, treat as bg


def vectorized_rgb_to_hsv(rgb):
    """Vectorized RGB (0-255) to HSV (H: 0-360, S: 0-1, V: 0-1)."""
    r, g, b = rgb[:, :, 0] / 255.0, rgb[:, :, 1] / 255.0, rgb[:, :, 2] / 255.0

    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    diff = mx - mn

    h = np.zeros_like(mx)
    # Where max == r
    mask_r = (mx == r) & (diff > 0)
    h[mask_r] = (60 * ((g[mask_r] - b[mask_r]) / diff[mask_r]) + 360) % 360
    # Where max == g
    mask_g = (mx == g) & (diff > 0) & ~mask_r
    h[mask_g] = (60 * ((b[mask_g] - r[mask_g]) / diff[mask_g]) + 120) % 360
    # Where max == b
    mask_b = (mx == b) & (diff > 0) & ~mask_r & ~mask_g
    h[mask_b] = (60 * ((r[mask_b] - g[mask_b]) / diff[mask_b]) + 240) % 360

    s = np.where(mx > 0, diff / mx, 0)
    v = mx

    return h, s, v


def vectorized_hsv_to_rgb(h, s, v):
    """Vectorized HSV to RGB (0-255)."""
    h = h % 360
    c = v * s
    x = c * (1 - np.abs((h / 60) % 2 - 1))
    m = v - c

    r = np.zeros_like(h)
    g = np.zeros_like(h)
    b = np.zeros_like(h)

    # h < 60
    mask = h < 60
    r[mask], g[mask], b[mask] = c[mask], x[mask], 0
    # 60 <= h < 120
    mask = (h >= 60) & (h < 120)
    r[mask], g[mask], b[mask] = x[mask], c[mask], 0
    # 120 <= h < 180
    mask = (h >= 120) & (h < 180)
    r[mask], g[mask], b[mask] = 0, c[mask], x[mask]
    # 180 <= h < 240
    mask = (h >= 180) & (h < 240)
    r[mask], g[mask], b[mask] = 0, x[mask], c[mask]
    # 240 <= h < 300
    mask = (h >= 240) & (h < 300)
    r[mask], g[mask], b[mask] = x[mask], 0, c[mask]
    # 300 <= h < 360
    mask = h >= 300
    r[mask], g[mask], b[mask] = c[mask], 0, x[mask]

    rgb = np.stack([
        np.clip((r + m) * 255, 0, 255).astype(np.uint8),
        np.clip((g + m) * 255, 0, 255).astype(np.uint8),
        np.clip((b + m) * 255, 0, 255).astype(np.uint8),
    ], axis=-1)

    return rgb


def get_magenta_mask(arr):
    """Get a boolean mask of magenta/pink pixels. Works on RGBA arrays."""
    h, s, v = vectorized_rgb_to_hsv(arr[:, :, :3])
    visible = arr[:, :, 3] > 0
    # Saturated magenta/pink: hue 260-360 or 0-10
    saturated_magenta = (s > 0.1) & (((h >= 260) & (h <= 360)) | ((h >= 0) & (h < 10) & (s > 0.15)))
    # Desaturated pink/warm tint: very low saturation near-white with pink or warm cast
    # Catches (255,233,255) magenta-cast AND (255,244,244) warm-cast whites
    r, g, b = arr[:, :, 0].astype(float), arr[:, :, 1].astype(float), arr[:, :, 2].astype(float)
    desaturated_pink = (s > 0.03) & (s <= 0.12) & (r > g) & (v > 0.7) & ((h >= 270) | (h < 20))
    return visible & (saturated_magenta | desaturated_pink)


def detect_and_remove_background(arr):
    """Remove opaque backgrounds (both gray and magenta fill layers)."""
    h, w = arr.shape[:2]
    steps = []

    # Check corners for opaque background
    corners = [arr[0:10, 0:10], arr[0:10, w-10:w], arr[h-10:h, 0:10], arr[h-10:h, w-10:w]]
    has_opaque_bg = all(np.mean(c[:, :, 3]) > 200 for c in corners)

    if has_opaque_bg:
        # Find dominant edge color
        edge_pixels = np.concatenate([
            arr[0, :, :3].reshape(-1, 3),
            arr[-1, :, :3].reshape(-1, 3),
            arr[:, 0, :3].reshape(-1, 3),
            arr[:, -1, :3].reshape(-1, 3),
        ]).astype(float)
        bg_color = np.median(edge_pixels, axis=0)

        # Remove pixels close to bg color
        rgb = arr[:, :, :3].astype(float)
        diff = np.sqrt(np.sum((rgb - bg_color) ** 2, axis=2))
        bg_mask = diff < 45
        arr[bg_mask, 3] = 0
        steps.append(f"bg1({int(bg_color[0])},{int(bg_color[1])},{int(bg_color[2])})")

    # Only check for magenta secondary bg if we already found an opaque primary bg
    # (If no primary bg was found, the image already had transparency and
    #  magenta pixels are likely the actual effect content, not background)
    if has_opaque_bg:
        visible = arr[:, :, 3] > 0
        total_visible = np.sum(visible)
        if total_visible > 100:
            magenta_mask = get_magenta_mask(arr)
            magenta_count = np.sum(magenta_mask)
            magenta_ratio = magenta_count / total_visible

            if magenta_ratio > MAGENTA_BG_THRESHOLD:
                arr[magenta_mask, 3] = 0
                steps.append(f"bg2(magenta {magenta_ratio:.0%})")

    return arr, steps


def recolor_magenta(arr, target_hue, sat_scale):
    """Recolor magenta/pink pixels to target hue, vectorized."""
    magenta_mask = get_magenta_mask(arr)
    count = np.sum(magenta_mask)

    if count == 0:
        return arr, 0

    h, s, v = vectorized_rgb_to_hsv(arr[:, :, :3])

    # Remap hue and adjust saturation for magenta pixels
    h[magenta_mask] = target_hue
    s[magenta_mask] = np.clip(s[magenta_mask] * sat_scale, 0, 1)

    # Convert back to RGB
    new_rgb = vectorized_hsv_to_rgb(h, s, v)

    # Only update magenta pixels
    arr[:, :, 0][magenta_mask] = new_rgb[:, :, 0][magenta_mask]
    arr[:, :, 1][magenta_mask] = new_rgb[:, :, 1][magenta_mask]
    arr[:, :, 2][magenta_mask] = new_rgb[:, :, 2][magenta_mask]

    return arr, count


def remove_fringing(arr):
    """Remove semi-transparent fringe pixels."""
    mask = (arr[:, :, 3] > 0) & (arr[:, :, 3] < FRINGE_ALPHA_MAX)
    count = np.sum(mask)
    arr[mask, 3] = 0
    return arr, count


def connected_components_label(alpha_bool):
    """Label connected components using BFS flood fill (8-connectivity)."""
    h, w = alpha_bool.shape
    labels = np.zeros((h, w), dtype=np.int32)
    label_id = 0
    sizes = []

    for y in range(h):
        for x in range(w):
            if alpha_bool[y, x] and labels[y, x] == 0:
                label_id += 1
                size = 0
                queue = deque([(y, x)])
                labels[y, x] = label_id
                while queue:
                    cy, cx = queue.popleft()
                    size += 1
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            if dy == 0 and dx == 0:
                                continue
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and alpha_bool[ny, nx] and labels[ny, nx] == 0:
                                labels[ny, nx] = label_id
                                queue.append((ny, nx))
                sizes.append(size)

    return labels, sizes


def remove_stray_pixels(arr, min_size=MIN_CLUSTER_SIZE):
    """Remove small isolated pixel clusters."""
    alpha_bool = arr[:, :, 3] > 0

    if not np.any(alpha_bool):
        return arr, 0

    labels, sizes = connected_components_label(alpha_bool)

    removed = 0
    for i, size in enumerate(sizes):
        if size < min_size:
            mask = labels == (i + 1)
            arr[mask, 3] = 0
            removed += size

    return arr, removed


def process_frame(frame_path, target_hue, sat_scale, dry_run=False):
    """Process a single frame image."""
    img = Image.open(frame_path).convert("RGBA")
    arr = np.array(img)
    original_visible = int(np.sum(arr[:, :, 3] > 0))
    steps = []

    # Step 1: Background removal (gray + magenta fill)
    arr, bg_steps = detect_and_remove_background(arr)
    steps.extend(bg_steps)

    # Step 2: Remove fringing
    arr, fringe_count = remove_fringing(arr)
    if fringe_count > 0:
        steps.append(f"fringe:-{fringe_count}")

    # Step 3: Recolor remaining magenta/pink pixels to target color
    arr, recolor_count = recolor_magenta(arr, target_hue, sat_scale)
    if recolor_count > 0:
        steps.append(f"recolor:{recolor_count}→h{target_hue}")

    # Step 4: Remove stray pixel clusters
    arr, stray_count = remove_stray_pixels(arr)
    if stray_count > 0:
        steps.append(f"stray:-{stray_count}")

    final_visible = int(np.sum(arr[:, :, 3] > 0))

    if not dry_run:
        out_img = Image.fromarray(arr, "RGBA")
        out_img.save(frame_path)

    return steps, original_visible, final_visible


def process_vfx_directory(vfx_name, dry_run=False):
    """Process all frames in a VFX directory."""
    vfx_dir = os.path.join(VFX_BASE, vfx_name)
    if not os.path.isdir(vfx_dir):
        print(f"  SKIP: directory not found")
        return

    config = VFX_COLOR_MAP.get(vfx_name)
    if not config:
        print(f"  SKIP: no color config")
        return

    frames = sorted([f for f in os.listdir(vfx_dir) if f.startswith("frame_") and f.endswith(".png")])
    print(f"\n{'='*60}")
    print(f"{vfx_name} ({len(frames)} frames) → {config['desc']}")
    print(f"{'='*60}")

    for frame_name in frames:
        frame_path = os.path.join(vfx_dir, frame_name)
        steps, orig, final = process_frame(frame_path, config["hue"], config["sat_scale"], dry_run)
        status = " (dry)" if dry_run else " OK"
        print(f"  {frame_name}: {' | '.join(steps) if steps else 'clean'} [{orig}→{final}]{status}")


def main():
    dry_run = "--dry-run" in sys.argv
    if dry_run:
        print("DRY RUN MODE - no files will be modified\n")

    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    vfx_dirs = args if args else sorted(VFX_COLOR_MAP.keys())

    for vfx_name in vfx_dirs:
        process_vfx_directory(vfx_name, dry_run=dry_run)

    print(f"\nDone! Processed {len(vfx_dirs)} VFX sets.")


if __name__ == "__main__":
    main()
