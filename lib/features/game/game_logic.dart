import '../../core/config/economy_config.dart';
import '../../core/config/game_config.dart';
import '../../core/config/generator_config.dart';
import '../../core/models/board_position.dart';
import '../../core/models/game_object.dart';
import '../../core/models/game_state.dart';
import '../../core/models/generator_state.dart';

/// Result of a board action. Failed merges/moves leave state unchanged.
sealed class ActionResult {
  const ActionResult();
}

class ActionSuccess extends ActionResult {
  const ActionSuccess(this.state, {this.message});

  final GameState state;
  final String? message;
}

class ActionFailure extends ActionResult {
  const ActionFailure(this.reason);

  final String reason;
}

/// Pure, deterministic game logic — no Flutter dependencies.
class GameLogic {
  GameLogic({
    required this.config,
    int Function()? idFactory,
    int Function()? clockMs,
  })  : _idFactory = idFactory,
        _clockMs = clockMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final GameConfig config;
  final int Function()? _idFactory;
  final int Function() _clockMs;

  String _nextObjectId(GameState state) {
    if (_idFactory != null) {
      return 'obj_${_idFactory()}';
    }
    return 'obj_${state.nextObjectSeq}';
  }

  GameState createInitialState({int? nowMs}) {
    final now = nowMs ?? _clockMs();
    return GameState(
      schemaVersion: 1,
      columns: config.board.columns,
      rows: config.board.rows,
      objects: const {},
      coins: config.economy.startingCoins,
      gems: 0,
      generators: [
        GeneratorState(
          configId: config.starterGenerator.id,
          storedOutput: 1,
          lastTickMs: now,
        ),
      ],
      nextObjectSeq: 1,
      updatedAtMs: now,
    );
  }

  /// Advance generator production based on elapsed time.
  GameState tickGenerators(GameState state, {int? nowMs}) {
    final now = nowMs ?? _clockMs();
    final genConfig = config.starterGenerator;
    final updated = <GeneratorState>[];
    var changed = false;

    for (final gen in state.generators) {
      if (gen.configId != genConfig.id) {
        updated.add(gen);
        continue;
      }

      var stored = gen.storedOutput;
      var lastTick = gen.lastTickMs;
      final interval = genConfig.productionIntervalMs;
      if (interval <= 0) {
        updated.add(gen);
        continue;
      }

      while (stored < genConfig.maxStoredOutput &&
          now - lastTick >= interval) {
        stored += 1;
        lastTick += interval;
        changed = true;
      }
      // Cap clock so we don't spiral on huge offline gaps beyond capacity.
      if (stored >= genConfig.maxStoredOutput && lastTick < now) {
        lastTick = now;
      }

      updated.add(
        gen.copyWith(storedOutput: stored, lastTickMs: lastTick),
      );
    }

    if (!changed) {
      return state.copyWith(updatedAtMs: now);
    }
    return state.copyWith(generators: updated, updatedAtMs: now);
  }

  /// Place one stored generator output onto the first empty cell.
  ActionResult collectFromGenerator(
    GameState state, {
    String generatorId = GeneratorConfig.basicCoffeeId,
    int? nowMs,
  }) {
    final now = nowMs ?? _clockMs();
    var current = tickGenerators(state, nowMs: now);

    final genIndex =
        current.generators.indexWhere((g) => g.configId == generatorId);
    if (genIndex < 0) {
      return const ActionFailure('Generator not found');
    }

    final gen = current.generators[genIndex];
    if (gen.storedOutput <= 0) {
      return const ActionFailure('Nothing ready to collect');
    }

    final empty = current.firstEmptyCell();
    if (empty == null) {
      return const ActionFailure('Board is full — merge or sell to free space');
    }

    final genConfig = config.starterGenerator;
    final object = GameObject(
      id: _nextObjectId(current),
      chainId: genConfig.chainId,
      level: genConfig.producedLevel,
    );

    final newObjects = Map<BoardPosition, GameObject>.from(current.objects)
      ..[empty] = object;

    final newGens = List<GeneratorState>.from(current.generators);
    newGens[genIndex] = gen.copyWith(storedOutput: gen.storedOutput - 1);

    return ActionSuccess(
      current.copyWith(
        objects: newObjects,
        generators: newGens,
        nextObjectSeq: current.nextObjectSeq + 1,
        updatedAtMs: now,
      ),
      message: 'Collected ${config.coffeeChain.levelDef(object.level).displayName}',
    );
  }

  /// Move an object, or merge if destination holds a matching object.
  ActionResult moveOrMerge(
    GameState state,
    BoardPosition from,
    BoardPosition to, {
    int? nowMs,
  }) {
    final now = nowMs ?? _clockMs();

    if (from == to) {
      return const ActionFailure('Same cell');
    }
    if (!state.inBounds(from) || !state.inBounds(to)) {
      return const ActionFailure('Out of bounds');
    }

    final source = state.objectAt(from);
    if (source == null) {
      return const ActionFailure('No object at source');
    }
    if (source.locked) {
      return const ActionFailure('Object is locked');
    }

    final dest = state.objectAt(to);

    if (dest == null) {
      final newObjects = Map<BoardPosition, GameObject>.from(state.objects)
        ..remove(from)
        ..[to] = source;
      return ActionSuccess(
        state.copyWith(objects: newObjects, updatedAtMs: now),
      );
    }

    if (dest.locked) {
      return const ActionFailure('Destination is locked');
    }

    if (!source.canMergeWith(dest)) {
      return const ActionFailure('Objects cannot merge');
    }

    final chain = config.coffeeChain;
    if (source.chainId != chain.id) {
      return const ActionFailure('Unknown chain');
    }
    if (source.level >= chain.maxLevel) {
      return const ActionFailure('Already at max level');
    }

    // Atomic merge: build next state only after validation succeeds.
    final merged = source.mergeResult(newId: _nextObjectId(state));
    final newObjects = Map<BoardPosition, GameObject>.from(state.objects)
      ..remove(from)
      ..[to] = merged;

    return ActionSuccess(
      state.copyWith(
        objects: newObjects,
        nextObjectSeq: state.nextObjectSeq + 1,
        updatedAtMs: now,
      ),
      message: 'Merged into ${chain.levelDef(merged.level).displayName}',
    );
  }

  /// Sell the object at [pos] for coins from [EconomyConfig].
  ActionResult sellObject(
    GameState state,
    BoardPosition pos, {
    int? nowMs,
  }) {
    final now = nowMs ?? _clockMs();
    final object = state.objectAt(pos);
    if (object == null) {
      return const ActionFailure('No object to sell');
    }
    if (object.locked) {
      return const ActionFailure('Object is locked');
    }

    final EconomyConfig economy = config.economy;
    final value = economy.saleValueForLevel(object.level);

    final newObjects = Map<BoardPosition, GameObject>.from(state.objects)
      ..remove(pos);

    return ActionSuccess(
      state.copyWith(
        objects: newObjects,
        coins: state.coins + value,
        updatedAtMs: now,
      ),
      message: 'Sold for $value coins',
    );
  }

  int saleValue(GameObject object) =>
      config.economy.saleValueForLevel(object.level);

  bool isValuableSale(GameObject object) =>
      saleValue(object) >= config.economy.valuableSellThreshold;
}
