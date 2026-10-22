# iOS CocoaPods notes

## Why `pod install` failed on `webview_flutter_wkwebview`

`google_mobile_ads` declares a CocoaPods dependency on `webview_flutter_wkwebview`. That name is a **Flutter plugin pod** shipped via pub and installed under `ios/.symlinks/plugins/…` by Flutter’s `podhelper`. It is **not** published on the CocoaPods trunk/CDN.

If Swift Package Manager installs `webview_flutter_wkwebview` instead of CocoaPods (or if you run `pod install` without Flutter’s Podfile / without `flutter pub get` first), CocoaPods looks for a trunk spec and fails with:

```text
[!] Unable to find a specification for `webview_flutter_wkwebview`
depended upon by `google_mobile_ads`
```

## Fix in this repo

1. Checked-in `ios/Podfile` with `platform :ios, '13.0'` and `flutter_install_all_ios_pods`.
2. SPM disabled for the app in `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

No production AdMob IDs are required for this fix (test IDs remain).

## Commands that succeed (macOS + Xcode + CocoaPods)

From the repo root:

```bash
flutter pub get
cd ios
pod install
cd ..
```

Or let Flutter drive pods:

```bash
flutter pub get
flutter build ios --no-codesign
# or
flutter run -d ios
```

If CocoaPods specs for **Google-Mobile-Ads-SDK** are stale (unrelated to webview), once:

```bash
cd ios
pod install --repo-update
```

### Clean reinstall (if you still see the error after pulling)

```bash
flutter pub get
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install
cd ..
```

Do **not** invent a CocoaPods `source` entry for `webview_flutter_wkwebview` — use Flutter’s local plugin pods only.
