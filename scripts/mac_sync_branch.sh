#!/usr/bin/env bash
# Fix "local changes would be overwritten" then push your Tito (or other) commit.
# Run from repo root on Mac — no Pillow needed if frames are already sliced.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Discard local slice-script edits (cloud has the canonical version)"
git checkout -- scripts/slice_character_incoming.py 2>/dev/null || true

echo "==> Rebase onto remote branch"
git pull --rebase origin cursor/pocket-god-village-foundation-b7dc

echo "==> Push"
git push origin cursor/pocket-god-village-foundation-b7dc

echo "OK — remote is up to date."
