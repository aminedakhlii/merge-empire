# Merge Empire

Offline-capable Flutter merge game: grow a neighborhood coffee shop by merging products, fulfilling orders, upgrading the shop, and expanding your empire.

## Phase status

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Board, merge, generator, coins, sell, save | Done |
| 2 | Orders, shop, XP, missions, daily, achievements, tutorial, polish | **This branch** |
| 3 | AdMob, consent, analytics | Deferred |
| 4 | Release polish, privacy docs, store assets | Deferred |

## Requirements

- Flutter SDK **3.35+** (Dart 3.9+)
- iOS / Android / Chrome / Linux toolchain for device runs

## Run

```bash
flutter pub get
flutter run
```

Portrait is preferred. First launch walks through a short tutorial (Generate → Merge → Sell/Order). Progress auto-saves locally.

## Test

```bash
flutter test
flutter analyze
```

## Project layout

```
lib/
  app/                 # MaterialApp + theme
  core/                # config + models
  features/
    board/             # merge board
    daily_challenges/  # daily UI
    economy/           # sell UI
    game/              # logic, controller, main screen
    generators/        # coffee (+ pastry when unlocked)
    missions/          # missions + achievements
    orders/            # customer orders
    persistence/       # versioned SharedPreferences save (schema v2)
    progression/       # XP / orders / daily / tutorial helpers
    settings/          # sound/haptics toggles
    shop/              # ≥10 shop levels
    tutorial/          # first-minute overlay
docs/
  daily-challenges-offline.md   # clock safeguards + limitations
```

No production AdMob IDs. No backend.

## License

Private / TBD by owner.
