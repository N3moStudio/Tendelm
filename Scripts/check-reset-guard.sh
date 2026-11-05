#!/bin/bash
# Review experiment only. Restore the exact source even if the test command fails.
set -euo pipefail
mode=${1:-reset}
export TENDELM_MUTATION_MODE="$mode"
result_name="TrackerMutation-$mode"
source_file=Packages/TendelmCore/Sources/TendelmCore/Models/TimeSinceTracker.swift
original=$(mktemp)
cp "$source_file" "$original"
trap 'cp "$original" "$source_file"; rm -f "$original"' EXIT
python3 - "$source_file" <<'PY'
from pathlib import Path
import sys, os
p = Path(sys.argv[1])
s = p.read_text()
mode = os.environ['TENDELM_MUTATION_MODE']
assert mode in ('reset', 'scheduled')
before, after = ('guard date >= currentStart else', 'guard date < currentStart else') if mode == 'reset' else ('isScheduled = now < start', 'isScheduled = now >= start')
assert s.count(before) == 1
p.write_text(s.replace(before, after))
PY
device_id=$(cat output/simulator-id.txt)
set +e
xcodebuild test -project Tendelm.xcodeproj -scheme Tendelm \
  -destination "platform=iOS Simulator,id=$device_id" -derivedDataPath build \
  -resultBundlePath "output/$result_name.xcresult" \
  -only-testing:TendelmTests/TimeSinceTests CODE_SIGNING_ALLOWED=NO \
  > "output/$result_name.log" 2>&1
result=$?
set -e
test "$result" -ne 0
xcrun xcresulttool get test-results summary --path "output/$result_name.xcresult" --format json > "output/$result_name-summary.json"
python3 - "$result_name" <<'PY'
import json, os, sys
from pathlib import Path
s = json.loads(Path('output', sys.argv[1] + '-summary.json').read_text())
failures = s.get('testFailures', [])
expected = 'TimeSinceTests/backwardsClock()' if os.environ['TENDELM_MUTATION_MODE'] == 'reset' else 'TimeSinceTests/scheduledBoundary()'
assert any(f.get('testIdentifierString') == expected and
           'crash' not in f.get('failureText', '').lower() for f in failures), failures
print('PASS: ' + expected + ' rejected the inverted condition. Source restored on exit.')
PY
