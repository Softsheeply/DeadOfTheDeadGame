#!/usr/bin/env python3
"""Extract another plaza cast batch: Cuervo, Chavo, Don Mateo, Pinto."""

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
    for name in ("walk_left", "walk_right", "walk_up", "walk_down"):
        key = f"{character_id}/{name}"
        if key in exports:
            animations[name] = animation_def(exports[key], fps=walk_fps)

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


def export_side_walks(
    character_id: str,
    walk_frames: list,
    exports: dict[str, list[str]],
) -> None:
    exports[f"{character_id}/walk_right"] = export_frames(
        character_id, "walk_right", walk_frames
    )
    exports[f"{character_id}/walk_left"] = export_frames(
        character_id,
        "walk_left",
        [ImageOps.mirror(frame) for frame in walk_frames],
    )


def main() -> None:
    exports: dict[str, list[str]] = {}

    # Señor Cuervo — festival crow
    cuervo_sheet = REFERENCE / "Senor Curevo" / "9f1db72c-fbfa-49bf-86f9-78a502f17404.png"
    cuervo_walk = frames_from_spec(
        FrameSpec(
            cuervo_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5),
            max_width=100,
            max_height=100,
            clean_light_background=True,
        )
    )
    cuervo_idle = frames_from_spec(
        FrameSpec(
            cuervo_sheet,
            component_indexes=(32,),
            max_width=100,
            max_height=100,
            clean_light_background=True,
        )
    )
    export_side_walks("senor_cuervo", cuervo_walk, exports)
    exports["senor_cuervo/idle_down"] = export_frames("senor_cuervo", "idle_down", cuervo_idle)
    write_cast_config(
        character_id="senor_cuervo",
        display_name="Señor Cuervo",
        role="festival_crow",
        walk_speed=66,
        exports=exports,
    )

    # Chavo — young guitar mariachi
    chavo_sheet = (
        REFERENCE / "a new youner charactter" / "3aa82ec6-43bc-4ded-8509-3cf264e0fd7a.png"
    )
    chavo_walk = frames_from_spec(
        FrameSpec(
            chavo_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5),
            max_width=100,
            max_height=112,
            clean_light_background=True,
        )
    )
    chavo_idle = frames_from_spec(
        FrameSpec(
            chavo_sheet,
            component_indexes=(20,),
            max_width=100,
            max_height=112,
            clean_light_background=True,
        )
    )
    export_side_walks("chavo", chavo_walk, exports)
    exports["chavo/idle_down"] = export_frames("chavo", "idle_down", chavo_idle)
    write_cast_config(
        character_id="chavo",
        display_name="Chavo",
        role="junior_mariachi",
        walk_speed=52,
        exports=exports,
        walk_fps=9,
    )

    # Don Mateo
    mateo_sheet = REFERENCE / "Don Mateo" / "16719e4a-0553-4151-bd7f-751f490cffba.png"
    mateo_walk = frames_from_spec(
        FrameSpec(
            mateo_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5),
            max_width=95,
            max_height=112,
            clean_light_background=True,
        )
    )
    mateo_idle = frames_from_spec(
        FrameSpec(
            mateo_sheet,
            component_indexes=(24,),
            max_width=95,
            max_height=112,
            clean_light_background=True,
        )
    )
    export_side_walks("don_mateo", mateo_walk, exports)
    exports["don_mateo/idle_down"] = export_frames("don_mateo", "idle_down", mateo_idle)
    write_cast_config(
        character_id="don_mateo",
        display_name="Don Mateo",
        role="plaza_elder",
        walk_speed=38,
        exports=exports,
        walk_fps=8,
    )

    # Pinto — little painter
    pinto_sheet = REFERENCE / "Pinto" / "bd7bca4a-11cc-4bff-b0cf-647ef44b39fd.png"
    pinto_walk = frames_from_spec(
        FrameSpec(
            pinto_sheet,
            component_indexes=(0, 1, 2, 3, 4, 5),
            max_width=100,
            max_height=112,
            clean_light_background=True,
        )
    )
    pinto_idle = frames_from_spec(
        FrameSpec(
            pinto_sheet,
            component_indexes=(24,),
            max_width=100,
            max_height=112,
            clean_light_background=True,
        )
    )
    export_side_walks("pinto", pinto_walk, exports)
    exports["pinto/idle_down"] = export_frames("pinto", "idle_down", pinto_idle)
    write_cast_config(
        character_id="pinto",
        display_name="Pinto",
        role="plaza_painter",
        walk_speed=50,
        exports=exports,
    )

    print(json.dumps({"exported_ids": sorted({k.split("/")[0] for k in exports})}, indent=2))


if __name__ == "__main__":
    main()
