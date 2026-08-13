# Tito walk sheets — art brief

**Style lock:** match `idle/down/tito_idle_down_00.png` — genuine **calavera skull face** (hollow triangular nose, skull proportions), not the softer human face from some ChatGPT side views.

## Decisions (Aug 2026)

| Sheet | Action |
|-------|--------|
| walk_down (74c1112f…) | **Slice now** — matches skull style |
| walk_up (5bbd4ef1…) | **Slice now** — matches skull style |
| walk_left (side view) | **Redo** — current export has human face; regenerate with skull lock |
| Image 4 (16-variant grid) | **Ignore** — exploration only |

## Drop + slice

Put PNGs in `assets/images/tito/_incoming/` as either:

- `tito_walk_down.png` / `tito_walk_up.png`, **or**
- raw UUID names (`74c1112f-….png`, `5bbd4ef1-….png`) — slice script auto-detects prefixes

**Slice on cloud agent or any machine with Pillow** (Mac PEP 668 often blocks `pip3 install` globally):

```bash
pip3 install -r scripts/requirements-slice.txt   # or use a venv
python3 scripts/slice_character_incoming.py --character tito
```

If frames are already in `walk/down/` and `walk/up/`, skip slice — just sync git:

```bash
./scripts/mac_sync_branch.sh
```

Then add to `pubspec.yaml` under tito assets:

```yaml
    - assets/images/tito/walk/down/
    - assets/images/tito/walk/up/
```

## walk_left regen prompt (when ready)

Attach **idle_down** + approved **walk_down** as design lock. Request:

> 4×2 walk cycle, side view facing LEFT, mariachi Tito with trumpet.  
> **Same calavera skull face as idle** — hollow nose, no human nose/cheek dots.  
> Black charro suit, gold trim, sombrero. Alternating feet (not same foot every frame).  
> Transparent or solid black background. 128px-friendly character scale.

## Known art quirks

- **walk_down frame 0 leg ghosting** may be baked into ChatGPT source (motion blur), not a slice bug — verify on magenta check before re-prompting.
- Black mariachi suit triggers strip fallback (70% opaque retain threshold) — expected; pipeline uses source alpha.
