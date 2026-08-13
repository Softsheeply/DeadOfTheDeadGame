# Festival Plaza — ChatGPT prompts (from scratch)

Copy one block at a time into ChatGPT. **Generate in this order.**

Save each PNG as listed → drop in `assets/images/village/layers/` → push to git.

---

## Rules (every prompt)

- Canvas: **1280 × 426 px** landscape (very wide — about 3:1)
- Format: **PNG with transparency** (RGBA)
- Style: **2D mobile game art**, warm Día de los Muertos festival plaza, slightly isometric / tilted top-down view (like a living dollhouse village)
- **No text labels** on buildings (no “Panadería” painted on roofs)
- **One file per generation** — never ask for a grid of layers
- After Step 0 exists, **attach the master image** to every later prompt as the position lock

---

## Step 0 — Master design lock (generate first)

Save as: `plaza_master_reference.png` (reference only — not shipped in game)

```
Create a wide horizontal game background for a Día de los Muertos village plaza mobile game.

Canvas: exactly 1280 pixels wide × 426 pixels tall. Landscape, not portrait.

Camera: slightly elevated isometric view looking down at the plaza — like a cozy Pocket God / virtual village diorama. One continuous scene, not a collage.

SCENE LAYOUT (left → right, back → front):

SKY (top ~35%):
- Daytime clear blue sky, soft white clouds, rolling green hills on the horizon.

BACK ROW — buildings along the plaza (same roofline height):
- Far left: small flower stall with purple roof, overflowing marigolds and colorful flowers.
- Left-center: white panadería with brown tile roof; warm orange oven glow visible through a doorway.
- Center-back: large tree in a circular stone planter — dense green leaves with orange/yellow marigold blossoms.
- Right-center: wooden mariachi stage under a purple roof; guitar leaning inside; small skull emblem on the peak.
- Right: large purple church with domed roof and skull icon above double wooden doors.
- Far right: mercado stall with purple and yellow striped awning, goods on display.

TOP OF SCENE:
- Three horizontal strings of colorful papel picado (cut-paper banners) stretching across the full width — orange, blue, pink, yellow triangles.

MID / FOREGROUND:
- Tan cobblestone plaza fills the lower half — main walkable area.
- Center: circular three-tier stone fountain with bright blue water.
- Left foreground: blue river curving from bottom-left toward center-left; green lily pads; small arched stone bridge crossing the river.
- Right foreground: small purple-roofed doghouse with a dark dog sitting inside.
- Far right foreground: small graveyard enclosed by low wooden fence — gray tombstones, tall green cacti, marigolds.

STYLE:
- Warm, festive, hand-painted game art — not photorealistic, not 3D render.
- Purple roofs, terracotta and tan stone, marigold orange accents throughout.
- Soft outlines, readable at phone scale.
- Characters will walk on the cobble band in the lower third — keep that area relatively open.

Do NOT include: sun, moon, stars, or heavy glow/bloom (those are separate layers).
Output a single flat PNG, 1280×426.
```

---

## Step 1 — Base plate (static world)

Save as: `plaza_base.png`

Attach: **plaza_master_reference.png**

```
Using the attached reference as an EXACT layout lock:

Export ONE layer for a 1280×426 mobile game background.

Include ONLY the static parts of the plaza:
- Cobblestone plaza ground
- All building walls, roofs, doors, windows (flower stall, panadería, mariachi stage, church, mercado)
- Stone bridge (structure only — NO river water)
- Fountain stone bowl and tiers (NO water inside)
- Tree TRUNK and stone planter only (NO leaves or flowers — those are a separate layer)
- Benches, doghouse structure, graveyard fence and tombstones (no candle flames)
- Hills visible below the sky line if any peek above buildings

EXCLUDE entirely (fully transparent):
- Sky (blue, clouds, hills horizon)
- River water and lily pads
- Fountain water
- Tree canopy / leaves / blossoms
- Papel picado flag strings
- Sun, moon, stars
- Any warm glow, candle flames, lantern light, window glow

Canvas: 1280×426 PNG, transparent outside the art.
Match the reference colors, perspective, and pixel positions exactly.
No text labels.
```

---

## Step 2 — Day sky

Save as: `plaza_sky_day.png`

```
Using the attached plaza master reference as layout lock:

Export ONE layer, 1280×426 PNG, transparent outside the sky.

Include ONLY:
- Blue daytime sky filling the upper portion
- Soft white clouds
- Rolling green hills on the horizon line

EXCLUDE: sun, buildings, plaza, flags, any ground. Everything below the horizon = transparent.

Match the reference sky colors and cloud placement exactly.
```

---

## Step 3 — Night sky

Save as: `plaza_sky_night.png`

Attach: **plaza_master_reference.png** (or day sky if you have it)

```
Using the attached reference for horizon placement:

Export ONE layer, 1280×426 PNG.

Include ONLY the night sky:
- Deep midnight blue sky
- Scattered small white stars
- Same hill silhouette as day version but darkened / in shadow

EXCLUDE: moon (separate layer), buildings, plaza, glow from candles below.
Everything below the horizon = transparent.
Same canvas size and horizon Y position as the day sky layer.
```

---

## Step 4 — Sun

Save as: `plaza_sun.png`

```
Game art asset: the SUN only for a Día de los Muertos village background.

Canvas: 1280×426 PNG — almost entirely transparent.

Place ONE soft round sun in the UPPER RIGHT area of the canvas (roughly 78% from left, 12% from top of the full canvas).

Style: warm yellow-orange, soft cel-shaded game sun, slight glow halo — matches a festive cartoon mobile game.

Everything else on the canvas = fully transparent.
No sky, no clouds, no buildings.
```

---

## Step 5 — Moon

Save as: `plaza_moon.png`

```
Game art asset: the MOON only for a Día de los Muertos village night background.

Canvas: 1280×426 PNG — almost entirely transparent.

Place ONE bright full moon in the UPPER LEFT area (roughly 22% from left, 14% from top of the full canvas).

Style: soft pale white-blue moon, gentle glow — cartoon mobile game, not photorealistic.

Everything else = fully transparent.
```

---

## Step 6 — River

Save as: `plaza_river.png`

Attach: **plaza_master_reference.png**

```
Using the attached reference as EXACT position lock:

Export ONE layer, 1280×426 PNG, transparent outside the water.

Include ONLY:
- The blue river water in the left foreground
- Green lily pads on the water
- Subtle water shading / highlights (game art style)

EXCLUDE: bridge stone, cobblestone, banks, buildings, candles, sky.

The river path, width, and bridge crossing must match the reference exactly.
This layer will be animated (flow) in code — draw the water as a clean separate element.
```

---

## Step 7 — Fountain water

Save as: `plaza_fountain.png`

Attach: **plaza_master_reference.png**

```
Using the attached reference as EXACT position lock:

Export ONE layer, 1280×426 PNG, transparent outside the fountain water.

Include ONLY the water inside the central three-tier stone fountain:
- Bright blue pool in the bowl
- Small water jets / surface ripples
- Center of fountain roughly at 57% from left, 60% from top of canvas

EXCLUDE: stone fountain structure (that's on the base layer), cobblestone, buildings, sky.

Clean water shapes only — this layer animates (ripple) in code.
```

---

## Step 8 — Tree canopy

Save as: `plaza_tree.png`

Attach: **plaza_master_reference.png**

```
Using the attached reference as EXACT position lock:

Export ONE layer, 1280×426 PNG, transparent outside the foliage.

Include ONLY the main plaza tree's canopy:
- Dense green leaves
- Orange and yellow marigold blossoms mixed in the foliage
- Centered behind the fountain (~50% from left, canopy spans roughly 38%–46% from top)

EXCLUDE: tree trunk, stone planter (on base layer), buildings, sky, flags.

This layer will sway gently in wind — draw leaves as one cohesive canopy mass.
```

---

## Step 9 — Papel picado flags

Save as: `plaza_flags.png`

Attach: **plaza_master_reference.png**

```
Using the attached reference as EXACT position lock:

Export ONE layer, 1280×426 PNG, transparent outside the banners.

Include ONLY the three horizontal strings of papel picado across the top of the scene:
- Colorful cut-paper triangles: orange, blue, pink, yellow
- Strings span the full width of the plaza
- Slight natural sag between support points

EXCLUDE: sky, buildings, trees, everything else.

This layer will sway in wind in code — draw flags as one connected element per string.
```

---

## Step 10 — Night lights (all glows)

Save as: `plaza_lights.png`

Attach: **plaza_master_reference.png** + your **night version reference** if you have one

```
Using the attached plaza reference(s) as EXACT position lock:

Export ONE layer, 1280×426 PNG for NIGHTTIME light effects only.

Include ALL warm light sources visible at night (draw the glow + flame/light, not the objects themselves):

- Small votive candles along the riverbank and on the bridge
- Candles floating on the river water
- Candles ringing the fountain base
- Paper lanterns hanging from the main tree branches
- Tall street lamps left and right edges of plaza
- Warm window glow from panadería and church
- Candle clusters on church steps
- Soft glow on graveyard tombstones
- Any mercado stall lamplight

Style: warm yellow-orange glow pools + small bright flame cores. Soft bloom, game art — readable at phone scale.

EXCLUDE: sky, moon, stars, buildings (solid walls), cobblestone, water (blue), tree leaves (green). Only the LIGHT/GLOW elements.

This entire layer flickers in code — keep glow shapes simple and slightly separated where possible.

Background = fully transparent.
Same layout positions as the reference exactly.
```

---

## After export — Mac checklist

1. Verify each file is **1280 × 426** (resize in Photopea if ChatGPT drifted)
2. Confirm transparent areas are truly transparent (checkered in preview)
3. Drop into repo:

```
assets/images/village/layers/
  plaza_base.png
  plaza_sky_day.png
  plaza_sky_night.png
  plaza_sun.png
  plaza_moon.png
  plaza_river.png
  plaza_fountain.png
  plaza_tree.png
  plaza_flags.png
  plaza_lights.png
```

4. Push → pull on Mac → `flutter run`

Game loads layers automatically when **3+** PNGs exist; all 10 = full stack.

---

## If ChatGPT drifts off layout

Reply in the same thread:

```
Wrong layout. Re-generate using the attached master reference ONLY.
Do not move any building, the fountain, river, or tree.
Same 1280×426 canvas. Same [layer name] only. Everything else transparent.
```

---

## Minimum viable set (test motion fast)

If 10 files is too much at once, generate these **five first**:

1. `plaza_master_reference.png` (lock)
2. `plaza_base.png`
3. `plaza_river.png`
4. `plaza_fountain.png`
5. `plaza_tree.png`
6. `plaza_flags.png`

Sky/sun/moon/lights can wait — code falls back to legacy plate for missing layers.

---

## Related

- [[plaza-layered-backdrop]] — technical layer spec + code wiring
- `assets/data/locations/l1_plaza_layers.json` — manifest
