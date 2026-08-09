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
- Tick boxes in [[FINISH_PLAN]]
- Location brainstorm notes (`docs/locations/…`)
- Cast bios, mission drafts, art brief per character
- Link “Pepita walks” ↔ “Phase A” ↔ TestFlight notes

Less useful:
- Replacing GitHub / PRs
- Storing huge binary art (keep art in `assets/`, not only in the vault)
- A second copy of the checklist that drifts from git

---

## Setup (you already have Obsidian — ~2 minutes)

### 1. Open the vault

1. Obsidian → **Open folder as vault**
2. Choose your **real git clone** (must contain `pubspec.yaml`):
   ```
   ~/DeadOfTheDeadGame
   ```
   Not Desktop art folders — the clone you push from.

### 2. Pull latest (includes starter notes)

```bash
cd ~/DeadOfTheDeadGame
git pull
git checkout cursor/pocket-god-village-foundation-b7dc   # or main after merge
```

### 3. Pin the dashboard

1. Open **`docs/Home.md`** — project hub with links to everything
2. Right-click tab → **Pin**
3. Also pin **`docs/FINISH_PLAN.md`**

### 4. Try these features (60 seconds each)

| Feature | How |
|---------|-----|
| **Wikilinks** | In `Home.md`, click `[[pepita]]` → jumps to cast note |
| **Backlinks** | Open `docs/cast/pepita.md` → right panel “Backlinks” shows what links here |
| **Graph** | Ribbon → **Open graph view** → see plaza ↔ pepita ↔ art brief |
| **Checkboxes** | Open `FINISH_PLAN.md` → click any `- [ ]` box to toggle |
| **Tags** | Search `tag:#phase-a` or click `#pepita` in a note |
| **Quick switcher** | `Cmd+O` → type “pepita” or “finish” |

### 5. Keep git in sync

When you check items or edit notes:

```bash
git add docs/
git commit -m "Update finish plan from Obsidian"
git push
```

Or ask the Cloud Agent to commit doc updates. **Uncommitted Obsidian edits are invisible to the agent.**

---

## Starter vault layout (in repo)

```
docs/
  Home.md                 ← start here (dashboard)
  FINISH_PLAN.md          ← master checklist (in git)
  OBSIDIAN.md             ← this file
  cast/
    pepita.md             ← character status + links
  art-briefs/
    pepita-walk-regen.md  ← ChatGPT prompt to copy
  missions/
    plaza-loop.md         ← shipped mission chain
  locations/
    l1-festival-plaza.md  ← current map status
```

Add more notes anytime (`docs/cast/xolo.md`, etc.). Don’t block shipping on perfect wiki structure.

---

## Optional: docs-only vault

If opening the whole repo feels noisy (Flutter `build/`, etc.):

1. Open **`~/DeadOfTheDeadGame/docs`** as the vault instead
2. Wikilinks like `[[FINISH_PLAN]]` still work inside `docs/`
3. You won’t see `lib/` in the file tree — use Cursor for code

---

## Sync tip

If Obsidian Sync or iCloud also touches the repo, avoid editing the same file on two machines without pulling first — treat git as canonical.

---

## What the Cloud Agent sees

| You do in Obsidian | Agent sees? |
|--------------------|-------------|
| Edit + commit + push | ✅ Yes |
| Local checkbox toggle only | ❌ No |
| New note in `docs/` + push | ✅ Yes |

The agent reads **`docs/FINISH_PLAN.md`** and linked notes from git — not your Obsidian app directly.
