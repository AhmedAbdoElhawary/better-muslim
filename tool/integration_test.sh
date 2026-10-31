#!/usr/bin/env bash
#
# Runs the journeys in integration_test/ on the one connected Android device.
#
# Needs: one device in `adb devices`.

set -euo pipefail

cd "$(dirname "$0")/.."

# flutter also lists desktop and web targets, so name the adb device
flutter test integration_test \
  -d "$(adb get-serialno)" \
  --flavor dev \
  --dart-define-from-file=dart_define/dev.json
