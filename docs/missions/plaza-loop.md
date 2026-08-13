# Plaza mission loop #1

**Status:** Shipped ✅  
**Code:** `lib/game/spirit_village_game.dart` · atmosphere / tap zones

## Chain (loops)

1. **Ofrenda** — marigold petals at painted zone
2. **Mariachi** — music beat
3. **Xolo** — treat / feed
4. **Candles** — tap painted UV zones (petals at finger, **no coded glow orbs**)

## Design rules (hold the line)

- Night art already paints candles, lanterns, windows — **no fake light overlays**
- Candle taps use painted UV hit zones only
- Hybrid direction: animate **one real prop at a time** when art exists

## Tests

- `test/plaza_mission_test.dart`

## Future (not now)

- Rare idle events (star, balloon) — [[FINISH_PLAN#Plaza feel|#28]]
- Skippable tutorial beads — [[FINISH_PLAN#Plaza feel|#29]]
- Phase B mission framework — **deferred**

## Related

- [[l1-festival-plaza]]
- [[FINISH_PLAN#Plaza feel]]

#mission #plaza #phase-a
