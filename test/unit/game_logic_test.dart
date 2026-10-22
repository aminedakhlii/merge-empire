import 'package:flutter_test/flutter_test.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/core/models/board_position.dart';
import 'package:merge_empire/core/models/game_object.dart';
import 'package:merge_empire/core/models/game_state.dart';
import 'package:merge_empire/core/models/generator_state.dart';
import 'package:merge_empire/features/game/game_logic.dart';

void main() {
  late GameLogic logic;
  var clock = 1_000_000;
  var idCounter = 0;

  setUp(() {
    clock = 1_000_000;
    idCounter = 0;
    logic = GameLogic(
      config: GameConfig.phase1,
      clockMs: () => clock,
      idFactory: () => ++idCounter,
    );
  });

  GameState withObjects(Map<BoardPosition, GameObject> objects, {int coins = 0}) {
    final base = logic.createInitialState(nowMs: clock);
    return base.copyWith(objects: objects, coins: coins, nextObjectSeq: 100);
  }

  group('move', () {
    test('moves object to empty cell', () {
      final from = const BoardPosition(0, 0);
      final to = const BoardPosition(1, 0);
      final state = withObjects({
        from: const GameObject(id: 'a', chainId: 'coffee', level: 1),
      });

      final result = logic.moveOrMerge(state, from, to);
      expect(result, isA<ActionSuccess>());
      final next = (result as ActionSuccess).state;
      expect(next.objectAt(from), isNull);
      expect(next.objectAt(to)?.id, 'a');
    });

    test('fails when source empty', () {
      final state = withObjects({});
      final result = logic.moveOrMerge(
        state,
        const BoardPosition(0, 0),
        const BoardPosition(1, 0),
      );
      expect(result, isA<ActionFailure>());
      expect(state.objects, isEmpty);
    });
  });

  group('merge', () {
    test('merges two matching objects atomically', () {
      final from = const BoardPosition(0, 0);
      final to = const BoardPosition(1, 0);
      final state = withObjects({
        from: const GameObject(id: 'a', chainId: 'coffee', level: 1),
        to: const GameObject(id: 'b', chainId: 'coffee', level: 1),
      });

      final result = logic.moveOrMerge(state, from, to);
      expect(result, isA<ActionSuccess>());
      final next = (result as ActionSuccess).state;
      expect(next.objectAt(from), isNull);
      expect(next.objectAt(to)?.level, 2);
      expect(next.occupiedCount, 1);
    });

    test('rejects mismatched levels without destroying objects', () {
      final from = const BoardPosition(0, 0);
      final to = const BoardPosition(1, 0);
      final state = withObjects({
        from: const GameObject(id: 'a', chainId: 'coffee', level: 1),
        to: const GameObject(id: 'b', chainId: 'coffee', level: 2),
      });

      final result = logic.moveOrMerge(state, from, to);
      expect(result, isA<ActionFailure>());
      expect(state.objectAt(from)?.id, 'a');
      expect(state.objectAt(to)?.id, 'b');
    });

    test('rejects merge at max level', () {
      final from = const BoardPosition(0, 0);
      final to = const BoardPosition(1, 0);
      final state = withObjects({
        from: const GameObject(id: 'a', chainId: 'coffee', level: 10),
        to: const GameObject(id: 'b', chainId: 'coffee', level: 10),
      });

      final result = logic.moveOrMerge(state, from, to);
      expect(result, isA<ActionFailure>());
      expect(state.occupiedCount, 2);
    });
  });

  group('sell', () {
    test('removes object and adds coins from economy config', () {
      final pos = const BoardPosition(0, 0);
      final state = withObjects({
        pos: const GameObject(id: 'a', chainId: 'coffee', level: 3),
      });

      final expected = GameConfig.phase1.economy.saleValueForLevel(3);
      final result = logic.sellObject(state, pos);
      expect(result, isA<ActionSuccess>());
      final next = (result as ActionSuccess).state;
      expect(next.objectAt(pos), isNull);
      expect(next.coins, expected);
    });

    test('fails when cell empty', () {
      final state = withObjects({});
      final result = logic.sellObject(state, const BoardPosition(0, 0));
      expect(result, isA<ActionFailure>());
    });
  });

  group('generator', () {
    test('collect places level-1 coffee on board and decrements storage', () {
      final state = logic.createInitialState(nowMs: clock);
      expect(state.generators.first.storedOutput, 1);

      final result = logic.collectFromGenerator(state, nowMs: clock);
      expect(result, isA<ActionSuccess>());
      final next = (result as ActionSuccess).state;
      expect(next.occupiedCount, 1);
      expect(next.objects.values.first.level, 1);
      expect(next.generators.first.storedOutput, 0);
    });

    test('tick accumulates stored output up to max', () {
      var state = logic.createInitialState(nowMs: clock);
      // Consume initial stored output.
      state = (logic.collectFromGenerator(state, nowMs: clock) as ActionSuccess)
          .state;
      expect(state.generators.first.storedOutput, 0);

      clock += GeneratorConfigInterval.threeIntervals;
      state = logic.tickGenerators(state, nowMs: clock);
      expect(state.generators.first.storedOutput, 3);

      clock += GeneratorConfigInterval.manyIntervals;
      state = logic.tickGenerators(state, nowMs: clock);
      expect(
        state.generators.first.storedOutput,
        GameConfig.phase1.starterGenerator.maxStoredOutput,
      );
    });

    test('collect fails when board is full', () {
      final objects = <BoardPosition, GameObject>{};
      var n = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 7; c++) {
          objects[BoardPosition(c, r)] = GameObject(
            id: 'o${n++}',
            chainId: 'coffee',
            level: 1,
          );
        }
      }
      final state = withObjects(objects).copyWith(
        generators: [
          const GeneratorState(
            configId: 'basic_coffee_generator',
            storedOutput: 2,
            lastTickMs: 1_000_000,
          ),
        ],
      );

      final result = logic.collectFromGenerator(state);
      expect(result, isA<ActionFailure>());
      expect(state.occupiedCount, 63);
    });
  });
}

/// Helpers for generator interval math in tests.
abstract final class GeneratorConfigInterval {
  static const threeIntervals = 3 * 3000;
  static const manyIntervals = 100 * 3000;
}
