#!/bin/bash
# Review experiment only. Restore the exact source even if the test command fails.
set -euo pipefail
source_file=Packages/TendelmCore/Sources/TendelmCore/Models/TimeSinceTracker.swift
original=$(mktemp)
cp "$source_file" "$original"
trap 'cp "$original" "$source_file"; rm -f "$original"' EXIT
python3 - "$source_file" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
before = 'guard date >= currentStart else'
assert s.count(before) == 1
p.write_text(s.replace(before, 'guard date < currentStart else'))
PY
device_id=$(cat output/simulator-id.txt)
set +e
xcodebuild test -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath build \
  -resultBundlePath output/ResetGuardMutation.xcresult \
  -only-testing:TendelmTests/TimeSinceTests CODE_SIGNING_ALLOWED=NO \
  > output/reset-guard-mutation.log 2>&1
result=$?
set -e
test "$result" -ne 0
xcrun xcresulttool get test-results summary --path output/ResetGuardMutation.xcresult --format json > output/ResetGuardMutation-summary.json
python3 - <<'PY'
import json
from pathlib import Path
s = json.loads(Path('output/ResetGuardMutation-summary.json').read_text())
failures = s.get('testFailures', [])
assert any(f.get('testIdentifierString') == 'TimeSinceTests/backwardsClock()' and
           'crash' not in f.get('failureText', '').lower() for f in failures), failures
print('PASS: the backwards-clock regression test rejected the inverted guard. Source restored on exit.')
PY
