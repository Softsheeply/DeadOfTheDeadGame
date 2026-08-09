#!/usr/bin/env bash
# Pre-flight checks for iOS lifecycle / white-screen regressions.
# Run on Mac before TestFlight upload (complements scripts/ios_testflight.sh).
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Pubspec version"
grep '^version:' pubspec.yaml

echo "==> Info.plist lifecycle keys"
python3 - <<'PY'
import plistlib
from pathlib import Path
info = plistlib.loads(Path("ios/Runner/Info.plist").read_bytes())
checks = {
    "UILaunchStoryboardName": info.get("UILaunchStoryboardName"),
    "UIApplicationSupportsIndirectInputEvents": info.get("UIApplicationSupportsIndirectInputEvents"),
    "UIRequiresFullScreen": info.get("UIRequiresFullScreen"),
}
for key, val in checks.items():
    status = "OK" if val else "WARN missing"
    print(f"  {key}: {val!r} ({status})")
orientations = info.get("UISupportedInterfaceOrientations", [])
if "UIInterfaceOrientationLandscapeLeft" in orientations and "UIInterfaceOrientationLandscapeRight" in orientations:
    print("  orientations: OK landscape")
else:
    print("  orientations: FAIL need landscape left+right", orientations)
PY

echo "==> Asset bundles referenced in pubspec"
python3 - <<'PY'
import re
from pathlib import Path
text = Path("pubspec.yaml").read_text()
assets = re.findall(r"^\s*-\s*(.+)$", text, re.M)
required = [
    "assets/data/cast_bios.json",
    "assets/data/locations/l1_festival_plaza.json",
    "assets/images/village/decor_markers.json",
]
missing = [a for a in required if a not in assets]
if missing:
    print("FAIL missing pubspec assets:", missing)
    raise SystemExit(1)
print("OK core JSON assets listed")
PY

echo "==> Flutter analyze (if flutter on PATH)"
if command -v flutter >/dev/null 2>&1; then
  flutter analyze --no-fatal-infos
  flutter test
else
  echo "SKIP flutter not installed on this machine"
fi

echo ""
echo "Manual device pass (recommended each TestFlight):"
echo "  1. Cold launch → plaza visible within 3s (no white screen)"
echo "  2. Background app 30s → resume → plaza still interactive"
echo "  3. Rotate landscape → layout intact"
echo "  4. Toggle mute / reduce motion / photo mode → no crash"
echo "Done."
