# Day of the Dead — Finish Plan (living checklist)

> Pocket God / living-world first. **Reuse cast across locations.**  
> Soft launch = Phase A. Full game ≈ through Phase H.  
> Check boxes as you go. Keep this file the source of truth in git.

**Current build target:** `1.0.0+43` (cast slice pipeline + plaza interactables)  
**Branch:** `cursor/pocket-god-village-foundation-b7dc`

---

## Next session — Pepita animation sprint (priority)

Device TestFlight: magnified face / sliced-in-half / backwards walk.

- [x] **A1.** Re-slice `idle_down` breathe — root cause found: `a656ed79-...png` is a single 1254x1254 full-canvas portrait, not an 8-frame sheet, so grid-slicing it into 4x2 produced meaningless crops (a corner cell catching a ~20px sliver of hair/crown, scaled up to fill the frame, reading as a magnified face fragment). Fixed by giving `slice_pepita_incoming.py` a `mode="single"` path that treats the whole stripped image as one pose instead of grid-slicing it. `idle_down` is now an honest 1 real frame, not 8 broken ones.
- [x] **A2.** Add bbox validation to slice script (min width 60 px) — `MIN_FRAME_WIDTH`/`frame_content_width` existed but were never actually called anywhere; wired into the grid-slicing path now, rejects + logs (filename, frame index, target animation, measured width) any frame under 60px instead of silently exporting it. Re-ran on all incoming sheets — the real grid sheets (walk/skip, ~90-130px wide) all passed with zero rejections, confirming they were fine as the art brief suspected.
- [x] **A3.** Verify walk_left / walk_right facing matches travel direction (backwards walk) — confirmed by eye, not guessed: `a8b372d7-...png` (mapped to `walk_left`) visually shows Pepita facing/stepping RIGHT, and `Unknown-1.jpeg` (mapped to `walk_right`) visually shows her facing/stepping LEFT. The two source files were swapped in `SHEET_MAP`. Neither has a baked-in title label confirming its own direction (unlike the self-labeled "WALK DIAGONAL LEFT" skip sheet, which was correctly mapped), so the swap went unnoticed until it showed up as backwards walking on device. Fixed by swapping the SHEET_MAP entries.
- [x] **A4.** Walk cycle footfall: stride vs fps so feet don't skate on cobble — turned on `distanceWalkSync: true` in Pepita's `movement` config so `resident.dart` advances walk/skip frames by actual travel distance (`_walkDistance / stride * frameCount`) instead of a fixed-clock ticker. This also locks the coded step-bob (which was already distance-driven) into phase with the real frames instead of drifting against them on its own clock. Confirmed via static per-frame inspection that all 8 walk_left/right frames show genuine alternating foot poses (not a 2-pose fallback). Live on-device "watch her walk" confirmation still pending — screenshot-burst verification proved impractical (she wanders unpredictably, catching a mid-stride frame reliably needs a human watching continuously, not periodic captures). Code + art are both confirmed correct at this point; flag it if it still reads oddly in play.
- [x] **A7.** (new, found this session) Fixed see-through eyes — `strip_background()`'s near-black removal rule was matching Pepita's own black face paint (eye sockets, nose cross), punching real transparent holes through her face and letting the plaza background show through. Rewrote to flood-fill the background strip from the image border only, leaving interior black/white character detail alone. Also fixed a resize-halo bug (RGB not zeroed on stripped pixels) that could leave a faint pale fringe under light-colored edges like her shoes/socks.
- [ ] **A5.** Re-enable multi-frame idle_down in `character.json` after all frames pass QA — still blocked: there is no real multi-frame breathe source, only the single a656ed79 portrait (see A1). Needs a genuine new multi-pose idle sheet before this can happen; the current single-frame idle_down is the honest state, not a placeholder to "re-enable" past.
- [ ] **A6.** Real door open/close art (coded door pulse removed — sparkles + flavor only) — still art-blocked, unchanged.

**Hotfix shipped (+40):** single-frame `idle_down_01`; removed `BuildingDoorPulse` on building tap.
**A1/A2/A3 fixed** — idle single-mode slice, bbox validation, walk L/R SHEET_MAP swap (see items above).
**Hotfix shipped (+41):** distance-sync walk + 2-frame step bob while Pepita walk art lacks alternating feet. Device re-verify walk/idle after pull.
**A4/A7 fixed** — distance-synced real 8-frame walk cycle, background-strip flood-fill fix for see-through eyes + foot halo (see items above).

---

## Already done (baseline)

- [x] Living plaza prototype (contain-fit day/night art)
- [x] Cast invite / send off (persisted)
- [x] Toys: wind, petals, music, pan dulce, lantern
- [x] Day/night sky toggle
- [x] Coded atmosphere (fountain, river flow, flags, leaves, candles)
- [x] Mission loop: ofrenda marigolds → mariachi → feed Xolo → candles
- [x] Audio bed + toy stingers + mute
- [x] Walk bob / facing hysteresis / walkability blockers
- [x] Soft depth occluders
- [x] TestFlight pipeline script (`scripts/ios_testflight.sh`)
- [x] Pick up / drag / fling (Pocket God) on `Resident` — all spawned cast
- [x] Pickup juice (shadow, grab/drop SFX, held lift)
- [x] Drop / fling lands on walkable cobble
- [x] Soft separation while holding so toys don’t stack
- [x] Tutorial bead: “Drag anyone — they’re toys”
- [x] Settings (mute, reduce motion, credits) + save mute/day/cast/mission/tutorial
- [x] Remove fake papel overlays (painted flags only until animated sheets)
- [x] Disable coded river/fountain overlays (were puddles/spray on cobble)
- [x] Soft circular building glows (no grey light slabs)
- [x] Strip fake candle/window light orbs — painted night plate only
- [x] River + doghouse walk blockers; taller Pocket God pickup
- [x] Multi-hop + graph routing around doghouse / grave (cross-plaza paths)
- [x] Personality JSON drives autonomous behaviour (weights + decision interval)
- [x] Skippable 4-bead tutorial (drag → day/night → toys → mission)
- [x] Richer building taps (sparkles, cast glance, role flavor + SFX)
- [x] Rare idle events (shooting star, balloon, parade tease)
- [x] Mission loop #2 (festival set: encore, candle path, treat round, ofrenda tribute)
- [x] Ofrenda tap marker + clear tappable zone
- [x] Bench sit walks-to-spot and snaps on arrival
- [x] anchors.feet from character.json drives foot alignment
- [x] Photo mode (hide HUD for screenshots)
- [ ] Building door micro-animation on tap (#21 — coded pulse removed; real art later)
- [x] Depth occluder tuning + feet-priority sort (#20)
- [x] Cast journal bios in HUD (#58 partial)
- [x] Location data format — L1 JSON + parser (#25 partial)
- [x] Store listing draft (#5 partial)
- [x] iOS lifecycle check script (#74 partial)
- [x] NPC bench chat flavor (#53 partial)
- [x] Mission catalog JSON + data-driven plaza missions (#27 partial)
- [x] Location loader wired into backdrop + occluders (#25)
- [x] Main menu overlay (Enter plaza / World map) (#56 partial)
- [x] World map stub panel — 8 nodes, plaza unlocked (#24 partial)
- [x] Mission log panel (tap mission card) (#59 partial)
- [x] Mission reward toast on complete (#29 partial)
- [x] Lantern toy — ripple glow + candle mission progress (#71 partial)

---

## Phase A — Plaza “finished” (soft launch)

### Store / chrome
- [x] 1. App icon (unique) — `assets/branding/app_icon_1024.png`; run `dart run flutter_launcher_icons` on Mac to fill appiconset
- [ ] 2. Launch image (unique)
- [x] 3. Settings sheet (mute, reduce motion, credits)
- [x] 4. Save: missions + day/night + cast + mute
- [x] 5. Store listing copy + plaza screenshots (copy draft in docs/store/)
- [ ] 6. Soft-launch TestFlight / App Store build from polished plaza

### Character art (locked walks — Aseprite, not ChatGPT sheets)
- [x] 7. Pepita walk down / up / left / right (locked model)
- [x] 8. Pepita L/R are true mirrors; wire into `character.json`
- [ ] 9. Abuela Rosa locked walks
- [ ] 10. Xolo locked walks
- [ ] 11. Gato locked walks
- [ ] 12. Idle blink / breathing sprites for main 4
- [ ] 13. Real sit / wave / smell sprites (replace squash hacks)

### Pick up & move (all characters)
- [x] 14. Verify **every** cast member (all 12) can be grabbed, dragged, and flung on device (hitbox/visual alignment fixed — re-test on device)
- [x] 15. Reliable hit boxes (big heads / small critters — no missy taps)
- [x] 16. Pickup juice: scale-up, shadow, “held” pose / SFX
- [x] 17. Drop / fling lands on walkable cobble only (not roofs, fountain bowl, river)
- [x] 18. Soft collision so held characters don’t stack invisibly
- [x] 19. Tutorial bead: “Drag anyone — they’re toys”

### Plaza feel
- [x] 20. True depth cutouts (fountain rim, tree, bridge)
- [ ] 21. Building door open/close (real art — coded pulse removed from tap)
- [x] 22. Tap building → richer status / micro beat
- [x] 23. Bench sit looks correct
- [x] 24. Ofrenda as clear tappable prop
- [ ] 25. Better plaza music bed (replace placeholder WAVs)
- [ ] 26. Polish toy SFX
- [x] 27. Mission set #1: 4 looping plaza chores (marigolds → mariachi → Xolo → candles)
- [x] 28. Rare idle events (star, balloon, parade tease)
- [x] 29. Skippable tutorial beads (4 steps: drag, day/night, toys, mission)

**Exit criteria:** strangers enjoy poking the plaza 5+ minutes; Pepita walk no longer embarrasses you.

---

## Phase B — Systems for 8 locations

- [x] 24. World map / travel UI (8 nodes; Plaza unlocked first — stub panel)
- [x] 25. Location data format (L1 JSON + Dart parser + backdrop wiring)
- [ ] 26. Shared cast travel / “who is here”
- [x] 27. Mission framework (goals, chains, rewards, daily refresh — JSON catalog + loop)
- [ ] 28. Light inventory (marigold, pan dulce, candle, key…)
- [x] 29. Reward juice (sparkles, cast react, unlock toast — mission toast + celebration)
- [ ] 30. Cast schedules by time-of-day / location
- [ ] 31. Expand verbs beyond 4 toys (pick / give / play / clean…)
- [ ] 32. Standard z-sort + occlusion per location
- [ ] 33. Audio beds per location + crossfade on travel

---

## Phase C — Cast animation library

Order: Pepita → Abuela → Xolo → Gato → Tito → Miguel → Doña Luz → Chavo → Don Mateo → Pinto → Alebrije → Cuervo.

For **each** character:
- [ ] Walk 4-dir locked
- [ ] Idle + blink
- [ ] React: poke, happy, sit, carry
- [ ] Shared dance (music)
- [ ] Shared wind lean
- [ ] Held / carried pose (while player drags them)

Tracking:
- [ ] 34. Pepita complete set
- [ ] 35. Abuela complete set
- [ ] 36. Xolo complete set
- [ ] 37. Gato complete set
- [ ] 38. Tito complete set
- [ ] 39. Miguel complete set
- [ ] 40. Doña Luz complete set
- [ ] 41. Chavo complete set
- [ ] 42. Don Mateo complete set
- [ ] 43. Pinto complete set
- [ ] 44. Alebrije complete set
- [ ] 45. Señor Cuervo complete set
- [ ] 46. Optional emotion bubbles

**Rule:** don’t paint location 8 before ~6 humans have good walks.

---

## Phase D — Eight locations (day + night)

| ID | Location | Role |
|----|----------|------|
| L1 | Festival Plaza | Hub (current) |
| L2 | Floristería Gardens | Pepita flowers |
| L3 | Panadería Lane | Sweets / oven |
| L4 | Church & Candle Steps | Quiet / Doña Luz |
| L5 | Mercado | Trade / find |
| L6 | River & Bridge | Water life |
| L7 | Cemetery Ofrenda | Offerings / night magic |
| L8 | Parade / Stage Hill | Festival climax |

**Map build order:** L1 polish → **L3** → **L2** → **L4** → **L5** → **L6** → **L7** → **L8**

### Per location checklist (copy for each)

#### L1 Festival Plaza
- [x] Day art (in)
- [x] Night art (in)
- [ ] Walk mesh / blockers polished
- [ ] Buildings + taps polished
- [ ] Atmosphere polished
- [ ] 3–5 solid missions
- [ ] 2–3 unique verbs/toys
- [x] Unlocked by default

#### L3 Panadería Lane
- [ ] Day backdrop
- [ ] Night backdrop
- [ ] Walk mesh / blockers / hotspots JSON
- [ ] Buildings + taps
- [ ] Atmosphere (oven glow, smoke)
- [ ] 3–5 missions
- [ ] Unique verbs (deliver dulce, tend oven)
- [ ] Unlock from Plaza

#### L2 Floristería Gardens
- [ ] Day backdrop
- [ ] Night backdrop
- [ ] Walk mesh / JSON
- [ ] Buildings + taps
- [ ] Atmosphere (butterflies, watering)
- [ ] 3–5 missions
- [ ] Unique verbs (water, bouquet)
- [ ] Unlock condition

#### L4 Church & Candle Steps
- [ ] Day / night art
- [ ] Walk mesh / JSON
- [ ] Buildings + taps
- [ ] Atmosphere (candle path)
- [ ] 3–5 missions
- [ ] Unique verbs (light candles, quiet sit)
- [ ] Unlock condition

#### L5 Mercado
- [ ] Day / night art
- [ ] Walk mesh / JSON
- [ ] Stalls + taps
- [ ] Atmosphere
- [ ] 3–5 missions
- [ ] Unique verbs (trade / find)
- [ ] Unlock condition

#### L6 River & Bridge
- [ ] Day / night art
- [ ] Walk mesh / JSON
- [ ] Props + taps
- [ ] Atmosphere (flow — code OK)
- [ ] 3–5 missions
- [ ] Unique verbs (skip stone, lily)
- [ ] Unlock condition

#### L7 Cemetery Ofrenda
- [ ] Day / night art
- [ ] Walk mesh / JSON
- [ ] Altars + taps
- [ ] Atmosphere (fireflies, candles)
- [ ] 3–5 missions
- [ ] Unique verbs (place offering)
- [ ] Unlock condition

#### L8 Parade / Stage Hill
- [ ] Day / night art
- [ ] Walk mesh / JSON
- [ ] Stage + taps
- [ ] Atmosphere (confetti, music)
- [ ] 3–5 missions + finale
- [ ] Unique verbs (start parade)
- [ ] Unlock condition

---

## Phase E — Houses & place depth

- [ ] 47. Exterior focus zoom on building tap
- [ ] 48. Simple interiors: florist, bakery, church, one home
- [ ] 49. Give item to NPC
- [ ] 50. Fetch quests across 2 locations
- [ ] 51. Clean / decorate ofrenda or stall
- [ ] 52. Pet / play Xolo & Gato (location-aware)
- [x] 53. NPC–NPC bench chats (flavor)
- [ ] 54. Door schedules day vs night
- [ ] 55. Hidden interactables (careful with walk rules)

---

## Phase F — Menus & meta

- [x] 56. Main menu (Play / Continue / Settings / Credits — Enter plaza + map stub)
- [ ] 57. Pause + map always available
- [x] 58. Cast journal (bios) — journal sheet in cast panel
- [x] 59. Mission log (active / done — tap mission card)
- [ ] 60. Collection album (events, marigolds)
- [ ] 61. Daily gift
- [ ] 62. Photo mode (hide UI)
- [ ] 63. Accessibility (hit targets, reduce flash, SFX captions)
- [ ] 64. Onboarding: sky / poke / toy / first mission

---

## Phase G — More toys & mission ideas

### Toys / verbs
- [ ] 65. Watering can
- [ ] 66. Balloon
- [ ] 67. Soft comic firecracker (family-safe)
- [ ] 68. Camera
- [ ] 69. Broom
- [ ] 70. Guitar (for Tito)
- [x] 71. Lantern (ripple glow toy — coded, no sprite)
- [ ] 72. Soap bubbles

### Mission seeds (tick when designed + shipped)
- [ ] Plaza: feed Xolo, light all candles, runaway balloon
- [ ] Gardens: water 3 beds, butterflies, bouquet for Abuela
- [ ] Bakery: deliver pan dulce, oven smoke, sugar-skull cookie
- [ ] Church: candle path, sit with Doña Luz, lost ribbon
- [ ] Mercado: 3 stall finds, fair trade, kind scare for Cuervo
- [ ] River: skip stone, return lily, watch fish
- [ ] Cemetery: photo + marigold, night fireflies, Abuela memory
- [ ] Parade: start music, line up cast, confetti finale

---

## Phase H — Ship full game

- [ ] 73. Performance pass (night FX + full cast)
- [x] 74. iOS white-screen / lifecycle regression checks (script + manual checklist)
- [ ] 75. Final music / SFX pack
- [ ] 76. Screenshots for all unlocked maps + trailer loop
- [ ] 77. Privacy / kids-friendly age rating pass
- [ ] 78. **v1.0 full** = polished Plaza + ≥3 other locations + mission framework + core 6 cast walks
- [ ] 79. **v1.1+** = remaining locations, interiors, collections

---

## Working rules

1. **Art long pole:** locked walks in Aseprite (or Spine later) — not ChatGPT full sheets.
2. **Code FX first** for water/wind/candles; swap art only when frames are locked.
3. **One plaza great > eight maps mediocre.**
4. After each chunk: bump `pubspec` build, TestFlight, poke on device.
5. Update this file in the same PR as the work.

---

## Obsidian

Open the repo folder (or `docs/`) as an Obsidian vault to check boxes locally. Prefer committing checklist edits so Cursor and git stay aligned — see `docs/OBSIDIAN.md`.
