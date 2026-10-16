#!/usr/bin/env bash
#
# Runs the journeys in integration_test/ on the one connected Android device.
#
# Needs: one device in `adb devices`.

set -euo pipefail

cd "$(dirname "$0")/.."

# TODO(ahmed): start a fake backend here and point API_BASE_URL at it with --dart-define, never let journeys hit the real dev server.
# flutter also lists desktop and web targets, so name the adb device
flutter test integration_test \
  -d "$(adb get-serialno)" \
  --flavor dev \
  --dart-define-from-file=dart_define/dev.json
