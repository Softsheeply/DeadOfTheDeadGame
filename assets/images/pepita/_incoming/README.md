# Pepita incoming art

Save ChatGPT PNG exports here, then from repo root:

```bash
python3 scripts/slice_pepita_incoming.py
git add assets/images/pepita/
git commit -m "Re-slice Pepita walks"
git push
```

## Friendly filenames (preferred)

| File | Becomes |
|------|---------|
| `pepita_walk_down.png` | `walk/down/` (8 frames, front view) |
| `pepita_walk_up.png` | `walk/up/` (back view) |
| `pepita_walk_left.png` | `walk/left/` + mirrored `walk/right/` |
| `pepita_walk_right.png` | `walk/right/` only (optional if left exists) |
| `pepita_idle_down.png` | single `idle/down/` frame |

4×2 grid sheets (4 columns, 2 rows). Transparent or black background OK.

## After slicing

Cloud Agent or local: bump build + TestFlight.

Walk left must show **both** feet leading (not same foot every frame) or she will glide on device.
