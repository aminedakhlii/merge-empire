import 'package:flutter_test/flutter_test.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/core/models/board_position.dart';
import 'package:merge_empire/core/models/game_object.dart';
import 'package:merge_empire/core/models/mission_progress.dart';
import 'package:merge_empire/features/game/game_logic.dart';
import 'package:merge_empire/features/persistence/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('save validation', () {
    test('rejects negative coins', () {
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 1);
      final state = logic.createInitialState(nowMs: 1).copyWith(coins: -5);
      expect(SharedPreferencesSaveService.validateState(state), isFalse);
    });

    test('rejects out-of-bounds objects', () {
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 1);
      final state = logic.createInitialState(nowMs: 1).copyWith(
        objects: {
          const BoardPosition(99, 99): const GameObject(
            id: 'x',
            chainId: 'coffee',
            level: 1,
          ),
        },
      );
      expect(SharedPreferencesSaveService.validateState(state), isFalse);
    });

    test('refuses to persist invalid state', () async {
      final save = InMemorySaveService();
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 1);
      final bad = logic.createInitialState(nowMs: 1).copyWith(coins: -1);
      expect(() => save.save(bad), throwsStateError);
    });
  });

  group('crash recovery via backup', () {
    test('InMemorySaveService recovers from corrupted primary', () async {
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 10);
      final save = InMemorySaveService();
      var state = logic.createInitialState(nowMs: 10);
      state = (logic.collectFromGenerator(state, nowMs: 10) as ActionSuccess)
          .state;
      await save.save(state);

      final second = state.copyWith(coins: 42);
      await save.save(second);
      expect((await save.load())!.coins, 42);

      save.corruptPrimaryKeepBackup();
      final recovered = await save.load();
      expect(recovered, isNotNull);
      expect(recovered!.occupiedCount, 1);
    });

    test('SharedPreferences falls back to backup key', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final save = SharedPreferencesSaveService(prefs: prefs);
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 20);

      var state = logic.createInitialState(nowMs: 20);
      state = (logic.collectFromGenerator(state, nowMs: 20) as ActionSuccess)
          .state;
      await save.save(state);

      final progressed = state.copyWith(coins: 77);
      await save.save(progressed);

      await prefs.setString(save.storageKey, '{not-json');
      final recovered = await save.load();
      expect(recovered, isNotNull);
      expect(recovered!.occupiedCount, 1);
    });

    test('malformed primary and backup returns null (fresh start)', () async {
      SharedPreferences.setMockInitialValues({
        'merge_empire_save_v1': '%%%',
        'merge_empire_save_backup_v1': '%%%',
      });
      final prefs = await SharedPreferences.getInstance();
      final save = SharedPreferencesSaveService(prefs: prefs);
      expect(await save.load(), isNull);
    });
  });

  group('no partial merge / duplicate rewards', () {
    test('failed merge leaves both objects', () {
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 1);
      const from = BoardPosition(0, 0);
      const to = BoardPosition(1, 0);
      final state = logic.createInitialState(nowMs: 1).copyWith(
        objects: {
          from: const GameObject(id: 'a', chainId: 'coffee', level: 1),
          to: const GameObject(id: 'b', chainId: 'coffee', level: 2),
        },
      );
      final result = logic.moveOrMerge(state, from, to);
      expect(result, isA<ActionFailure>());
      expect(state.objectAt(from)?.id, 'a');
      expect(state.objectAt(to)?.id, 'b');
    });

    test('mission cannot be claimed twice', () {
      final logic = GameLogic(config: GameConfig.standard, clockMs: () => 1);
      var state = logic.createInitialState(nowMs: 1);
      state = state.copyWith(
        missions: [
          for (final m in state.missions)
            if (m.missionId == 'm_merge_5')
              m.copyWith(progress: 5, status: MissionStatus.completed)
            else
              m,
        ],
      );

      final first = logic.claimMission(state, 'm_merge_5', nowMs: 1);
      expect(first, isA<ActionSuccess>());
      final next = (first as ActionSuccess).state;
      final second = logic.claimMission(next, 'm_merge_5', nowMs: 2);
      expect(second, isA<ActionFailure>());
    });
  });
}
