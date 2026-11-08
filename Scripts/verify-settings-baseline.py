"""Allow packaging only the exact settings implementation already tested on iOS."""
import json
from pathlib import Path
import subprocess
import sys

BASELINE = "d205ded203d60346d0efa2b10048f1148b6b7e98"
TEST_RUN = "6aeff00124e1ec2375576207"
METADATA = {
    "Tendelm.xcodeproj/project.pbxproj": [
        ("MARKETING_VERSION = 1.0.5;", "MARKETING_VERSION = 1.0.6;", 8),
        ("CURRENT_PROJECT_VERSION = 6;", "CURRENT_PROJECT_VERSION = 7;", 8),
    ],
    "Scripts/verify-personal-ipa.py": [
        ('== "1.0.5"', '== "1.0.6"', 1),
        ('info["CFBundleVersion"] == "6"', 'info["CFBundleVersion"] == "7"', 1),
    ],
}
BUILD_ONLY = {"Scripts/build-personal.sh", "Scripts/verify-settings-baseline.py", "codemagic.yaml"}

def validate_paths(paths):
    unexpected = [p for p in paths if p not in METADATA and p not in BUILD_ONLY
                  and p != "README.md" and not p.startswith("docs/")]
    assert not unexpected, "App/test/config source changed since native validation: " + ", ".join(unexpected)

def validate_metadata(path, before, after):
    expected = before
    for old, new, count in METADATA[path]:
        assert expected.count(old) == count, "Unexpected baseline metadata: " + path
        expected = expected.replace(old, new)
    assert after == expected, "Only the reviewed version/build bump may differ: " + path

def verify(baseline):
    assert baseline == BASELINE, "Unverified native-test baseline"
    paths = subprocess.check_output(["git", "diff", "--name-only", baseline, "--"], text=True, encoding="utf-8").splitlines()
    untracked = subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard"], text=True, encoding="utf-8").splitlines()
    validate_paths(paths + untracked)
    for path in METADATA:
        before = subprocess.check_output(["git", "show", f"{baseline}:{path}"], text=True, encoding="utf-8")
        validate_metadata(path, before, Path(path).read_text(encoding="utf-8"))
    return {"result": "passed", "tested_commit": baseline, "native_test_run": TEST_RUN,
            "version": "1.0.6", "build": "7", "app_and_test_source": "identical",
            "allowed_changes": "exact version/build bump, build tooling, documentation",
            "unit_passed": 841, "expected_issues": 1, "ui_passed": 17}

if __name__ == "__main__":
    print(json.dumps(verify(sys.argv[1]), indent=2))
