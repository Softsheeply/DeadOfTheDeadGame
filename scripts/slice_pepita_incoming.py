#!/usr/bin/env python3
"""Slice Pepita ChatGPT/Aseprite sheets from _incoming into game frames."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
INCOMING = ROOT / "assets" / "images" / "pepita" / "_incoming"
IMAGES = ROOT / "assets" / "images" / "pepita"
CONFIG_PATH = IMAGES / "character.json"

FRAME_SIZE = 192
BASELINE_Y = 188
MAX_CHAR_W = 168
MAX_CHAR_H = 176

# Labeled source sheets → animation targets (4-dir + skip diagonals + idle breathe).
SHEET_MAP: dict[str, str] = {
    "78c4f662-4ec7-4463-b43c-aeb11f85dd88.png": "walk_down",
    "2fe8206a-cf71-46ae-a024-e16fd6e9c805.png": "walk_up",
    "a8b372d7-078e-43e0-9364-284443db83bc.png": "walk_left",
    "Unknown-1.jpeg": "walk_right",
    "a656ed79-379a-4c40-8fa2-884c22bc491c.png": "idle_down",
    "4fdbd239-dbdb-4cff-921f-05cda0d6a4c1.png": "skip_down",
    "c79052a7-a6bd-45e3-9e14-a9c05f479b1a.png": "skip_left",
    "Unknown-2.jpeg": "skip_up",
}


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


MIN_FRAME_WIDTH = 60


def frame_content_width(frame: Image.Image) -> int:
    bbox = alpha_bbox(frame)
    if bbox is None:
        return 0
    return bbox[2] - bbox[0]


def normalize_frame(image: Image.Image, *, mirror: bool = False) -> Image.Image:
    crop = strip_background(image)
    bbox = alpha_bbox(crop)
    if bbox is None:
        raise ValueError("empty frame after background strip")

    character = crop.crop(bbox)
    if mirror:
        character = ImageOps.mirror(character)

    scale = min(MAX_CHAR_W / character.width, MAX_CHAR_H / character.height)
    resized = (
        round(max(1, character.width * scale)),
        round(max(1, character.height * scale)),
    )
    character = character.resize(resized, Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = (FRAME_SIZE - character.width) // 2
    y = BASELINE_Y - character.height
    frame.alpha_composite(character, (x, y))
    return frame


def export_animation(animation: str, frames: list[Image.Image]) -> list[str]:
    state, direction = animation.split("_", 1)
    output_dir = IMAGES / state / direction
    output_dir.mkdir(parents=True, exist_ok=True)
    for existing in output_dir.glob("*.png"):
        existing.unlink()

    character_id = "pepita"
    paths: list[str] = []
    for index, frame in enumerate(frames):
        name = f"{character_id}_{state}_{direction}_{index:02d}.png"
        frame.save(output_dir / name)
        paths.append(f"{state}/{direction}/{name}")
    return paths


def mirror_paths(left_paths: list[str], target_animation: str) -> list[str]:
    frames = [
        normalize_frame(load_rgba(IMAGES / rel), mirror=True) for rel in left_paths
    ]
    return export_animation(target_animation, frames)


def animation_entry(paths: list[str], *, fps: float, loop: bool = True) -> dict[str, object]:
    return {
        "frames": len(paths),
        "fps": fps,
        "loop": loop,
        "paths": paths,
    }


def main() -> None:
    exports: dict[str, list[str]] = {}

    for filename, animation in SHEET_MAP.items():
        source = INCOMING / filename
        if not source.exists():
            print(f"skip missing {filename}")
            continue
        sheet = strip_background(load_rgba(source))
        raw_frames = grid_frames(sheet)
        normalized = [normalize_frame(frame) for frame in raw_frames]
        target = animation.removesuffix("_alt")
        paths = export_animation(target, normalized)
        exports[target] = paths
        print(f"{filename} -> {target} ({len(paths)} frames)")

    if "walk_left" in exports and "walk_right" not in exports:
        exports["walk_right"] = mirror_paths(exports["walk_left"], "walk_right")

    if "skip_left" in exports and "skip_right" not in exports:
        exports["skip_right"] = mirror_paths(exports["skip_left"], "skip_right")

    idle_down_paths = exports.get("idle_down", [])
    if idle_down_paths:
        idle0 = load_rgba(IMAGES / idle_down_paths[0])
        exports["idle_up"] = export_animation("idle_up", [normalize_frame(idle0)])
        exports["idle_left"] = export_animation(
            "idle_left",
            [normalize_frame(idle0, mirror=True)],
        )
        exports["idle_right"] = export_animation(
            "idle_right",
            [normalize_frame(idle0)],
        )

    config = json.loads(CONFIG_PATH.read_text())
    animations: dict[str, object] = config["animations"]  # type: ignore[assignment]

    for name, paths in exports.items():
        if name.startswith("walk_"):
            animations[name] = animation_entry(paths, fps=10)
        elif name.startswith("skip_"):
            animations[name] = animation_entry(paths, fps=12)
        elif name.startswith("idle_"):
            fps = 6 if len(paths) > 1 else 1
            animations[name] = animation_entry(paths, fps=fps)

    config["frameWidth"] = FRAME_SIZE
    config["frameHeight"] = FRAME_SIZE
    config["visualReference"]["baselineY"] = BASELINE_Y  # type: ignore[index]
    config["visualReference"]["status"] = "incoming-sheets-v2"  # type: ignore[index]

    CONFIG_PATH.write_text(json.dumps(config, indent=2) + "\n")
    print(json.dumps({"exported": list(exports.keys())}, indent=2))


if __name__ == "__main__":
    main()
