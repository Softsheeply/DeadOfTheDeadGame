#!/usr/bin/env bash
# Push local commits (e.g. Tito art) when branch diverged from remote.
# Stashes unstaged work, rebases onto origin, pushes, restores stash.
set -euo pipefail
cd "$(dirname "$0")/.."
BRANCH="${1:-cursor/pocket-god-village-foundation-b7dc}"

echo "==> Fetch $BRANCH"
git fetch origin "$BRANCH"

echo "==> Stash unstaged changes (if any)"
git stash push -u -m "mac_sync_branch autostash $(date +%Y%m%d-%H%M%S)" || true

echo "==> Discard local slice-script edits (remote is canonical)"
git checkout -- scripts/slice_character_incoming.py 2>/dev/null || true

echo "==> Rebase local commits onto origin/$BRANCH"
git rebase "origin/$BRANCH"

echo "==> Push"
git push origin "$BRANCH"

if git stash list | grep -q "mac_sync_branch autostash"; then
  echo "==> Restore stashed changes"
  git stash pop || echo "Note: stash pop had conflicts — run 'git stash list' and resolve manually"
fi

echo "OK — pushed to origin/$BRANCH"
