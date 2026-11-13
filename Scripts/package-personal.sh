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


run_xcode device-build build -project Tendelm.xcodeproj -scheme Tendelm -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath "$out/DeviceBuild" CODE_SIGNING_ALLOWED=NO
app="$out/DeviceBuild/Build/Products/Release-iphoneos/Tendelm.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Info.plist")
mkdir -p "$out/Payload"
cp -R "$app" "$out/Payload/"
(cd "$out" && zip -qr "Tendelm-$version.ipa" Payload)
python3 Scripts/verify-personal-ipa.py "$out/Tendelm-$version.ipa" > "$out/package-inspection.json"
echo "IPA: $out/Tendelm-$version.ipa"
echo "Device build and package verification passed. Simulator results are reported separately."
