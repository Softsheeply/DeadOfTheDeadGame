# Mac git sync — when push is rejected or pull says "divergent branches"

Your Tito frames are in a **local commit**. Remote moved ahead. Run **one line at a time** from repo root:

```bash
cd "/Users/user/Desktop/Day of the Dead/Repo Clone/DayoftheDead"
git fetch origin cursor/pocket-god-village-foundation-b7dc
git stash push -u -m "wip before tito push"
git checkout -- scripts/slice_character_incoming.py
git rebase origin/cursor/pocket-god-village-foundation-b7dc
```

If rebase stops with **conflicts** (often `pubspec.yaml`):

```bash
git status
git add pubspec.yaml assets/images/tito/
git rebase --continue
```

If rebase says "nothing to commit" or you're stuck:

```bash
git rebase --abort
git merge origin/cursor/pocket-god-village-foundation-b7dc
git add pubspec.yaml assets/images/tito/
git commit -m "Merge remote; keep Tito walk down/up"
```

Then push:

```bash
git push origin cursor/pocket-god-village-foundation-b7dc
git stash pop
```

After pull succeeds once, future syncs:

```bash
./scripts/mac_sync_branch.sh
```

**You do not need Pillow on Mac** if `assets/images/tito/walk/down/` already has 8 PNGs.
