#!/usr/bin/env bash
# Build + upload Dead of the Dead to TestFlight.
# Run on a Mac with Xcode, Flutter, and a signed-in Apple Developer account.
set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID="${APPLE_TEAM_ID:-67FWLN54W6}"
BUNDLE_ID="com.softsheeply.deadOfTheDeadGame"
BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%y%m%d%H)}"

echo "==> Flutter pub get"
flutter pub get

echo "==> iOS pods"
(cd ios && pod install)

echo "==> Building IPA (team $TEAM_ID, $BUILD_NAME+$BUILD_NUMBER)"
flutter build ipa \
  --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

IPA="build/ios/ipa/dead_of_the_dead_game.ipa"
if [[ ! -f "$IPA" ]]; then
  # Flutter sometimes names the IPA from the display/product name.
  IPA="$(ls build/ios/ipa/*.ipa | head -n 1)"
fi
echo "==> IPA at $IPA"

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
