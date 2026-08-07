#!/usr/bin/env python3
"""Extract extra plaza cast sprites (gato, tito, miguel, alebrije, doña luz)."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import ImageOps

from extract_character_sprites import (
    FRAME_SIZE,
    IMAGES,
    REFERENCE,
    FrameSpec,
    animation_def,
    export_frames,
    frames_from_spec,
    write_json,
)


def write_cast_config(
    *,
    character_id: str,
    display_name: str,
    role: str,
    walk_speed: float,
    exports: dict[str, list[str]],
    walk_fps: int = 10,
) -> None:
    animations: dict[str, object] = {
        "idle_down": animation_def(exports[f"{character_id}/idle_down"], fps=1),
    }
    for name in ("walk_left", "walk_right", "walk_up", "walk_down", "idle_left", "idle_right", "idle_up"):
        key = f"{character_id}/{name}"
        if key in exports:
            animations[name] = animation_def(
                exports[key],
                fps=1 if name.startswith("idle_") else walk_fps,
            )

    config = {
        "schemaVersion": 1,
        "id": character_id,
        "displayName": display_name,
        "role": role,
        "frameWidth": FRAME_SIZE,
        "frameHeight": FRAME_SIZE,
        "defaultDirection": "down",
        "movement": {
            "walkSpeed": walk_speed,
            "skipSpeed": walk_speed + 15,
        },
        "personality": {
            "decisionIntervalMs": [1200, 3800],
            "autonomousBehaviours": [
                {"action": "idle", "weight": 0.3},
                {"action": "walk", "weight": 0.7},
            ],
        },
        "animations": animations,
    }
    write_json(IMAGES / character_id / "character.json", config)


def main() -> None:
    exports: dict[str, list[str]] = {}

    # --- Gato ---
    gato_sheet = REFERENCE / "gato" / "5508daa8-5bde-4cf7-87b1-ff4d2e7dba80.png"
    gato_right = frames_from_spec(
        FrameSpec(
            gato_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5, 6),
            max_width=110,
            max_height=90,
            clean_light_background=True,
        )
    )
    gato_left = frames_from_spec(
        FrameSpec(
            gato_sheet,
            component_indexes=(7, 8, 9, 10, 11, 12, 13),
            max_width=110,
            max_height=90,
            clean_light_background=True,
        )
    )
    gato_up = frames_from_spec(
        FrameSpec(
            gato_sheet,
            component_indexes=(14, 15, 16, 17, 18, 19),
            max_width=100,
            max_height=95,
            clean_light_background=True,
        )
    )
    gato_idle = frames_from_spec(
        FrameSpec(
            gato_sheet,
            component_indexes=(21,),
            max_width=110,
            max_height=100,
            clean_light_background=True,
        )
    )
    exports["gato/walk_right"] = export_frames("gato", "walk_right", gato_right)
    exports["gato/walk_left"] = export_frames("gato", "walk_left", gato_left)
    exports["gato/walk_up"] = export_frames("gato", "walk_up", gato_up)
    exports["gato/idle_down"] = export_frames("gato", "idle_down", gato_idle)
    write_cast_config(
        character_id="gato",
        display_name="Gato",
        role="plaza_cat",
        walk_speed=78,
        exports=exports,
    )

    # --- Tito (mariachi) ---
    tito_sheet = REFERENCE / "Tito" / "baea36e1-07e0-4008-b12b-bce43f434836.png"
    tito_walk = frames_from_spec(
        FrameSpec(tito_sheet, component_indexes=(3, 4, 5, 6, 7), max_width=100, max_height=112)
    )
    tito_idle = frames_from_spec(
        FrameSpec(tito_sheet, component_indexes=(12,), max_width=100, max_height=112)
    )
    exports["tito/walk_right"] = export_frames("tito", "walk_right", tito_walk)
    exports["tito/walk_left"] = export_frames(
        "tito", "walk_left", [ImageOps.mirror(f) for f in tito_walk]
    )
    exports["tito/idle_down"] = export_frames("tito", "idle_down", tito_idle)
    write_cast_config(
        character_id="tito",
        display_name="Tito",
        role="mariachi",
        walk_speed=48,
        exports=exports,
        walk_fps=9,
    )

    # --- Miguel ---
    miguel_sheet = REFERENCE / "Miegel" / "3ff301cc-5b2a-4617-82a7-d8e8d0953c9d.png"
    miguel_walk = frames_from_spec(
        FrameSpec(miguel_sheet, component_indexes=(0, 1, 2, 3, 4), max_width=100, max_height=112)
    )
    miguel_idle = frames_from_spec(
        FrameSpec(miguel_sheet, component_indexes=(11,), max_width=100, max_height=112)
    )
    exports["miguel/walk_right"] = export_frames("miguel", "walk_right", miguel_walk)
    exports["miguel/walk_left"] = export_frames(
        "miguel", "walk_left", [ImageOps.mirror(f) for f in miguel_walk]
    )
    exports["miguel/idle_down"] = export_frames("miguel", "idle_down", miguel_idle)
    write_cast_config(
        character_id="miguel",
        display_name="Miguel",
        role="marigold_courier",
        walk_speed=58,
        exports=exports,
    )

    # --- Alebrije ---
    ale_sheet = REFERENCE / "alebrije" / "ae5cff96-9f37-442f-9b30-aeab155891d3.png"
    ale_walk = frames_from_spec(
        FrameSpec(
            ale_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5),
            max_width=110,
            max_height=100,
            clean_light_background=True,
        )
    )
    ale_idle = frames_from_spec(
        FrameSpec(
            ale_sheet,
            component_indexes=(24,),
            max_width=110,
            max_height=100,
            clean_light_background=True,
        )
    )
    exports["alebrije/walk_right"] = export_frames("alebrije", "walk_right", ale_walk)
    exports["alebrije/walk_left"] = export_frames(
        "alebrije", "walk_left", [ImageOps.mirror(f) for f in ale_walk]
    )
    exports["alebrije/idle_down"] = export_frames("alebrije", "idle_down", ale_idle)
    write_cast_config(
        character_id="alebrije",
        display_name="Alebrije",
        role="spirit_creature",
        walk_speed=70,
        exports=exports,
    )

    # --- Doña Luz ---
    luz_sheet = REFERENCE / "Dona Luz" / "e5298113-c518-404d-a44e-3e952f214144.png"
    luz_walk = frames_from_spec(
        FrameSpec(
            luz_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5),
            max_width=95,
            max_height=112,
            clean_light_background=True,
        )
    )
    luz_idle = frames_from_spec(
        FrameSpec(
            luz_sheet,
            component_indexes=(24,),
            max_width=95,
            max_height=112,
            clean_light_background=True,
        )
    )
    exports["dona_luz/walk_right"] = export_frames("dona_luz", "walk_right", luz_walk)
    exports["dona_luz/walk_left"] = export_frames(
        "dona_luz", "walk_left", [ImageOps.mirror(f) for f in luz_walk]
    )
    exports["dona_luz/idle_down"] = export_frames("dona_luz", "idle_down", luz_idle)
    write_cast_config(
        character_id="dona_luz",
        display_name="Doña Luz",
        role="candle_keeper",
        walk_speed=40,
        exports=exports,
        walk_fps=8,
    )

    print(json.dumps({"exported_ids": sorted({k.split("/")[0] for k in exports})}, indent=2))


if __name__ == "__main__":
    main()
