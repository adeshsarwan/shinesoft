#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# build_apks.sh  –  Build optimised APKs (phone, tablet, and Android TV)
#
# Usage:
#   chmod +x build_apks.sh
#   ./build_apks.sh
#
# Output (in build/outputs/):
#   →  arm64-v8a, armeabi-v7a, x86_64  APKs
# ─────────────────────────────────────────────────────────────────────────────

set -e   # exit on any error

OUTPUT_DIR="build/outputs"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "══════════════════════════════════════════════"
echo "  Step 1 – Clean previous build"
echo "══════════════════════════════════════════════"
flutter clean
flutter pub get

# media_kit_libs_android_video downloads native libs from GitHub during Gradle
# evaluation; slow networks often hit "Operation timed out". Pre-cache them here.
MEDIA_KIT_DIR="build/media_kit_libs_android_video/v1.1.7"
MEDIA_KIT_BASE="https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.7"
mkdir -p "$MEDIA_KIT_DIR"
for jar in default-arm64-v8a.jar default-armeabi-v7a.jar default-x86_64.jar default-x86.jar; do
  if [ ! -f "$MEDIA_KIT_DIR/$jar" ]; then
    echo "Downloading media_kit lib: $jar"
    curl -L --fail --retry 3 -o "$MEDIA_KIT_DIR/$jar" "$MEDIA_KIT_BASE/$jar"
  fi
done

echo ""
echo "══════════════════════════════════════════════"
echo "  Step 2 – Build APKs (release)"
echo "══════════════════════════════════════════════"
flutter build apk \
  --release \
  --flavor mobile \
  --target lib/main.dart \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/debug-info

cp android/app/build/outputs/apk/release/*-arm64-v8a-release.apk   "$OUTPUT_DIR/flixo-arm64.apk"   2>/dev/null || true
cp android/app/build/outputs/apk/release/*-armeabi-v7a-release.apk "$OUTPUT_DIR/flixo-arm32.apk"   2>/dev/null || true
cp android/app/build/outputs/apk/release/*-x86_64-release.apk      "$OUTPUT_DIR/flixo-x86_64.apk"  2>/dev/null || true

echo ""
echo "══════════════════════════════════════════════"
echo "  ✅  Build complete!"
echo "══════════════════════════════════════════════"
echo ""
ls -lh "$OUTPUT_DIR/" 2>/dev/null || echo "  (none found)"
echo ""
echo "Debug symbols saved to: build/debug-info/"
echo ""
