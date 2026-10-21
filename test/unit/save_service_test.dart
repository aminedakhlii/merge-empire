import 'package:flutter_test/flutter_test.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/core/models/board_position.dart';
import 'package:merge_empire/core/models/game_object.dart';
import 'package:merge_empire/features/game/game_logic.dart';
import 'package:merge_empire/features/persistence/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemorySaveService', () {
    test('round-trips game state', () async {
      final logic = GameLogic(config: GameConfig.phase1, clockMs: () => 42);
      final save = InMemorySaveService();
      var state = logic.createInitialState(nowMs: 42);
      state = (logic.collectFromGenerator(state, nowMs: 42) as ActionSuccess)
          .state;

      await save.save(state);
      final loaded = await save.load();

      expect(loaded, isNotNull);
      expect(loaded!.coins, state.coins);
      expect(loaded.occupiedCount, state.occupiedCount);
      expect(loaded.objects.values.first.level, 1);
      expect(loaded.generators.first.storedOutput, 0);
      expect(loaded.schemaVersion, 2);
      expect(loaded.missions, isNotEmpty);
      expect(loaded.orders.length, 3);
    });
  });

  group('SharedPreferencesSaveService', () {
    test('persists and resumes after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final save = SharedPreferencesSaveService(prefs: prefs);
      final logic = GameLogic(config: GameConfig.phase1, clockMs: () => 99);

      var state = logic.createInitialState(nowMs: 99);
      state = (logic.collectFromGenerator(state, nowMs: 99) as ActionSuccess)
          .state;
      final pos = state.objects.keys.first;
      // Place a second bean and merge.
      state = state.copyWith(
        objects: {
          ...state.objects,
          const BoardPosition(1, 0): const GameObject(
            id: 'extra',
            chainId: 'coffee',
            level: 1,
          ),
        },
      );
      state = (logic.moveOrMerge(
        state,
        pos,
        const BoardPosition(1, 0),
        nowMs: 99,
      ) as ActionSuccess)
          .state;
      state = (logic.sellObject(
        state,
        const BoardPosition(1, 0),
        nowMs: 99,
      ) as ActionSuccess)
          .state;

      await save.save(state);

      // Simulate app restart with a fresh service on same prefs.
      final save2 = SharedPreferencesSaveService(prefs: prefs);
      final resumed = await save2.load();

      expect(resumed, isNotNull);
      expect(resumed!.coins, GameConfig.phase1.economy.saleValueForLevel(2));
      expect(resumed.occupiedCount, 0);
      expect(resumed.columns, 7);
      expect(resumed.rows, 9);
    });

    test('migrate upgrades schema 0 through 2', () {
      final save = SharedPreferencesSaveService();
      final migrated = save.migrate({
        'schemaVersion': 0,
        'columns': 7,
        'rows': 9,
        'coins': 10,
        'objects': <dynamic>[],
        'generators': <dynamic>[],
      });
      expect(migrated['schemaVersion'], 2);
      expect(migrated['gems'], 0);
      expect(migrated['nextObjectSeq'], 1);
      expect(migrated['playerLevel'], 1);
      expect(migrated['shopLevel'], 1);
    });

    test('malformed save returns null', () async {
      SharedPreferences.setMockInitialValues({
        'merge_empire_save_v1': '{not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      final save = SharedPreferencesSaveService(prefs: prefs);
      expect(await save.load(), isNull);
    });
  });
}
