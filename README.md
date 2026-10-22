# Merge Empire

Offline-capable Flutter merge game: grow a neighborhood coffee shop by merging products, fulfilling orders, upgrading the shop, and expanding your empire.

## Phase status

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Board, merge, generator, coins, sell, save | Done |
| 2 | Orders, shop, XP, missions, daily, achievements, tutorial | Done |
| 3 | AdMob, consent, analytics, Remove Ads flag | **This branch** |
| 4 | Release polish, privacy docs, store assets | Deferred |

## Requirements

- Flutter SDK **3.35+** (Dart 3.9+)
- iOS / Android for AdMob (web/desktop use no-op ads)

## Run

```bash
flutter pub get
flutter run
```

Ads use **Google test unit IDs only**. See `docs/admob-setup.md`.

## Test

```bash
flutter analyze
flutter test
```

## Monetization notes

- Ads live behind `AdService` (`lib/monetization/ads/`) — not in gameplay widgets
- Banner slot is reserved below controls (never overlays the board)
- Rewarded is optional; rewards only after SDK callback; claim-once
- Interstitials respect frequency caps and never show during board drag
- Consent / privacy options entry in Settings (UMP/ATT hooks ready)
- Analytics via `AnalyticsService` abstraction (logging/no-op until Firebase is wired)
- Remove Ads IAP is feature-flagged off with a service interface

No production AdMob IDs. No backend.

## License

Private / TBD by owner.
