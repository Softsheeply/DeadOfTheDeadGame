#!/usr/bin/env bash
# Build + upload Day of the Dead to TestFlight.
# Run on a Mac with Xcode, Flutter, and a signed-in Apple Developer account.
#
# IMPORTANT: use the repo clone that tracks this branch, e.g.:
#   cd ~/DeadOfTheDeadGame && git pull && ./scripts/ios_testflight.sh
set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID="${APPLE_TEAM_ID:-67FWLN54W6}"
BUNDLE_ID="com.softsheeply.deadOfTheDeadGame"
# Defaults come from pubspec.yaml (version: name+number) unless overridden.
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"

echo "==> Verifying iOS App Store keys in Info.plist"
python3 - <<'PY'
import plistlib, sys
from pathlib import Path
p = Path("ios/Runner/Info.plist")
info = plistlib.loads(p.read_bytes())
needed = {
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationPortraitUpsideDown",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
}
for key in ("UISupportedInterfaceOrientations", "UISupportedInterfaceOrientations~ipad"):
    have = set(info.get(key, []))
    missing = needed - have
    if missing:
        print(f"FAIL: {key} missing {sorted(missing)}", file=sys.stderr)
        sys.exit(1)
if not info.get("UIRequiresFullScreen"):
    print("FAIL: UIRequiresFullScreen must be true", file=sys.stderr)
    sys.exit(1)
print("OK: orientations + UIRequiresFullScreen")
PY

echo "==> Flutter pub get"
flutter pub get

echo "==> iOS pods"
(cd ios && pod install)

BUILD_ARGS=(--release --export-options-plist=ios/ExportOptions.plist)
if [[ -n "$BUILD_NAME" ]]; then
  BUILD_ARGS+=(--build-name="$BUILD_NAME")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  BUILD_ARGS+=(--build-number="$BUILD_NUMBER")
fi

echo "==> Building IPA (team $TEAM_ID, bundle $BUNDLE_ID)"
flutter build ipa "${BUILD_ARGS[@]}"

IPA="build/ios/ipa/dead_of_the_dead_game.ipa"
if [[ ! -f "$IPA" ]]; then
  # Flutter sometimes names the IPA from the display/product name.
  IPA="$(ls build/ios/ipa/*.ipa | head -n 1)"
fi
echo "==> IPA at $IPA"

# Quick sanity check of the shipped Info.plist inside the IPA.
if command -v unzip >/dev/null; then
  TMP="$(mktemp -d)"
  unzip -qq -d "$TMP" "$IPA" "Payload/*.app/Info.plist" || true
  PLIST="$(find "$TMP/Payload" -name Info.plist | head -n 1 || true)"
  if [[ -n "${PLIST:-}" ]]; then
    echo "==> IPA Info.plist:"
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null | sed 's/^/    version: /' || true
    /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST" 2>/dev/null | sed 's/^/    build: /' || true
    /usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$PLIST" 2>/dev/null | sed 's/^/    minOS: /' || true
    /usr/libexec/PlistBuddy -c 'Print :UIRequiresFullScreen' "$PLIST" 2>/dev/null | sed 's/^/    fullScreen: /' || true
  fi
  rm -rf "$TMP"
fi

if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" && -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  echo "==> Uploading with App Store Connect API key"
  xcrun altool --upload-app --type ios -f "$IPA" \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo "==> Uploading with Apple ID + app-specific password"
  xcrun altool --upload-app --type ios -f "$IPA" \
    -u "$APPLE_ID" -p "$APPLE_APP_SPECIFIC_PASSWORD"
else
  echo "==> IPA built. Upload with Transporter or:"
  echo "    open -a Transporter \"$IPA\""
  echo "Or set APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD and re-run."
fi

echo "Done. In App Store Connect → TestFlight, wait for processing, then add testers."
