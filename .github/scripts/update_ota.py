"""
Reads env vars set by the CI workflow and writes release.json to /tmp/ota/.
Rotates the current release into the rollback field (one level deep).
"""
import json, os
from pathlib import Path

version      = os.environ['VERSION']
version_code = int(os.environ['VERSION_CODE'])
sha          = os.environ['SHA']
dt           = os.environ['DT']
tag          = f"v{version}-{sha}"
base         = f"https://github.com/Project-Delilah/luckylatlang/releases/download/{tag}"

new_release = {
    "versionCode":   version_code,
    "version":       version,
    "changelog":     os.environ.get('COMMIT_MSG', ''),
    "forceRollback": False,
    "apks": {
        "arm64-v8a":   {"url": f"{base}/luckylatlang_arm64-v8a_{dt}-signed.apk",   "sha256": os.environ['SHA_ARM64']},
        "armeabi-v7a": {"url": f"{base}/luckylatlang_armeabi-v7a_{dt}-signed.apk", "sha256": os.environ['SHA_ARM']},
        "x86_64":      {"url": f"{base}/luckylatlang_x86_64_{dt}-signed.apk",       "sha256": os.environ['SHA_X86']},
    },
}

prev_path = Path("/tmp/ota/release.json")
if prev_path.exists():
    prev = json.loads(prev_path.read_text())
    prev.pop("rollback", None)
    prev.pop("forceRollback", None)
    new_release["rollback"] = prev

Path("/tmp/ota/release.json").write_text(json.dumps(new_release, indent=2))
print(f"release.json written: v{version}+{version_code}")
