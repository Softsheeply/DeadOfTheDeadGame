# Pepita animation fix brief

Device TestFlight notes (build 39): magnified face / sliced-in-half / backwards walk.

## Root cause found — idle_down breathe

Grid slice produced **broken frames** in `idle/down/`:

| Frame | Content width (alpha bbox) | Issue |
|-------|---------------------------|--------|
| `00` | ~28 px | Vertical sliver — reads as giant face when scaled |
| `03` | ~15 px | Same |
| `01`, `02`, `05`, `06` | ~126 px | Full body OK |
| `04`, `07` | ~78 px | Partial — OK for subtle breathe |

**Hotfix (shipped):** `character.json` uses single frame `idle_down_01` until re-slice.

## Tomorrow — animation sprint

1. Re-run `scripts/slice_pepita_incoming.py` with validation:
   - Reject any normalized frame whose alpha bbox width `< 60` px
   - Log frame index + path when rejected
2. Re-export 6–8 frame `idle_down` breathe from source sheet `a656ed79-…png`
3. Verify **walk_left** / **walk_right** facing matches movement (backwards walk report)
4. Walk cycle: confirm feet land on cobble (stride vs fps in `resident.dart`)
5. Optional: re-enable coded idle breathe only after all frames pass bbox check
6. **Door tap:** removed coded `BuildingDoorPulse` — replace later with real door art (#21)

## Walk / skip sheets

Walk and skip bbox widths look consistent (~90–130 px). Backwards walk is likely facing mismatch on L/R sheets or direction hysteresis — verify on device after idle fix.
