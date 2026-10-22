# Build and run

## Prerequisites

- Flutter **3.35+** (Dart 3.9+)
- Xcode (iOS) and/or Android SDK
- For live AdMob test ads: physical device or emulator with Google Play services (Android)

## Install

```bash
flutter pub get
flutter doctor
```

## Run (development)

```bash
flutter run                 # default device
flutter run -d ios
flutter run -d android
flutter run -d chrome       # ads no-op on web
```

Ads use **Google test unit IDs** only. See `docs/admob-setup.md`.

## Test

```bash
flutter analyze
flutter test
```

## iOS release build

```bash
flutter build ipa
# or
flutter build ios --release
```

Requires: Apple Developer team, signing, final bundle ID, App Store Connect record.

## Android release build

```bash
flutter build appbundle
# or
flutter build apk --release
```

Requires: upload keystore, final `applicationId`, Play Console app.

## Production AdMob

1. Fill `ProductionConfig` / `AdsConfig.productionUnits` with **owner** IDs (never invent).
2. Set manifests `APPLICATION_ID` / `GADApplicationIdentifier` to production app IDs.
3. Set `AdsEnvironment.production` only after IDs are real.
4. Complete UMP/ATT flows for the target regions.

## Branding assets

Default icons/splash live under `assets/branding/` and platform mipmaps/AppIcon.

Regenerate defaults (optional):

```bash
python3 scripts/generate_branding_assets.py
```

**Owner must replace** with licensed final artwork before store submission.
