#!/usr/bin/env bash
# Captures README screenshots from the iOS simulator using the harness in
# tool/screenshots/main.dart. Usage: tool/screenshots/capture.sh [udid]
#
# Each screen is a separate build because the screen is selected with a
# compile-time --dart-define (simctl launch env vars do not reach Dart).
set -euo pipefail

cd "$(dirname "$0")/../.."
UDID="${1:-$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)}"
BUNDLE_ID=com.example.remote
APP=build/ios/iphonesimulator/Runner.app
OUT=docs/screenshots

[ -n "$UDID" ] || { echo "no booted simulator"; exit 1; }
mkdir -p "$OUT"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3

for screen in picker remote dialog; do
  flutter build ios --simulator --debug -t tool/screenshots/main.dart \
    --dart-define=SCREEN="$screen" >/dev/null
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot --type png "$OUT/$screen.png" 2>/dev/null
  sips --resampleWidth 600 "$OUT/$screen.png" >/dev/null
  echo "captured $OUT/$screen.png"
done

xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$UDID" clear
