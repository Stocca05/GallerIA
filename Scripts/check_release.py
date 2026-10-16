#!/usr/bin/env python3
"""Check local release prerequisites. This does not certify App Store approval."""
import argparse
import json
import plistlib
import struct
import sys
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--bundle", type=Path, help="Also inspect a built Release .app bundle")
parser.add_argument("--development", action="store_true", help="Report missing public links without failing development CI")
args = parser.parse_args()
errors = []


def check(condition, message):
    print(f"{'OK' if condition else 'MISSING'}: {message}")
    if not condition:
        errors.append(message)


def public_url(value):
    url = urlparse(value or "")
    host = url.hostname or ""
    return url.scheme == "https" and bool(host) and host != "example.com" and not host.endswith(".invalid") and not url.username and not url.password


with (ROOT / "Resources/ReleaseConfiguration.plist").open("rb") as file:
    config = plistlib.load(file)
for key in ("PrivacyPolicyURL", "SupportURL"):
    valid = public_url(config.get(key))
    if args.development and not valid:
        print(f"RELEASE BLOCKER (allowed in development): configure {key}")
    else:
        check(valid, f"Public HTTPS {key} configured (availability still requires a manual check)")

with (ROOT / "Resources/PrivacyInfo.xcprivacy").open("rb") as file:
    manifest = plistlib.load(file)
check(manifest.get("NSPrivacyTracking") is False, "Tracking disabled in privacy manifest")
check(any(item.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults" and "CA92.1" in item.get("NSPrivacyAccessedAPITypeReasons", []) for item in manifest.get("NSPrivacyAccessedAPITypes", [])), "Own-app UserDefaults reason declared")
icon = ROOT / "Sources/Assets.xcassets/AppIcon.appiconset"
contents = json.loads((icon / "Contents.json").read_text())
image = contents["images"][0]
header = (icon / image["filename"]).read_bytes()[:26]
check(header[:8] == b"\x89PNG\r\n\x1a\n" and struct.unpack(">II", header[16:24]) == (1024, 1024), "1024-pixel app icon supplied")
check(image.get("idiom") == "universal" and image.get("platform") == "ios", "Universal iOS icon catalog configured")
check(header[25] in (0, 2), "App icon has no alpha channel")
product = json.loads((ROOT / "Tests/Fixtures/GallerIA.storekit").read_text())["products"][0]
check(product["productID"] == "com.stocca.GallerIA.pro.lifetime" and product["type"] == "NonConsumable", "Local StoreKit test product matches the app")

if args.bundle:
    bundle = args.bundle.resolve()
    check((bundle / "PrivacyInfo.xcprivacy").is_file(), "Privacy manifest included in built app")
    check(not list(bundle.rglob("*.storekit")), "StoreKit fixtures excluded from shipped app")
    with (bundle / "Info.plist").open("rb") as file:
        info = plistlib.load(file)
    binary = (bundle / info["CFBundleExecutable"]).read_bytes()
    check(b"--preview-editor" not in binary and b"--reset-onboarding" not in binary, "Debug launch fixtures absent from Release executable")
    check(info.get("NSPhotoLibraryUsageDescription") and info.get("NSPhotoLibraryAddUsageDescription"), "Photos access descriptions included")

print("\nManual release checks: signed device Photos deletion/recovery, iCloud/limited access, App Store sandbox purchases/restoration/refunds, public links, signing and App Store metadata.")
sys.exit(1 if errors else 0)
