# Festival Plaza — layered backdrop spec

**Goal:** Same map geometry day and night. Animate river, fountain, tree, flags, lights, and sun/moon roll. Buildings/graveyard/doghouse stay on the base plate until we add per-building layers later.

**Canvas lock:** 1280 × 426 px (matches current `spirit_village_plaza_day.png`). Every layer PNG is full canvas, transparent outside the element.

---

## Is this honestly possible?

**Yes.** This is standard 2D compositing — Pocket God / living-world games do this constantly.

| Piece | How |
|-------|-----|
| Same map exactly | One **base plate** (cobble + buildings + props). Night adds a **lights overlay**, not a redraw. |
| River / fountain flow | Separate PNG masks + UV scroll / ripple shader in code (already started in `VillageAtmosphere`). |
| Tree + flags sway | Separate PNG layers + sine rotation/skew from wind (already in atmosphere). |
| Candle / lamp flicker | Night **lights layer** OR individual light sprites at `decor_markers.json` UVs + alpha pulse. |
| Sun / moon roll | Separate sky + celestial sprites; code animates horizontal slide on tap (no new art required to prototype). |
| Building taps later | Base stays static; optional future layers (`panaderia_glow`, `doghouse_door`, `graveyard_candles`). |

**Hard part = art export**, not code. ChatGPT can generate layers if you give it the locked full plate and ask for **one element per PNG, same canvas size, everything else transparent**.

---

## Layer stack (back → front)

| Z | Layer ID | Day | Night | Animation |
|---|----------|-----|-------|-----------|
| 0 | `sky_day` | ✓ | hidden | — |
| 0 | `sky_night` | hidden | ✓ | stars optional twinkle |
| 1 | `base` | ✓ | ✓ | static (cobble, buildings, bridge stone, tree trunk, benches) |
| 2 | `river` | ✓ | ✓ | flow scroll / ripple |
| 3 | `fountain` | ✓ | ✓ | ripple + occasional splash on tap |
| 4 | `tree_canopy` | ✓ | ✓ | gentle sway (wind + breeze) |
| 5 | `flags` | ✓ | ✓ | papel picado sway |
| 6 | `lights` | hidden | ✓ | flicker (candles, lanterns, windows) |
| 7 | `sun` | ✓ | hidden | rolls off-screen on → night |
| 7 | `moon` | hidden | ✓ | rolls in on → night |

**Do NOT put on base** (cut to separate layers): river water, fountain water, tree leaves, flag strings, sun, moon, any night glow.

---

## Export checklist (Photoshop / Photopea / ChatGPT)

For each layer export **PNG-32** at **1280×426**:

1. `plaza_base.png` — full scene minus animated parts above  
2. `plaza_river.png` — water + lily pads only  
3. `plaza_fountain.png` — bowl water + jets only  
4. `plaza_tree.png` — canopy + flowers only (trunk stays on base)  
5. `plaza_flags.png` — three papel picado strings only  
6. `plaza_sky_day.png` — blue sky, clouds, hills (no sun)  
7. `plaza_sky_night.png` — dark sky, stars (no moon)  
8. `plaza_sun.png` — sun only (small sprite OK if centered in cell)  
9. `plaza_moon.png` — moon only  
10. `plaza_lights.png` — **all** warm glows: candles, street lamps, tree lanterns, window light (night only)

Drop in: `assets/images/village/layers/`

Manifest: `assets/data/locations/l1_plaza_layers.json` (wired in code).

---

## ChatGPT prompt (one layer at a time)

Attach the **current full day plate** as design lock.

> Export ONE layer for my 1280×426 festival plaza game.  
> Canvas: exactly 1280×426 px PNG with transparency.  
> Layer: **[river / fountain / tree / flags / etc.]** only — everything else fully transparent.  
> Match colors, perspective, and position EXACTLY to the attached reference.  
> Do not move, resize, or redesign any element.  
> No text labels on the sheet.

Repeat per layer. **Do not** ask for all layers in one grid — one file per layer.

---

## Code status

- `VillageLayerStack` — compositor + animation hooks (`assets/data/locations/l1_plaza_layers.json`)
- Falls back to legacy `spirit_village_plaza_day/night.png` until layer files exist
- Sun/moon roll on day/night toggle — **tap the sun (day) or moon (night)**, or use the HUD moon button
- `decor_markers.json` UVs still drive taps + light flicker positions

---

## Phased rollout

1. **Now (code):** layer manifest, compositor, sun/moon roll, river/fountain/tree/flags motion on placeholders  
2. **Art v1:** base + river + fountain + tree + flags (day only) — flow/sway visible in simulator  
3. **Art v2:** sky split + sun/moon PNGs — roll transition polished  
4. **Art v3:** `plaza_lights.png` — night flicker  
5. **Later:** doghouse, graveyard, building glow layers for tap reactions
