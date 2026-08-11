#!/usr/bin/env python3
"""Slice ChatGPT/Aseprite character sheets from _incoming into game frames.

Usage:
  python3 scripts/slice_character_incoming.py --character pepita
  python3 scripts/slice_character_incoming.py --character abuela_rosa
  python3 scripts/slice_character_incoming.py --all
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "assets" / "images"

# Pepita uses 192px frames; plaza cast defaults to 128px (matches character.json).
CHARACTER_PROFILES: dict[str, dict[str, int | float]] = {
    "pepita": {
        "frame_size": 192,
        "baseline_y": 188,
        "max_char_w": 168,
        "max_char_h": 176,
        "min_frame_width": 60,
        "walk_fps": 10,
        "skip_fps": 12,
    },
}

DEFAULT_PROFILE: dict[str, int | float] = {
    "frame_size": 128,
    "baseline_y": 119,
    "max_char_w": 112,
    "max_char_h": 112,
    "min_frame_width": 40,
    "walk_fps": 9,
    "skip_fps": 11,
}

ALL_CHARACTERS = [
    "pepita",
    "abuela_rosa",
    "xolo",
    "gato",
    "tito",
    "miguel",
    "dona_luz",
    "chavo",
    "don_mateo",
    "pinto",
    "alebrije",
    "senor_cuervo",
]

# Pepita-specific legacy UUID mappings (other cast use {id}_walk_*.png only).
PEPITA_LEGACY_MAP: dict[str, tuple[str, str]] = {
    "24edaf07-f1a7-4e01-8820-1842ead695cd.png": ("walk_down", "grid"),
    "33e2e64d-db2e-4062-ae09-916ddcaab5a2.png": ("walk_left", "grid"),
    "79c5fa2b-2017-422c-b7ad-b26096927c35.png": ("walk_up", "grid"),
    "a656ed79-379a-4c40-8fa2-884c22bc491c.png": ("idle_down", "single"),
    "4fdbd239-dbdb-4cff-921f-05cda0d6a4c1.png": ("skip_down", "grid"),
    "c79052a7-a6bd-45e3-9e14-a9c05f479b1a.png": ("skip_left", "grid"),
    "Unknown-2.jpeg": ("skip_up", "grid"),
}


def profile_for(character_id: str) -> dict[str, int | float]:
    merged = dict(DEFAULT_PROFILE)
    merged.update(CHARACTER_PROFILES.get(character_id, {}))
    return merged


def sheet_map_for(character_id: str) -> dict[str, tuple[str, str]]:
    """Friendly filenames + Pepita legacy UUIDs."""
    mapping: dict[str, tuple[str, str]] = {
        f"{character_id}_walk_down.png": ("walk_down", "grid"),
        f"{character_id}_walk_up.png": ("walk_up", "grid"),
        f"{character_id}_walk_left.png": ("walk_left", "grid"),
        f"{character_id}_walk_right.png": ("walk_right", "grid"),
        f"{character_id}_idle_down.png": ("idle_down", "single"),
        f"{character_id}_skip_down.png": ("skip_down", "grid"),
        f"{character_id}_skip_left.png": ("skip_left", "grid"),
        f"{character_id}_skip_up.png": ("skip_up", "grid"),
    }
    if character_id == "pepita":
        mapping.update(
            {
                "pepita_walk_down.png": ("walk_down", "grid"),
                "pepita_walk_up.png": ("walk_up", "grid"),
                "pepita_walk_left.png": ("walk_left", "grid"),
                "pepita_walk_right.png": ("walk_right", "grid"),
                "pepita_idle_down.png": ("idle_down", "single"),
                **PEPITA_LEGACY_MAP,
            }
        )
    return mapping


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def strip_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                continue
            high = min(red, green, blue) >= 200
            low_chroma = max(red, green, blue) - min(red, green, blue) <= 28
            if high and low_chroma:
                pixels[x, y] = (red, green, blue, 0)
                continue
            if max(red, green, blue) <= 28 and low_chroma:
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def alpha_bbox(image: Image.Image, threshold: int = 12) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox()


def grid_frames(image: Image.Image, *, columns: int = 4, rows: int = 2) -> list[Image.Image]:
    width, height = image.size
    frames: list[Image.Image] = []
    for row in range(rows):
        for col in range(columns):
            left = round(col * width / columns)
            top = round(row * height / rows)
            right = round((col + 1) * width / columns)
            bottom = round((row + 1) * height / rows)
            frames.append(image.crop((left, top, right, bottom)))
    return frames


def frame_content_width(frame: Image.Image) -> int:
    bbox = alpha_bbox(frame)
    if bbox is None:
        return 0
    return bbox[2] - bbox[0]


def normalize_frame(
    image: Image.Image,
    *,
    profile: dict[str, int | float],
    mirror: bool = False,
) -> Image.Image:
    frame_size = int(profile["frame_size"])
    baseline_y = int(profile["baseline_y"])
    max_w = int(profile["max_char_w"])
    max_h = int(profile["max_char_h"])

    crop = strip_background(image)
    bbox = alpha_bbox(crop)
    if bbox is None:
        raise ValueError("empty frame after background strip")

    character = crop.crop(bbox)
    if mirror:
        character = ImageOps.mirror(character)

    scale = min(max_w / character.width, max_h / character.height)
    resized = (
        round(max(1, character.width * scale)),
        round(max(1, character.height * scale)),
    )
    character = character.resize(resized, Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
    x = (frame_size - character.width) // 2
    y = baseline_y - character.height
    frame.alpha_composite(character, (x, y))
    return frame


def export_animation(
    character_id: str,
    animation: str,
    frames: list[Image.Image],
    *,
    profile: dict[str, int | float],
) -> list[str]:
    state, direction = animation.split("_", 1)
    output_dir = IMAGES / character_id / state / direction
    output_dir.mkdir(parents=True, exist_ok=True)
    for existing in output_dir.glob("*.png"):
        existing.unlink()

    paths: list[str] = []
    for index, frame in enumerate(frames):
        name = f"{character_id}_{state}_{direction}_{index:02d}.png"
        frame.save(output_dir / name)
        paths.append(f"{state}/{direction}/{name}")
    return paths


def mirror_paths(
    character_id: str,
    left_paths: list[str],
    target_animation: str,
    *,
    profile: dict[str, int | float],
) -> list[str]:
    base = IMAGES / character_id
    frames = [
        normalize_frame(load_rgba(base / rel), profile=profile, mirror=True)
        for rel in left_paths
    ]
    return export_animation(character_id, target_animation, frames, profile=profile)


def animation_entry(paths: list[str], *, fps: float, loop: bool = True) -> dict[str, object]:
    return {
        "frames": len(paths),
        "fps": fps,
        "loop": loop,
        "paths": paths,
    }


def dedupe_grid_frames(frames: list[Image.Image]) -> list[Image.Image]:
    if len(frames) != 8:
        return frames
    import hashlib

    def digest(img: Image.Image) -> str:
        return hashlib.md5(img.tobytes()).hexdigest()

    top = [digest(f) for f in frames[:4]]
    bottom = [digest(f) for f in frames[4:]]
    if top == bottom:
        print("  note: bottom row duplicates top — using 4 unique frames")
        return frames[:4]
    return frames


def slice_character(character_id: str) -> dict[str, list[str]]:
    profile = profile_for(character_id)
    incoming = IMAGES / character_id / "_incoming"
    config_path = IMAGES / character_id / "character.json"
    sheet_map = sheet_map_for(character_id)
    min_width = int(profile["min_frame_width"])
    exports: dict[str, list[str]] = {}

    if not incoming.is_dir():
        print(f"skip {character_id}: no _incoming folder")
        return exports

    for filename, (animation, mode) in sheet_map.items():
        source = incoming / filename
        if not source.exists():
            continue
        sheet = strip_background(load_rgba(source))

        if mode == "single":
            normalized = [normalize_frame(sheet, profile=profile)]
        else:
            raw_frames = dedupe_grid_frames(grid_frames(sheet))
            normalized = []
            for index, frame in enumerate(raw_frames):
                candidate = normalize_frame(frame, profile=profile)
                width = frame_content_width(candidate)
                if width < min_width:
                    print(
                        f"REJECTED {character_id}/{filename} frame {index:02d} "
                        f"for {animation}: content width {width}px < {min_width}px"
                    )
                    continue
                normalized.append(candidate)

        if not normalized:
            print(f"FAIL {character_id}/{filename}: no valid frames")
            continue

        target = animation.removesuffix("_alt")
        paths = export_animation(character_id, target, normalized, profile=profile)
        exports[target] = paths
        print(f"{character_id}: {filename} -> {target} ({len(paths)} frames)")

    if "walk_left" in exports and "walk_right" not in exports:
        exports["walk_right"] = mirror_paths(
            character_id, exports["walk_left"], "walk_right", profile=profile
        )

    if "skip_left" in exports and "skip_right" not in exports:
        exports["skip_right"] = mirror_paths(
            character_id, exports["skip_left"], "skip_right", profile=profile
        )

    idle_down_paths = exports.get("idle_down", [])
    if idle_down_paths:
        idle0 = load_rgba(IMAGES / character_id / idle_down_paths[0])
        exports["idle_up"] = export_animation(
            character_id, "idle_up", [normalize_frame(idle0, profile=profile)], profile=profile
        )
        exports["idle_left"] = export_animation(
            character_id,
            "idle_left",
            [normalize_frame(idle0, profile=profile, mirror=True)],
            profile=profile,
        )
        exports["idle_right"] = export_animation(
            character_id, "idle_right", [normalize_frame(idle0, profile=profile)], profile=profile
        )

    if not exports:
        return exports

    if config_path.exists():
        config = json.loads(config_path.read_text())
    else:
        display = character_id.replace("_", " ").title()
        config = {
            "schemaVersion": 1,
            "id": character_id,
            "displayName": display,
            "role": "plaza_resident",
            "defaultDirection": "down",
            "movement": {"walkSpeed": 50, "skipSpeed": 65},
            "personality": {
                "decisionIntervalMs": [1500, 4500],
                "autonomousBehaviours": [
                    {"action": "idle", "weight": 0.45},
                    {"action": "walk", "weight": 0.55},
                ],
            },
            "animations": {},
        }

    animations: dict[str, object] = config.setdefault("animations", {})  # type: ignore[assignment]

    if any(key.startswith("walk_") for key in exports):
        movement = config.setdefault("movement", {})
        movement["walkTwoFrameFallback"] = False

    walk_fps = float(profile["walk_fps"])
    skip_fps = float(profile["skip_fps"])

    for name, paths in exports.items():
        if name.startswith("walk_"):
            animations[name] = animation_entry(paths, fps=walk_fps)
        elif name.startswith("skip_"):
            animations[name] = animation_entry(paths, fps=skip_fps)
        elif name.startswith("idle_"):
            fps = 6 if len(paths) > 1 else 1
            animations[name] = animation_entry(paths, fps=fps)

    config["frameWidth"] = int(profile["frame_size"])
    config["frameHeight"] = int(profile["frame_size"])
    visual_ref = config.setdefault("visualReference", {})
    if isinstance(visual_ref, dict):
        visual_ref["baselineY"] = int(profile["baseline_y"])
        visual_ref["status"] = "incoming-sheets-v2"

    config_path.write_text(json.dumps(config, indent=2) + "\n")
    print(json.dumps({"character": character_id, "exported": list(exports.keys())}, indent=2))
    return exports


def main() -> None:
    parser = argparse.ArgumentParser(description="Slice character _incoming art sheets")
    parser.add_argument(
        "--character",
        "-c",
        choices=ALL_CHARACTERS,
        help="Character folder under assets/images/",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Slice every character that has files in _incoming",
    )
    args = parser.parse_args()

    if args.all:
        for character_id in ALL_CHARACTERS:
            slice_character(character_id)
        return

    character_id = args.character or "pepita"
    slice_character(character_id)


if __name__ == "__main__":
    main()
