#!/usr/bin/env python3
"""Extract clean 128x128 Flame sprite frames from character reference sheets.

The source sheets mix transparent multi-pose art, labeled concept grids, and a
few baked checkerboard strips. This script favors a small number of clean frames
over exporting every detected pose.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "assets" / "reference" / "Characters"
IMAGES = ROOT / "assets" / "images"
FRAME_SIZE = 128
BASELINE_Y = 119


@dataclass(frozen=True)
class FrameSpec:
    source: Path
    component_indexes: tuple[int, ...] | None = None
    grid: tuple[int, int, int, int] | None = None  # columns, rows, start, count
    mirror: bool = False
    max_width: int = 112
    max_height: int = 112
    clean_light_background: bool = False


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def remove_light_background(image: Image.Image) -> Image.Image:
    """Drop baked white/light-gray checkerboard pixels while preserving art."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                continue
            high_value = min(red, green, blue) >= 218
            low_chroma = max(red, green, blue) - min(red, green, blue) <= 22
            if high_value and low_chroma:
                pixels[x, y] = (red, green, blue, 0)
    return rgba


def alpha_bbox(image: Image.Image, threshold: int = 10) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox()


def connected_component_boxes(
    image: Image.Image,
    *,
    min_pixels: int = 500,
    min_width: int = 80,
    min_height: int = 100,
) -> list[tuple[int, int, int, int]]:
    """Find alpha-connected blobs large enough to be character poses."""
    alpha = image.getchannel("A")
    width, height = alpha.size
    pixels = alpha.load()
    visited = bytearray(width * height)
    boxes: list[tuple[int, int, int, int, int]] = []

    for y in range(height):
        row_offset = y * width
        for x in range(width):
            offset = row_offset + x
            if visited[offset] or pixels[x, y] <= 10:
                continue

            stack = [(x, y)]
            visited[offset] = 1
            min_x = max_x = x
            min_y = max_y = y
            count = 0

            while stack:
                current_x, current_y = stack.pop()
                count += 1
                min_x = min(min_x, current_x)
                max_x = max(max_x, current_x)
                min_y = min(min_y, current_y)
                max_y = max(max_y, current_y)

                for next_x in (current_x - 1, current_x, current_x + 1):
                    for next_y in (current_y - 1, current_y, current_y + 1):
                        if (
                            next_x < 0
                            or next_y < 0
                            or next_x >= width
                            or next_y >= height
                        ):
                            continue
                        next_offset = next_y * width + next_x
                        if visited[next_offset] or pixels[next_x, next_y] <= 10:
                            continue
                        visited[next_offset] = 1
                        stack.append((next_x, next_y))

            box_width = max_x - min_x + 1
            box_height = max_y - min_y + 1
            if count >= min_pixels and box_width >= min_width and box_height >= min_height:
                boxes.append((min_x, min_y, max_x + 1, max_y + 1, count))

    return [
        (min_x, min_y, max_x, max_y)
        for min_x, min_y, max_x, max_y, _ in sorted(boxes, key=lambda box: (box[1], box[0]))
    ]


def grid_boxes(image: Image.Image, columns: int, rows: int) -> list[tuple[int, int, int, int]]:
    width, height = image.size
    boxes: list[tuple[int, int, int, int]] = []
    for row in range(rows):
        for column in range(columns):
            left = round(column * width / columns)
            top = round(row * height / rows)
            right = round((column + 1) * width / columns)
            bottom = round((row + 1) * height / rows)
            boxes.append((left, top, right, bottom))
    return boxes


def normalize_frame(
    image: Image.Image,
    *,
    max_width: int,
    max_height: int,
    mirror: bool = False,
) -> Image.Image:
    bbox = alpha_bbox(image)
    if bbox is None:
        raise ValueError("Cannot normalize an empty transparent frame")

    character = image.crop(bbox)
    if mirror:
        character = ImageOps.mirror(character)

    scale = min(max_width / character.width, max_height / character.height)
    resized_size = (
        max(1, round(character.width * scale)),
        max(1, round(character.height * scale)),
    )
    character = character.resize(resized_size, Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = (FRAME_SIZE - character.width) // 2
    y = BASELINE_Y - character.height
    frame.alpha_composite(character, (x, y))
    return frame


def frames_from_spec(spec: FrameSpec) -> list[Image.Image]:
    source = load_rgba(spec.source)
    if spec.clean_light_background:
        source = remove_light_background(source)

    if spec.component_indexes is not None:
        boxes = connected_component_boxes(source)
        selected_boxes = [boxes[index] for index in spec.component_indexes]
    elif spec.grid is not None:
        columns, rows, start, count = spec.grid
        selected_boxes = grid_boxes(source, columns, rows)[start : start + count]
    else:
        raise ValueError("FrameSpec must define component_indexes or grid")

    frames: list[Image.Image] = []
    for box in selected_boxes:
        crop = source.crop(box)
        if spec.clean_light_background:
            crop = remove_light_background(crop)
        frames.append(
            normalize_frame(
                crop,
                max_width=spec.max_width,
                max_height=spec.max_height,
                mirror=spec.mirror,
            )
        )
    return frames


def clear_pngs(directory: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    for path in directory.glob("*.png"):
        path.unlink()


def export_frames(
    character_id: str,
    animation: str,
    frames: Iterable[Image.Image],
) -> list[str]:
    state, direction = animation.split("_", 1)
    output_dir = IMAGES / character_id / state / direction
    clear_pngs(output_dir)

    exported: list[str] = []
    for index, frame in enumerate(frames):
        output_name = f"{character_id}_{state}_{direction}_{index:02d}.png"
        output_path = output_dir / output_name
        frame.save(output_path)
        exported.append(str(output_path.relative_to(ROOT)))
    return exported


def copy_existing_frame(character_id: str, animation: str, source_relative: str) -> list[str]:
    state, direction = animation.split("_", 1)
    source = IMAGES / character_id / source_relative
    output_dir = IMAGES / character_id / state / direction
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{character_id}_{state}_{direction}_00.png"
    if source.resolve() != output_path.resolve():
        clear_pngs(output_dir)
        output_path.write_bytes(source.read_bytes())
    return [str(output_path.relative_to(ROOT))]


def animation_def(paths: list[str], fps: int) -> dict[str, object]:
    return {
        "frames": len(paths),
        "fps": fps,
        "loop": True,
        "paths": ["/".join(Path(path).parts[3:]) for path in paths],
    }


def read_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text())


def write_json(path: Path, data: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def update_pepita_config(exports: dict[str, list[str]]) -> None:
    path = IMAGES / "pepita" / "character.json"
    config = read_json(path)
    animations = config["animations"]  # type: ignore[index]
    assert isinstance(animations, dict)
    for name in ("walk_left", "walk_right", "walk_up"):
        animations[name] = animation_def(exports[f"pepita/{name}"], fps=10)
    write_json(path, config)


def update_abuela_config(exports: dict[str, list[str]]) -> None:
    path = IMAGES / "abuela_rosa" / "character.json"
    config = read_json(path)
    animations = config["animations"]  # type: ignore[index]
    assert isinstance(animations, dict)
    for name in (
        "idle_down",
        "idle_left",
        "idle_right",
        "idle_up",
        "walk_down",
        "walk_left",
        "walk_right",
        "walk_up",
    ):
        animations[name] = animation_def(
            exports[f"abuela_rosa/{name}"],
            fps=1 if name.startswith("idle_") else 8,
        )
    write_json(path, config)


def write_xolo_config(exports: dict[str, list[str]]) -> None:
    config = {
        "schemaVersion": 1,
        "id": "xolo",
        "displayName": "Xolo",
        "role": "loyal_dog",
        "frameWidth": FRAME_SIZE,
        "frameHeight": FRAME_SIZE,
        "defaultDirection": "down",
        "movement": {
            "walkSpeed": 70,
            "skipSpeed": 85,
        },
        "personality": {
            "decisionIntervalMs": [1500, 4500],
            "autonomousBehaviours": [
                {"action": "idle", "weight": 0.55},
                {"action": "walk", "weight": 0.45},
            ],
        },
        "animations": {
            "idle_down": animation_def(exports["xolo/idle_down"], fps=1),
            "walk_left": animation_def(exports["xolo/walk_left"], fps=10),
            "walk_right": animation_def(exports["xolo/walk_right"], fps=10),
        },
    }
    write_json(IMAGES / "xolo" / "character.json", config)


def main() -> None:
    pepita_right = FrameSpec(
        REFERENCE / "Pepita" / "74080b79-a3c7-46bd-a9f4-7185ec7f91dd.png",
        component_indexes=(1, 3, 7, 8, 9, 7),
    )
    pepita_up = FrameSpec(
        REFERENCE / "Pepita" / "f1a7f310-d550-408a-8b4f-98ed9c06b052.png",
        component_indexes=(0, 1, 2, 3, 4, 5),
    )

    abuela_right = FrameSpec(
        REFERENCE / "Abeula" / "552fcca8-d55d-4c59-bc26-a17f93581084.png",
        component_indexes=(0, 1, 2, 3, 4, 5),
        max_height=108,
    )
    abuela_down = FrameSpec(
        REFERENCE / "Abeula" / "552fcca8-d55d-4c59-bc26-a17f93581084.png",
        component_indexes=(8, 9, 10, 11, 12, 15),
        max_height=108,
    )
    abuela_up = FrameSpec(
        REFERENCE / "Abeula" / "374db267-06bf-4d91-bb39-1c35deff0213.png",
        component_indexes=(6, 7, 8, 9, 10, 11),
        max_height=108,
    )

    xolo_left = FrameSpec(
        REFERENCE / "Xolo" / "32771eb1-9faa-4150-8e54-6eff8c8778ce.png",
        component_indexes=(0, 3, 4, 5, 1, 6, 2, 7),
        max_width=110,
        max_height=88,
        clean_light_background=True,
    )
    xolo_idle = FrameSpec(
        REFERENCE / "Xolo" / "1a36d1a0-42d1-48fe-9e95-66d4b677913b.png",
        component_indexes=(0,),
        max_width=112,
        max_height=108,
    )

    exports: dict[str, list[str]] = {}

    pepita_right_frames = frames_from_spec(pepita_right)
    pepita_up_frames = frames_from_spec(pepita_up)
    exports["pepita/walk_right"] = export_frames("pepita", "walk_right", pepita_right_frames)
    exports["pepita/walk_left"] = export_frames(
        "pepita",
        "walk_left",
        [ImageOps.mirror(frame) for frame in pepita_right_frames],
    )
    exports["pepita/walk_up"] = export_frames("pepita", "walk_up", pepita_up_frames)

    abuela_right_frames = frames_from_spec(abuela_right)
    abuela_down_frames = frames_from_spec(abuela_down)
    abuela_up_frames = frames_from_spec(abuela_up)
    exports["abuela_rosa/idle_down"] = copy_existing_frame(
        "abuela_rosa",
        "idle_down",
        "idle/down/abuela_rosa_idle_down_00.png",
    )
    exports["abuela_rosa/idle_right"] = export_frames("abuela_rosa", "idle_right", abuela_right_frames[:1])
    exports["abuela_rosa/idle_left"] = export_frames(
        "abuela_rosa",
        "idle_left",
        [ImageOps.mirror(abuela_right_frames[0])],
    )
    exports["abuela_rosa/idle_up"] = export_frames("abuela_rosa", "idle_up", abuela_up_frames[:1])
    exports["abuela_rosa/walk_right"] = export_frames("abuela_rosa", "walk_right", abuela_right_frames)
    exports["abuela_rosa/walk_left"] = export_frames(
        "abuela_rosa",
        "walk_left",
        [ImageOps.mirror(frame) for frame in abuela_right_frames],
    )
    exports["abuela_rosa/walk_down"] = export_frames("abuela_rosa", "walk_down", abuela_down_frames)
    exports["abuela_rosa/walk_up"] = export_frames("abuela_rosa", "walk_up", abuela_up_frames)

    xolo_left_frames = frames_from_spec(xolo_left)
    exports["xolo/idle_down"] = export_frames("xolo", "idle_down", frames_from_spec(xolo_idle))
    exports["xolo/walk_left"] = export_frames("xolo", "walk_left", xolo_left_frames)
    exports["xolo/walk_right"] = export_frames(
        "xolo",
        "walk_right",
        [ImageOps.mirror(frame) for frame in xolo_left_frames],
    )

    update_pepita_config(exports)
    update_abuela_config(exports)
    write_xolo_config(exports)

    print(json.dumps({"exported": exports}, indent=2))


if __name__ == "__main__":
    main()
