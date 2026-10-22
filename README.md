# Merge Empire

Offline-capable Flutter merge game: brew coffee creations, fulfill orders, upgrade your café, and grow a cozy empire.

## Phase status

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Board, merge, generator, coins, sell, save | Done |
| 2 | Orders, shop, XP, missions, daily, achievements, tutorial | Done |
| 3 | AdMob service layer, consent hooks, analytics abstraction | Done |
| 4 | Reliability, legal placeholders, icons, release docs | **This branch** |

## Quick start

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

iOS (after `flutter pub get`): `cd ios && pod install` — see [`docs/ios-cocoapods.md`](docs/ios-cocoapods.md) if you hit `webview_flutter_wkwebview` CocoaPods errors.

Full instructions: [`docs/build-and-run.md`](docs/build-and-run.md)  
AdMob: [`docs/admob-setup.md`](docs/admob-setup.md)  
Release: [`docs/release-checklist.md`](docs/release-checklist.md)  
Owner inputs: [`docs/owner-inputs.md`](docs/owner-inputs.md)

## Notes

- **Test AdMob IDs only** until the owner supplies production IDs (`ProductionConfig`).
- Privacy Policy / Terms in-app are **clearly marked placeholders** — not real legal documents.
- Default icons/splash under `assets/branding/` must be replaced before store submission.
- No backend. No invented production secrets.

## License

Private / TBD by owner.
