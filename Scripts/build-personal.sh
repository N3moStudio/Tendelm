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
xcodebuild -version
out=$(mktemp -d "$root/.build-personal-XXXXXXXX")
echo "Build logs and test results: $out"
device_id=${TENDELM_SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(v["udid"] for a in d["devices"].values() for v in a if "iPhone" in v["name"]))')}

run_xcode() {
  local name=$1
  shift
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

run_xcode unit-tests test -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" \
  -resultBundlePath "$out/UnitTests.xcresult" -only-testing:TendelmTests CODE_SIGNING_ALLOWED=NO
xcrun simctl boot "$device_id" 2>/dev/null || true
xcrun simctl bootstatus "$device_id" -b
xcrun simctl ui "$device_id" appearance light
run_xcode iphone-ui test-without-building -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath "$out/DerivedData" \
  -resultBundlePath "$out/iPhone.xcresult" -only-testing:TendelmUITests/PersonalEditionTests \
  -only-testing:TendelmUITests/HabitThemePickerTests -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 90 \
  -maximum-test-execution-time-allowance 180 CODE_SIGNING_ALLOWED=NO
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
