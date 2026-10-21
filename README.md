# Merge Empire

Offline-capable Flutter merge game: grow a neighborhood coffee shop by merging coffee products, selling them for coins, and expanding your empire.

**Phase 1** delivers the playable foundation: configurable 7×9 merge board, coffee chain (10 levels), generator, coin economy, selling, and versioned local save/resume.

## Requirements

- Flutter SDK **3.35+** (Dart 3.9+)
- iOS and/or Android toolchain for device/simulator runs

## Run

```bash
flutter pub get
flutter run
```

Portrait is preferred. On first launch you get one ready coffee bean in the generator — tap **Generate**, drag matching items together to merge, select an item and tap **Sell** to earn coins. Progress auto-saves locally; kill and reopen the app to resume.

## Test

```bash
flutter test
```

Core coverage: merge/move, sell/economy, generator collect + tick, versioned save/load resume.

## Project layout

```
lib/
  app/           # MaterialApp + theme
  core/          # config + models (no Flutter UI)
  features/
    board/       # merge board widgets
    economy/     # sell UI
    game/        # logic, controller, main screen
    generators/  # coffee generator UI
    persistence/ # versioned SharedPreferences save
```

Game rules live in `features/game/game_logic.dart` and are unit-tested without the widget tree. Balancing is centralized under `core/config/`.

## Phase status

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Board, merge, generator, coins, sell, save | This branch |
| 2 | Orders, shop, XP, missions, daily, tutorial | Deferred |
| 3 | AdMob, consent, analytics | Deferred |
| 4 | Release polish, privacy docs, store assets | Deferred |

No production AdMob IDs are embedded. No backend.

## License

Private / TBD by owner.
