# Using Obsidian with this project

## What Obsidian is for

**Obsidian** is a local markdown notes app. Your “vault” is just a folder of `.md` files. It gives you:

- Backlinks and a graph between notes
- Checkboxes that toggle in the UI
- Daily notes, tags, search
- No account required for local use

It is **not** a game engine, art tool, or Task manager that replaces git — it’s a brain for writing and tracking ideas.

## Is it useful for Day of the Dead?

**Yes, if you use it as the reading/editing UI for this repo’s docs.**

Good uses:
- Tick boxes in `docs/FINISH_PLAN.md`
- Location brainstorm notes (`docs/locations/…`)
- Cast bios, mission drafts, art brief per character
- Link “Pepita walks” ↔ “Phase A” ↔ TestFlight notes

Less useful:
- Replacing GitHub / PRs
- Storing huge binary art (keep art in `assets/`, not only in the vault)
- A second copy of the checklist that drifts from git

## Recommended setup

1. Open Obsidian → **Open folder as vault**
2. Choose either:
   - **`~/DeadOfTheDeadGame`** (whole repo), or
   - **`~/DeadOfTheDeadGame/docs`** (docs only)
3. Pin `FINISH_PLAN.md`
4. When you check items, **commit** those markdown changes (or ask the cloud agent to sync) so the living checklist stays one source of truth

## Optional vault layout

```
docs/
  FINISH_PLAN.md      ← master checklist (in git)
  OBSIDIAN.md         ← this file
  locations/          ← one note per map (optional)
  cast/               ← bios / animation status (optional)
  missions/           ← quest drafts (optional)
```

Create location/cast notes as you need them; don’t block shipping on perfect wiki structure.

## Sync tip

If Obsidian Sync or iCloud also touches the repo, avoid editing the same file on two machines without pulling first — treat git as canonical.
