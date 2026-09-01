#!/bin/bash
# Run on Android TV (single APK — TV UI at runtime via leanback detection).
set -e
cd "$(dirname "$0")"
DEVICE="${1:-BeyondTV}"
echo "Running on device: $DEVICE"
flutter run --flavor tv -d "$DEVICE"
