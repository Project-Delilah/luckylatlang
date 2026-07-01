#!/usr/bin/env bash
set -e

PUBSPEC="pubspec.yaml"
APK_OUT="build/app/outputs/flutter-apk"

# ── helpers ──────────────────────────────────────────────────────────────────
current_version() { grep -m1 '^version:' "$PUBSPEC" | sed 's/version: //'; }

do_bump() {
  local cur semver code major rest minor patch
  cur=$(current_version)
  semver="${cur%+*}"; code="${cur#*+}"
  major="${semver%%.*}"; rest="${semver#*.}"
  minor="${rest%%.*}"; patch="${rest#*.}"
  local new="${major}.${minor}.$((patch+1))+$((code+1))"
  sed -i "s/^version: .*/version: ${new}/" "$PUBSPEC"
  echo "  bumped  ${cur}  →  ${new}"
}

do_analyze() {
  echo ""
  echo "▶ flutter analyze"
  set +e; flutter analyze 2>&1; status=$?; set -e
  if [[ $status -ne 0 ]]; then
    echo ""
    echo "  Issues found. Options:"
    echo "    dart fix --dry-run   — preview auto-fixable issues"
    echo "    dart fix --apply     — apply all fixes automatically"
    read -rp "  Run 'dart fix --apply' now? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] && dart fix --apply && echo "  Fixes applied. Re-run analysis to confirm."
  fi
}

do_test() {
  echo ""
  echo "▶ flutter test"
  flutter test
}

do_build() {
  local flags="$1" label="$2"
  echo ""
  echo "▶ flutter build apk ${flags}  (${label})"
  # ponytail: key.properties swap — cleanest way to force unsigned without touching build.gradle
  local swapped=0
  if [[ "$flags" == *"unsigned"* ]]; then
    flags="${flags/ unsigned/}"
    if [[ -f android/key.properties ]]; then
      mv android/key.properties android/key.properties.bak
      swapped=1
    fi
  fi
  # shellcheck disable=SC2086
  flutter build apk $flags
  [[ $swapped -eq 1 ]] && mv android/key.properties.bak android/key.properties
  echo ""
  echo "  Output:"
  ls -lh "${APK_OUT}"/*.apk 2>/dev/null && echo "" || true
}

# ── menu ─────────────────────────────────────────────────────────────────────
VER=$(current_version)
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│         luckylatlang  dev tool              │"
echo "├─────────────────────────────────────────────┤"
printf "│  version: %-35s│\n" "$VER"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "  [1]  Bump version (patch + build code)"
echo "  [2]  flutter analyze  +  dart fix suggestion"
echo "  [3]  flutter test"
echo "  [4]  Build: debug APK"
echo "  [5]  Build: release APK — single, signed"
echo "  [6]  Build: release APK — split-per-ABI, signed"
echo "  [7]  Build: release APK — single, unsigned"
echo "  [8]  Build: release APK — split-per-ABI, unsigned"
echo "  [9]  Quick release: bump → analyze → split-per-ABI signed"
echo ""
read -rp "Choice(s) [space-separated, e.g. 1 2 5]: " -a choices
echo ""

for c in "${choices[@]}"; do
  case "$c" in
    1) do_bump ;;
    2) do_analyze ;;
    3) do_test ;;
    4) do_build "--debug"                            "debug, unsigned" ;;
    5) do_build "--release"                          "release, single, signed" ;;
    6) do_build "--release --split-per-abi"          "release, split-per-ABI, signed" ;;
    7) do_build "--release unsigned"                 "release, single, unsigned" ;;
    8) do_build "--release --split-per-abi unsigned" "release, split-per-ABI, unsigned" ;;
    9) do_bump; do_analyze; do_build "--release --split-per-abi" "release, split-per-ABI, signed" ;;
    *) echo "  unknown option: $c" ;;
  esac
done

echo ""
echo "done."
