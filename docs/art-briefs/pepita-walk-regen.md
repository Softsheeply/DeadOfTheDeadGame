# Pepita walk regen (ChatGPT)

Use this brief when asking ChatGPT for replacement walk sheets. David is **not** using Aseprite — full PNG sheets only.

## Drop zone

```
assets/images/pepita/_incoming/
```

Push to git → tell Cloud Agent → agent re-slices into `walk/down|up|left|right/` and updates `character.json`.

## Locked look (do not drift)

- Chibi Día de los Muertos skeleton florist
- Flower crown, braids, purple embroidered dress, flower basket
- Brown shoes — **must read clearly while walking**
- Palette: see `character.json` → `visualReference.palette`
- Frame size: **192×192**, **8 frames** per direction
- 4 directions only: down, up, left, right (game ignores diagonals)
- Side sheet faces **left**; agent mirrors for right

## Prompt starter (copy/paste)

```
Sprite sheet for a mobile game character walk cycle.

Character: cheerful chibi Day of the Dead skeleton florist girl (Pepita).
Flower crown, braids, purple dress with embroidery, flower basket in hand.
Brown shoes MUST be clearly visible stepping — lift foot off ground on alternating frames.
Long dress OK but do NOT hide feet completely.

Output: 8-frame horizontal walk cycle, 192x192 pixels per frame, transparent background.
Direction: [down | up | left].
Side view faces LEFT only (we mirror for right in code).

Style: clean game sprite, dark outline #3b2146, flat colors, no baked shadow under feet, no glow halo.
Same character design as previous sheet — only improve visible shoe stride.
```

## After you get PNGs

- [ ] One PNG per direction (or labeled clearly)
- [ ] Drop in `_incoming/`
- [ ] Commit + push
- [ ] Message agent: "Pepita walks in _incoming, please re-slice"

## Related

- [[pepita]]
- [[FINISH_PLAN#Character art (locked walks — Aseprite, not ChatGPT sheets)|Finish plan #7–8]]

#pepita #art-brief #phase-a
