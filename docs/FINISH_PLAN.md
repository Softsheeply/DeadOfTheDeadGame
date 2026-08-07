# Day of the Dead — Finish Plan (living checklist)

> Pocket God / living-world first. **Reuse cast across locations.**  
> Soft launch = Phase A. Full game ≈ through Phase H.  
> Check boxes as you go. Keep this file the source of truth in git.

**Current build target:** `1.0.0+18` (plaza prototype on TestFlight)  
**Branch:** `cursor/pocket-god-village-foundation-b7dc`

---

## Already done (baseline)

- [x] Living plaza prototype (contain-fit day/night art)
- [x] Cast invite / send off (persisted)
- [x] Toys: wind, petals, music, pan dulce
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

---

## Phase A — Plaza “finished” (soft launch)

### Store / chrome
- [ ] 1. App icon (unique) — drop `assets/branding/app_icon_1024.png`, run `dart run flutter_launcher_icons`
- [ ] 2. Launch image (unique)
- [x] 3. Settings sheet (mute, reduce motion, credits)
- [x] 4. Save: missions + day/night + cast + mute
- [ ] 5. Store listing copy + plaza screenshots
- [ ] 6. Soft-launch TestFlight / App Store build from polished plaza

### Character art (locked walks — Aseprite, not ChatGPT sheets)
- [ ] 7. Pepita walk down / up / left / right (locked model)
- [ ] 8. Pepita L/R are true mirrors; wire into `character.json`
- [ ] 9. Abuela Rosa locked walks
- [ ] 10. Xolo locked walks
- [ ] 11. Gato locked walks
- [ ] 12. Idle blink / breathing sprites for main 4
- [ ] 13. Real sit / wave / smell sprites (replace squash hacks)

### Pick up & move (all characters)
- [ ] 14. Verify **every** cast member (all 12) can be grabbed, dragged, and flung on device (hitbox/visual alignment fixed — re-test on device)
- [ ] 15. Reliable hit boxes (big heads / small critters — no missy taps)
- [x] 16. Pickup juice: scale-up, shadow, “held” pose / SFX
- [x] 17. Drop / fling lands on walkable cobble only (not roofs, fountain bowl, river)
- [x] 18. Soft collision so held characters don’t stack invisibly
- [x] 19. Tutorial bead: “Drag anyone — they’re toys”

### Plaza feel
- [ ] 20. True depth cutouts (fountain rim, tree, bridge)
- [ ] 21. Building door open/close (florist, bakery, church, mercado)
- [ ] 22. Tap building → richer status / micro beat
- [ ] 23. Bench sit looks correct
- [ ] 24. Ofrenda as clear tappable prop
- [ ] 25. Better plaza music bed (replace placeholder WAVs)
- [ ] 26. Polish toy SFX
- [x] 27. Mission set #1: 4 looping plaza chores (marigolds → mariachi → Xolo → candles)
- [ ] 28. Rare idle events (star, balloon, parade tease)
- [ ] 29. Skippable 90s tutorial beads

**Exit criteria:** strangers enjoy poking the plaza 5+ minutes; Pepita walk no longer embarrasses you.

---

## Phase B — Systems for 8 locations

- [ ] 24. World map / travel UI (8 nodes; Plaza unlocked first)
- [ ] 25. Location data format (day/night, road, blockers, hotspots, buildings, missions)
- [ ] 26. Shared cast travel / “who is here”
- [ ] 27. Mission framework (goals, chains, rewards, daily refresh)
- [ ] 28. Light inventory (marigold, pan dulce, candle, key…)
- [ ] 29. Reward juice (sparkles, cast react, unlock toast)
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
- [ ] 53. NPC–NPC bench chats (flavor)
- [ ] 54. Door schedules day vs night
- [ ] 55. Hidden interactables (careful with walk rules)

---

## Phase F — Menus & meta

- [ ] 56. Main menu (Play / Continue / Settings / Credits)
- [ ] 57. Pause + map always available
- [ ] 58. Cast journal (bios)
- [ ] 59. Mission log (active / done)
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
- [ ] 71. Lantern
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
- [ ] 74. iOS white-screen / lifecycle regression checks
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
