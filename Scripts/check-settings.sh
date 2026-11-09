#!/bin/bash
# Simulator-only validation. Never archives, signs, packages an IPA or publishes.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
[[ "$(uname -s)" == Darwin ]] || { echo "Requires a Mac with Xcode." >&2; exit 1; }
out=$(mktemp -d "$PWD/.settings-check-XXXXXXXX")
finish() {
  local status=$?
  trap - EXIT
  for result in "$out"/*.xcresult; do
    [[ -d "$result" ]] || continue
    local name
    name=$(basename "$result" .xcresult)
    xcrun xcresulttool get test-results summary --path "$result" --format json > "$out/$name-summary.json" || echo "Summary failed: $name" >&2
    xcrun xcresulttool export attachments --path "$result" --output-path "$out/attachments/$name" > "$out/$name-attachments.log" 2>&1 || echo "Attachment export failed: $name" >&2
  done
  git rev-parse HEAD > "$out/commit.txt"
  echo "$status" > "$out/native-exit-code.txt"
  exit "$status"
}
trap finish EXIT
run() {
  local name=$1
  shift
  if xcodebuild "$@" > "$out/$name.log" 2>&1; then
    if command -v xcsift >/dev/null; then xcsift < "$out/$name.log" || tail -30 "$out/$name.log"; else tail -30 "$out/$name.log"; fi
  else
    local status=$?
    tail -100 "$out/$name.log" >&2
    return "$status"
  fi
}
xcodebuild -version > "$out/toolchain.log"
swift --version >> "$out/toolchain.log"
phone=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; a=[v for vs in json.load(sys.stdin)["devices"].values() for v in vs if "iPhone" in v["name"]]; print(next((v["udid"] for v in a if "SE" in v["name"] or "16e" in v["name"]),a[0]["udid"]))')
pad=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; print(next(v["udid"] for a in json.load(sys.stdin)["devices"].values() for v in a if "iPad" in v["name"]))')
xcrun simctl boot "$phone" 2>/dev/null || true
xcrun simctl bootstatus "$phone" -b
xcrun simctl ui "$phone" appearance light
run unit test -project Tendelm.xcodeproj -scheme Tendelm -destination "platform=iOS Simulator,id=$phone" \
  -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/Unit.xcresult" -only-testing:TendelmTests CODE_SIGNING_ALLOWED=NO
run settings test-without-building -project Tendelm.xcodeproj -scheme Tendelm -destination "platform=iOS Simulator,id=$phone" \
  -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/Settings.xcresult" \
  -only-testing:TendelmUITests/SettingsPresentationUITests -only-testing:TendelmUITests/HabitThemePickerTests \
  -only-testing:TendelmUITests/PasteImportTests -only-testing:TendelmUITests/DayStartPickerTests \
  -only-testing:TendelmUITests/DevModeSwapTests \
  -only-testing:TendelmUITests/RecentlyDeletedUITests/testGroupedSettingsAtLargeText \
  -only-testing:TendelmUITests/RecentlyDeletedUITests/testTodayDeleteAndRestoreSurviveRelaunch \
  -only-testing:TendelmUITests/RecentlyDeletedUITests/testCardsAndOverviewDeleteSelection \
  -parallel-testing-enabled NO -test-timeouts-enabled YES -default-test-execution-time-allowance 360 \
  -maximum-test-execution-time-allowance 420 CODE_SIGNING_ALLOWED=NO
xcrun simctl ui "$phone" appearance dark
run dark test-without-building -project Tendelm.xcodeproj -scheme Tendelm -destination "platform=iOS Simulator,id=$phone" \
  -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/Dark.xcresult" -only-testing:TendelmUITests/SettingsPresentationUITests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
xcrun simctl boot "$pad" 2>/dev/null || true
xcrun simctl bootstatus "$pad" -b
xcrun simctl ui "$pad" appearance light
run ipad test-without-building -project Tendelm.xcodeproj -scheme Tendelm -destination "platform=iOS Simulator,id=$pad" \
  -derivedDataPath "$out/DerivedData" -resultBundlePath "$out/iPad.xcresult" \
  -only-testing:TendelmUITests/SettingsPresentationUITests \
  -only-testing:TendelmUITests/PasteImportTests/testHistoryPastePreviewCancelAndRepeatImport \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
echo "Simulator validation complete. No IPA was built."
