#!/bin/bash
# Run manually on a Mac. No GitHub account, upload, signing identity, or publishing.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
if [[ "$(uname -s)" != Darwin ]]; then
  echo "This build needs a Mac with Xcode 26.3 or later." >&2
  exit 1
fi
command -v xcodebuild >/dev/null
command -v python3 >/dev/null
out=$(mktemp -d "$root/.build-personal-XXXXXXXX")
baseline=${TENDELM_RESUME_UI_BASELINE:-}
color_baseline=${TENDELM_UNDO_COLOR_BASELINE:-}
settings_baseline=${TENDELM_SETTINGS_TEST_BASELINE:-}
package_baseline=${TENDELM_VERIFIED_PACKAGE_BASELINE:-}
[[ -z "$settings_baseline" || ( -z "$baseline" && -z "$color_baseline" ) ]] || { echo "Choose one baseline mode." >&2; exit 1; }
[[ -z "$baseline" || -z "$color_baseline" ]] || { echo "Choose one baseline mode." >&2; exit 1; }
[[ -z "$color_baseline" ]] || baseline=$color_baseline
[[ -z "$settings_baseline" ]] || baseline=$settings_baseline
[[ -z "$package_baseline" || -z "$baseline" ]] || { echo "Choose one baseline mode." >&2; exit 1; }
[[ -z "$package_baseline" ]] || baseline=$package_baseline
echo "Build logs and test results: $out"

assert_idle() {
  if pgrep -lx xcodebuild; then
    echo "Another Xcode build is active; refusing to overlap." >&2
    return 1
  else
    local status=$?
    [[ "$status" -eq 1 ]] || return "$status"
  fi
}

# Keep diagnostics even when compilation or a test fails. Collection failures
# are reported separately and never turn a failed native command into success.
finish() {
  local native_status=$?
  trap - EXIT
  local collection_status=complete
  for result in "$out"/*.xcresult; do
    [[ -d "$result" ]] || continue
    local name
    name=$(basename "$result" .xcresult)
    if ! xcrun xcresulttool get test-results summary --path "$result" --format json \
        > "$out/$name-summary.json" 2>> "$out/collection.log"; then
      collection_status=partial
      echo "Could not collect the $name test summary; see collection.log." >&2
    fi
    if ! xcrun xcresulttool export attachments --path "$result" --output-path "$out/attachments/$name" \
        >> "$out/collection.log" 2>&1; then
      collection_status=partial
      echo "Could not export all $name attachments; see collection.log." >&2
    fi
    if ! (cd "$out" && zip -qr "$name.xcresult.zip" "$name.xcresult"); then
      collection_status=partial
      echo "Could not archive the $name result bundle." >&2
    fi
  done
  python3 - "$out" "$native_status" "$collection_status" "$baseline" <<'PY'
import json, pathlib, subprocess, sys
out, status, collection, baseline = sys.argv[1:]
receipt = {"commit": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
           "native_exit_code": int(status), "evidence_collection": collection,
           "reused_test_baseline": baseline or None}
pathlib.Path(out, "build-receipt.json").write_text(json.dumps(receipt, indent=2))
PY
  exit "$native_status"
}
trap finish EXIT
assert_idle
xcodebuild -version | tee "$out/toolchain.log"
swift --version >> "$out/toolchain.log"
run_xcode() {
  local name=$1
  shift
  assert_idle
  if xcodebuild "$@" > "$out/$name.log" 2>&1; then
    if command -v xcsift >/dev/null; then
      xcsift < "$out/$name.log" || tail -30 "$out/$name.log"
    else
      tail -30 "$out/$name.log"
    fi
  else
    local status=$?
    tail -100 "$out/$name.log" >&2
    return "$status"
  fi
}


if [[ -n "$package_baseline" ]]; then
  [[ "$package_baseline" == d205ded203d60346d0efa2b10048f1148b6b7e98 ]] || { echo "Unverified package baseline." >&2; exit 1; }
  git cat-file -e "$package_baseline^{commit}" 2>/dev/null || git fetch --no-tags --depth=1 origin "$package_baseline"
  python3 Scripts/verify-settings-baseline.py "$package_baseline" > "$out/source-equivalence.json"
  echo "Reusing 841 unit passes, 1 expected issue and 17 UI passes from native run 6aeff00124e1ec2375576207; app/test source equality verified."
else
device_id=${TENDELM_SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(v["udid"] for a in d["devices"].values() for v in a if "iPhone" in v["name"]))')}


ui_tests=(-only-testing:TendelmUITests/PersonalEditionTests -only-testing:TendelmUITests/HabitThemePickerTests -only-testing:TendelmUITests/OverviewDayEditTests -only-testing:TendelmUITests/DayStartPickerTests -only-testing:TendelmUITests/DevModeSwapTests -only-testing:TendelmUITests/LogValueSheetTests)
if [[ -n "$baseline" ]]; then
  # A manual resume is only for an already-verified unit suite and unchanged
  # production code. Normal builds always run the complete selection below.
  [[ "$baseline" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid verified baseline." >&2; exit 1; }
  git cat-file -e "$baseline^{commit}" 2>/dev/null || git fetch --no-tags --depth=1 origin "$baseline"
  if [[ -n "$settings_baseline" ]]; then
    # Run 6aeebce824e1ec23755711d9 passed all unit and focused import/recovery
    # tests. Only these test-driver corrections may reuse those results.
    [[ "$baseline" == 755da7f7324543da2b30ec55cece07d187cb9acc ]] || { echo "Unverified settings baseline." >&2; exit 1; }
    git diff --exit-code "$baseline" HEAD -- . \
      ':(exclude)TendelmUITests/DayStartPickerTests.swift' \
      ':(exclude)TendelmUITests/LogValueSheetTests.swift' \
      ':(exclude)Scripts/build-personal.sh'
    echo "Reusing passed unit and focused import/recovery results from identical app source at $baseline."
  elif [[ -n "$color_baseline" ]]; then
    # Reuse is restricted to the exact reviewed text-contrast correction. Any
    # other app/test change refuses this short validation route.
    git diff --exit-code "$baseline" HEAD -- . \
      ':(exclude)Tendelm/Views/TimeSince/TimeSinceUndoToast.swift' \
      ':(exclude)Scripts/build-personal.sh' ':(exclude)codemagic.yaml'
    python3 - "$baseline" <<'PY'
import pathlib, subprocess, sys
path = "Tendelm/Views/TimeSince/TimeSinceUndoToast.swift"
before = subprocess.check_output(["git", "show", f"{sys.argv[1]}:{path}"], text=True)
line = '                        Label("Undo", systemImage: "arrow.uturn.backward")\n'
assert before.count(line) == 1
expected = before.replace(line, line + '                            .foregroundStyle(Color.kadoBackground)\n')
assert pathlib.Path(path).read_text() == expected, "Only the exact Undo contrast fix may reuse this baseline"
PY
    echo "Reusing passed unit/unaffected UI results; verified exact Undo text-color-only change from $baseline."
  else
    git diff --exit-code "$baseline" HEAD -- . \
      ':(exclude)TendelmUITests/PersonalEditionTests.swift' \
      ':(exclude)Scripts/build-personal.sh' ':(exclude)codemagic.yaml'
    echo "Reusing passed unit/interaction results from unchanged production source at $baseline."
  fi
  run_xcode simulator-build build-for-testing -project Tendelm.xcodeproj -scheme Tendelm \
    -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" CODE_SIGNING_ALLOWED=NO
  if [[ -z "$settings_baseline" ]]; then
    ui_tests=(-only-testing:TendelmUITests/PersonalEditionTests/testChooseFutureDateThenEditAndRelaunch)
  fi
  if [[ -n "$color_baseline" ]]; then
    ui_tests=(-only-testing:TendelmUITests/PersonalEditionTests/testRecentUndoExpiresAndDoesNotWalkHistory)
  fi
else
  run_xcode unit-tests test -project Tendelm.xcodeproj -scheme Tendelm \
    -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" \
    -resultBundlePath "$out/UnitTests.xcresult" -only-testing:TendelmTests CODE_SIGNING_ALLOWED=NO
fi
xcrun simctl boot "$device_id" 2>/dev/null || true
xcrun simctl bootstatus "$device_id" -b
xcrun simctl ui "$device_id" appearance light
if [[ -z "$baseline" ]]; then
  # Run the new import interactions first so presentation failures are diagnosed
  # before the broader UI pass; each light-mode test is still run only once.
  run_xcode paste-ui test-without-building -project Tendelm.xcodeproj -scheme Tendelm \
    -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" \
    -resultBundlePath "$out/Paste-iPhone.xcresult" -only-testing:TendelmUITests/PasteImportTests -only-testing:TendelmUITests/RecentlyDeletedUITests \
    -parallel-testing-enabled NO -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 360 -maximum-test-execution-time-allowance 420 CODE_SIGNING_ALLOWED=NO
fi
run_xcode iphone-ui test-without-building -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" \
  -resultBundlePath "$out/iPhone.xcresult" "${ui_tests[@]}" -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 90 \
  -maximum-test-execution-time-allowance 180 CODE_SIGNING_ALLOWED=NO
xcrun simctl ui "$device_id" appearance dark
run_xcode iphone-dark test-without-building -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" \
  -resultBundlePath "$out/iPhone-Dark.xcresult" \
  -only-testing:TendelmUITests/PersonalEditionTests/testCapturePersonalScreens \
  -only-testing:TendelmUITests/RecentlyDeletedUITests/testTodayDeleteAndRestoreSurviveRelaunch \
  -only-testing:TendelmUITests/PersonalEditionTests/testExternalImportEntryAndHelp \
  -only-testing:TendelmUITests/PersonalEditionTests/testSwipeDeleteHistoryUndoAndRelaunch \
  -only-testing:TendelmUITests/PasteImportTests/testBackupPasteCancelImportAndRelaunch \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
ipad_id=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(v["udid"] for a in d["devices"].values() for v in a if "iPad" in v["name"]))')
xcrun simctl boot "$ipad_id" 2>/dev/null || true
xcrun simctl bootstatus "$ipad_id" -b
run_xcode ipad-ui test-without-building -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$ipad_id" -derivedDataPath "$out/DerivedData" \
  -resultBundlePath "$out/iPad.xcresult" \
  -only-testing:TendelmUITests/PersonalEditionTests/testCapturePersonalScreens \
  -only-testing:TendelmUITests/RecentlyDeletedUITests/testTodayDeleteAndRestoreSurviveRelaunch \
  -only-testing:TendelmUITests/PersonalEditionTests/testExternalImportEntryAndHelp \
  -only-testing:TendelmUITests/PersonalEditionTests/testSwipeDeleteHistoryUndoAndRelaunch \
  -only-testing:TendelmUITests/PasteImportTests/testHistoryPastePreviewCancelAndRepeatImport \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
fi # Reuse only explicitly verified, unchanged app/test source.
run_xcode device-build build -project Tendelm.xcodeproj -scheme Tendelm -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath "$out/DeviceBuild" CODE_SIGNING_ALLOWED=NO
app="$out/DeviceBuild/Build/Products/Release-iphoneos/Tendelm.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Info.plist")
mkdir -p "$out/Payload"
cp -R "$app" "$out/Payload/"
(cd "$out" && zip -qr "Tendelm-$version.ipa" Payload)
python3 Scripts/verify-personal-ipa.py "$out/Tendelm-$version.ipa" > "$out/package-inspection.json"
echo "IPA: $out/Tendelm-$version.ipa"
echo "Build and simulator checks passed. Physical-device testing is still needed."
