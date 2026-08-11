# Cast walk pipeline (all 12 characters)

Same flow as Pepita build **+42**, generalized for every plaza resident.

## Drop art

For each character, save ChatGPT 4×2 grid sheets into:

`assets/images/{character_id}/_incoming/`

| File | Becomes |
|------|---------|
| `{id}_walk_down.png` | walk down (front) |
| `{id}_walk_up.png` | walk up (back) |
| `{id}_walk_left.png` | walk left (+ mirrored right) |
| `{id}_idle_down.png` | single idle frame |

Pepita also accepts `pepita_walk_*.png` and legacy UUID filenames.

## Slice

```bash
pip3 install -r scripts/requirements-slice.txt
python3 scripts/slice_character_incoming.py --character abuela_rosa
python3 scripts/slice_character_incoming.py --all   # any character with files in _incoming
```

Frame sizes: **Pepita 192×192**, everyone else **128×128** (matches `character.json`).

## Art order (FINISH_PLAN)

Pepita ✓ → Abuela Rosa → Xolo → Gato → Tito → Miguel → Doña Luz → Chavo → Don Mateo → Pinto → Alebrije → Cuervo

Walk left must show **alternating feet** or characters will glide on cobble (code fallback only helps Pepita-era art).
