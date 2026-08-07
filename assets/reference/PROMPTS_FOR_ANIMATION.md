# ChatGPT / image-gen prompts for Day of the Dead plaza animation

Use these with your plaza reference images attached when possible.
Goal: transparent PNG overlays and sprite strips that lock onto the existing
painted plaza (`spirit_village_plaza_day/night`), not a full scene rewrite.

Style keywords to reuse in every prompt:
> cozy chibi Día de los Muertos village, painterly soft shading, warm marigold
> orange #F39A3C, pink #ED5791, purple #733D91, turquoise #47C4BA, cream #FFF1D1,
> thick friendly outlines, Pocket God / Animal Crossing scale, family-friendly,
> no gore, transparent background, isolated sprites, consistent lighting from
> warm candlelight

---

## 1) Candle & lantern flicker pack (highest priority)

```
Create a transparent PNG sprite sheet of Día de los Muertos candle and lantern
animation frames for a cozy chibi village game.

Layout: 8 columns × 4 rows on a transparent background.
Row 1: single fat ofrenda candle, front view, 8 flicker frames
Row 2: thin tall candle in a simple holder, 8 flicker frames
Row 3: hanging tree lantern (paper/glass), 8 glow-pulse frames
Row 4: iron plaza lamp with warm bulb, 8 flicker frames

Each frame 128×128, character/object centered, soft warm glow baked lightly into
the sprite but leave room for code bloom. Same art style as a painterly chibi
Mexican festival village. No background, no ground shadow plates, no text.
```

## 2) Fountain & stream water loops

```
Create a transparent PNG water animation pack for a chibi Day of the Dead plaza.

Sheet A — Fountain bowl (6 frames, 256×128 each in one row):
top-down-ish oval water surface with soft turquoise ripples expanding outward,
subtle sparkle highlights, matching a stone fountain in a cobbled plaza.

Sheet B — Stream under a stone bridge (6 frames, 256×96 each in one row):
gentle left-to-right flow, small foam accents, lily-pad optional but sparse.

Painterly chibi style, transparent background, no fountain stone (water only),
no characters. Soft edges so it composites over painted plaza art.
```

## 3) Building life: windows, oven, door glow

```
Create a transparent PNG sprite sheet of building interior light overlays for a
cozy Día de los Muertos plaza game. These are ADDITIVE overlays, not full buildings.

Grid 6×4, each cell 96×96:
Row 1: rectangular warm window glow (flicker) — 6 frames
Row 2: arched church doorway warm spill — 6 frames
Row 3: bakery oven orange ember breath — 6 frames
Row 4: mercado stall lantern under striped awning — 6 frames

Soft rounded rectangles / ovals with glow falloff, transparent outside the light.
Match warm candle palette. No walls, no full architecture, no text labels.
```

## 4) Bakery chimney smoke

```
Create a transparent PNG looping smoke puff strip for a bakery chimney in a
chibi Day of the Dead village.

One row of 8 frames, each 128×128.
Soft gray-cream smoke rising and dissipating, slight sideways drift,
painterly soft edges, transparent background.
Family-friendly, cute, not dirty industrial smoke.
```

## 5) Papel picado sway strips

```
Create a transparent PNG sprite sheet of papel picado banner strings for a
Mexican festival plaza game.

3 banner strings, each with 6 sway frames (18 frames total).
Colors: magenta, marigold orange, turquoise, purple, yellow.
Each flag has tiny cutout patterns (circles/diamonds).
Frames show gentle wind sway / twist.
Transparent background, no sky, no poles unless minimal string line.
Flat decorative 2D look that matches chibi village UI.
Each frame about 512×128 for a full string.
```

## 6) Modular plaza buildings (next pipeline stage)

```
Design isolated modular building sprites for a living Día de los Muertos plaza,
matching a cozy painterly chibi village (not hard pixel tiles).

Provide separate transparent PNGs (or a labeled sheet) for:
1) Floristería flower stall — purple roof, marigold pots, skull motif
2) Panadería bakery — stone oven mouth clearly visible, warm interior
3) Mariachi stage — wooden platform, purple curtains, skull header
4) Small church — purple dome, cross, skull over arched door
5) Mercado stall — striped yellow/purple awning

Each building: 3/4 view, feet/base at bottom, readable at ~256–384 px wide,
transparent background, consistent ground-shadow optional soft ellipse only.
Also provide a night variant OR a separate “lit windows” layer for each.
No characters standing in front.
```

## 7) Ambient critters: butterflies & birds

```
Create transparent PNG animation strips for tiny ambient plaza life:

A) Monarch-style marigold butterfly — flap cycle 6 frames, 64×64 each
B) Blue festival butterfly — flap cycle 6 frames, 64×64 each
C) Small black festival bird / mini cuervo — fly cycle 6 frames side view, 96×64
D) Same bird perched idle bob — 4 frames

Painterly chibi Día de los Muertos style, cute, colorful accents, transparent
background, no scenery.
```

## 8) Ofrenda / decor props pack

```
Create a transparent PNG prop sheet for a Day of the Dead plaza toy game:

- 3 marigold pots (different sizes)
- 2 ofrenda altar stacks with candles (static is ok)
- 1 guitar leaning prop
- 1 market cart with flowers
- 1 stone well
- 1 iron fence segment
- 1 skull signpost

Painterly chibi style, consistent light, transparent backgrounds, each prop
isolated with a little padding. Readable at mobile size.
```

## 9) Interactive “door open” micro-animations

```
For each plaza building (florist, bakery, church, mercado), create a 4-frame
transparent overlay of a door slightly opening / closing with warm light spill
increasing as it opens. 128×160 frames, door region only, no full building.
Cozy chibi Día de los Muertos style.
```

---

## How we’ll use what you generate

1. Overlay packs (1–5, 7, 9) → drop into `assets/images/village/fx/` and wire via
   `decor_markers.json` UV points on the painted plaza.
2. Modular buildings (6, 8) → later replace/augment flattened plaza with layered
   props (bigger art pipeline).
3. Prefer **transparent PNG**, **labeled rows**, **power-of-two-ish frame sizes**,
   and **no baked checkerboard**.

## Reference to attach when prompting
- `assets/images/village/spirit_village_plaza_night.png`
- `assets/images/village/spirit_village_plaza_day.png`
- Any best building sheet from `assets/reference/Buildings/`
