# Pepita

**Role:** Florist · chibi skeleton · flower crown, braids, purple dress, basket  
**Status:** Incoming sheets v2 wired (walk + skip + idle breathe) — **feet TBD on device**  
**Code:** `assets/images/pepita/character.json` · `lib/game/resident.dart`

## Links

- [[FINISH_PLAN#Character art (locked walks — Aseprite, not ChatGPT sheets)|Phase A items 7–8]]
- [[pepita-walk-regen]] — ChatGPT prompt for better sheets
- [[l1-festival-plaza]] — home location

## Animation status

| State | Status | Notes |
|-------|--------|-------|
| Walk down/up/left/right | ✅ wired | Re-sliced from `_incoming/` v2 |
| Skip down/up/left/right | ✅ wired | ~28% of autonomous roam trips |
| Idle down | ✅ | 8-frame breathe cycle |
| Idle left/right/up | ✅ | Single frame from idle sheet |
| Feet / stride | ⚠️ | Fresh slices — verify on device (+31) |
| Held / carried | ❌ | Later when sheet exists |
| Sit / wave / smell | ❌ | Squash hacks — [[FINISH_PLAN#Character art (locked walks — Aseprite, not ChatGPT sheets)|#13]] |

## Art pipeline (David)

1. Generate in ChatGPT (not Aseprite) — use [[pepita-walk-regen]]
2. Save PNGs to `assets/images/pepita/_incoming/`
3. Push to git (real clone with `pubspec.yaml`)
4. Cloud Agent re-slices → `walk/` folders + `character.json`

## Open issues

- Long dress + tiny shoes in source art
- `anchors.feet` in JSON not read by code yet
- Slight roof clip near doghouse — accepted for now

#pepita #phase-a #cast
