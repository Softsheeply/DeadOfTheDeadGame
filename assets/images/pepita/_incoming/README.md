# Pepita incoming art

Save ChatGPT PNGs with friendly names **or** drop UUID-named exports — agent maps:

- `24edaf07-...` / `pepita_walk_down.png` → walk down (front)
- `79c5fa2b-...` / `pepita_walk_up.png` → walk up (back)
- `33e2e64d-...` / `pepita_walk_left.png` → walk left (+ mirrored right)

Install Pillow once, then slice:

```bash
pip3 install -r scripts/requirements-slice.txt
python3 scripts/slice_pepita_incoming.py
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
