#!/usr/bin/env bash
#
# Runs the journeys in integration_test/ on the one connected Android device.
#
# Needs: one device in `adb devices`.

set -euo pipefail

cd "$(dirname "$0")/.."

log="$(mktemp)"
failed=()
for test in integration_test/*_test.dart; do
  # on ci the emulator quits when a journey's app is stopped, so boot it again for the next one
  if [ -n "${CI:-}" ] && [ "$(adb get-state 2>/dev/null)" != device ]; then
    pkill -f qemu-system || true
    sleep 2
    "$ANDROID_HOME/emulator/emulator" -port 5554 -avd test -no-window -gpu swiftshader_indirect \
      -no-snapshot -noaudio -no-boot-anim >/dev/null 2>&1 &
    adb wait-for-device
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do sleep 2; done
  fi

  # that quit also loses the run's summary and exit code, so a journey counts by its own line
  # flutter also lists desktop and web targets, so name the adb device
  flutter test "$test" \
    -r github \
    -d "$(adb get-serialno)" \
    --flavor dev \
    --dart-define-from-file=dart_define/dev.json | tee "$log" || true
  if ! grep -q '^✅ ' "$log" || grep -q '❌' "$log"; then failed+=("$test"); fi
done

if [ ${#failed[@]} -gt 0 ]; then
  printf 'failed: %s\n' "${failed[@]}"
  exit 1
fi
