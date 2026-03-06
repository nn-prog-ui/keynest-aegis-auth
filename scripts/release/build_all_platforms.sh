#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

echo "== Aegis Auth multi-platform build =="
echo "project: $ROOT_DIR"

flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test

echo
echo "[1/4] iOS simulator build"
flutter build ios --simulator --no-codesign

echo
echo "[2/4] macOS release build"
flutter build macos --release

echo
echo "[3/4] Android App Bundle (if Android SDK exists)"
if command -v sdkmanager >/dev/null 2>&1 || [ -n "${ANDROID_HOME:-}" ]; then
  flutter build appbundle --release
else
  echo "SKIP: Android SDK is not configured on this machine."
fi

echo
echo "[4/4] Windows release build"
echo "SKIP on macOS. Run this on Windows or GitHub Actions workflow."

echo
echo "Done."
