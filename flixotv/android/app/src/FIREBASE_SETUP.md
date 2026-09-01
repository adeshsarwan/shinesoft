Flavor-specific Firebase configuration required:

- Place mobile flavor config at `android/app/src/mobile/google-services.json`
- Place tv flavor config at `android/app/src/tv/google-services.json`

Expected Android package names in Firebase:

- mobile: `com.flixotv.ignia`
- tv: `com.flixotv.ignia`

Notes:

- `android/app/src/main/google-services.json` is currently populated as a fallback.
- For correct Analytics/Crashlytics attribution per flavor, use real per-flavor files
  downloaded from Firebase after registering both Android apps.
