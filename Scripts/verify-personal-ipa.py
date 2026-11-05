"""Inspect the unsigned personal IPA using only Python's standard library."""
import hashlib
import json
import plistlib
import struct
import sys
import zipfile
from pathlib import Path


def inspect(path: Path) -> dict:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, "Corrupt ZIP entry"
        names = archive.namelist()
        root = "Payload/Tendelm.app/"
        assert {n.split('/')[1] for n in names if n.startswith('Payload/')} == {"Tendelm.app"}
        info = plistlib.loads(archive.read(root + "Info.plist"))
        assert info["CFBundleIdentifier"] == "com.n3mostudio.tendelm"
        assert info["CFBundleDisplayName"] == "Tendelm"
        assert info["CFBundleShortVersionString"] == "1.0.0"
        assert info["CFBundleVersion"] == "1"
        assert info["CFBundleSupportedPlatforms"] == ["iPhoneOS"]
        assert set(info["UIDeviceFamily"]) == {1, 2}
        assert not any(".xctest/" in n or "embedded.mobileprovision" in n for n in names)
        assert root + "Assets.car" in names
        notices = archive.read(root + "OpenSourceNotices.txt").decode("utf-8")
        assert "Sébastien Castiel" in notices and "Jakub Antalik" in notices
        bundles = [root] + [n[:-len("Info.plist")] for n in names
                          if n.startswith(root + "PlugIns/") and n.endswith(".appex/Info.plist")]
        assert len(bundles) == 2, "Expected one widget extension"
        binaries = []
        for bundle in bundles:
            metadata = plistlib.loads(archive.read(bundle + "Info.plist"))
            executable = archive.read(bundle + metadata["CFBundleExecutable"])
            magic, cpu = struct.unpack_from("<II", executable)
            assert magic == 0xFEEDFACF and cpu == 0x0100000C, "Expected arm64 Mach-O"
            commands = struct.unpack_from("<I", executable, 16)[0]
            offset = 32
            platforms = []
            encrypted = False
            for _ in range(commands):
                command, size = struct.unpack_from("<II", executable, offset)
                assert size >= 8 and offset + size <= len(executable)
                if command == 0x32:  # LC_BUILD_VERSION: 2 is device iOS; 7 is simulator.
                    platforms.append(struct.unpack_from("<I", executable, offset + 8)[0])
                if command == 0x2C:  # LC_ENCRYPTION_INFO_64
                    encrypted |= struct.unpack_from("<I", executable, offset + 16)[0] != 0
                offset += size
            assert platforms == [2] and not encrypted
            if bundle != root:
                assert metadata["CFBundleIdentifier"] == "com.n3mostudio.tendelm.TendelmWidgets"
            binaries.append({"bundle_id": metadata["CFBundleIdentifier"], "architecture": "arm64", "platform": "iOS device", "encrypted": encrypted})
        return {"file": str(path.resolve()), "bytes": path.stat().st_size,
                "sha256": hashlib.file_digest(path.open("rb"), "sha256").hexdigest(),
                "version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
                "minimum_os": info["MinimumOSVersion"], "binaries": binaries,
                "provisioning": "No profile; personal signing required", "zip_integrity": "passed"}


if __name__ == "__main__":
    print(json.dumps(inspect(Path(sys.argv[1])), indent=2))
