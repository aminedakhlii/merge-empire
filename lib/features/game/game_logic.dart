import '../../core/config/achievements_config.dart';
import '../../core/config/economy_config.dart';
import '../../core/config/game_config.dart';
import '../../core/config/generator_config.dart';
import '../../core/config/tutorial_config.dart';
import '../../core/models/board_position.dart';
import '../../core/models/game_object.dart';
import '../../core/models/game_state.dart';
import '../../core/models/generator_state.dart';
import '../../core/models/mission_progress.dart';
import '../../core/models/order_instance.dart';
import '../../core/models/player_stats.dart';
import '../progression/progression_logic.dart';

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
        _clockMs = clockMs ?? (() => DateTime.now().millisecondsSinceEpoch),
        progression = ProgressionLogic(config);

  final GameConfig config;
  final ProgressionLogic progression;
  final int Function()? _idFactory;
  final int Function() _clockMs;

  String _nextObjectId(GameState state) {
    if (_idFactory != null) {
      return 'obj_${_idFactory()}';
    }
    return 'obj_${state.nextObjectSeq}';
  }

  DateTime _nowDate({int? nowMs}) =>
      DateTime.fromMillisecondsSinceEpoch(nowMs ?? _clockMs());

  GameState createInitialState({int? nowMs}) {
    final now = nowMs ?? _clockMs();
    final nowDt = _nowDate(nowMs: now);
    var state = GameState(
      schemaVersion: 2,
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
      playerXp: 0,
      playerLevel: 1,
      shopLevel: 1,
      orders: const [],
      nextOrderSeq: 1,
      missions: progression.initialMissions(),
      achievements: progression.initialAchievements(),
      daily: progression.initialDaily(nowDt),
      stats: PlayerStats(
        lastSeenDayKey: localDayKey(nowDt),
        maxObjectLevelSeen: 1,
      ),
      tutorialStep: TutorialStep.welcome,
      tutorialCompleted: !config.tutorial.enabled,
    );
    final orders = progression.seedOrders(state, startSeq: 1);
    state = state.copyWith(
      orders: orders,
      nextOrderSeq: orders.length + 1,
    );
    return progression.unlockAchievement(state, AchievementId.firstLocation);
  }

  int generatorIntervalMs(GameState state) =>
      config.shop.levelDef(state.shopLevel).generatorIntervalMs;

  int generatorCapacity(GameState state) =>
      config.shop.levelDef(state.shopLevel).generatorCapacity;

  GeneratorConfig _configForGenerator(String id) {
    if (id == GeneratorConfig.pastryOvenId) {
      return GeneratorConfig.pastryOven;
    }
    return config.starterGenerator;
  }

  GameState tickGenerators(GameState state, {int? nowMs}) {
    final now = nowMs ?? _clockMs();
    final shopInterval = generatorIntervalMs(state);
    final shopCapacity = generatorCapacity(state);
    final updated = <GeneratorState>[];
    var changed = false;

    for (final gen in state.generators) {
      final genConfig = _configForGenerator(gen.configId);
      final isCoffee = gen.configId == config.starterGenerator.id;
      final interval =
          isCoffee ? shopInterval : genConfig.productionIntervalMs;
      final capacity = isCoffee ? shopCapacity : genConfig.maxStoredOutput;

      var stored = gen.storedOutput;
      var lastTick = gen.lastTickMs;
      if (interval <= 0) {
        updated.add(gen);
        continue;
      }

      while (stored < capacity && now - lastTick >= interval) {
        stored += 1;
        lastTick += interval;
        changed = true;
      }
      if (stored >= capacity && lastTick < now) {
        lastTick = now;
      }

      updated.add(
        gen.copyWith(storedOutput: stored, lastTickMs: lastTick),
      );
    }

    var next = changed
        ? state.copyWith(generators: updated, updatedAtMs: now)
        : state.copyWith(updatedAtMs: now);
    next = progression.syncDaily(next, _nowDate(nowMs: now));
    next = progression.maybeUnlockActivity7(next);
    return next;
  }

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

    final genConfig = _configForGenerator(generatorId);
    final object = GameObject(
      id: _nextObjectId(current),
      chainId: genConfig.chainId,
      level: genConfig.producedLevel,
    );

    final newObjects = Map<BoardPosition, GameObject>.from(current.objects)
      ..[empty] = object;

    final newGens = List<GeneratorState>.from(current.generators);
    newGens[genIndex] = gen.copyWith(storedOutput: gen.storedOutput - 1);

    var next = current.copyWith(
      objects: newObjects,
      generators: newGens,
      nextObjectSeq: current.nextObjectSeq + 1,
      updatedAtMs: now,
    );
    next = progression.onCollected(next, object);

    final name = config.chainById(object.chainId).levelDef(object.level).displayName;
    return ActionSuccess(
      next,
      message: 'Collected $name',
    );
  }

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

    final chain = config.chainById(source.chainId);
    if (source.level >= chain.maxLevel) {
      return const ActionFailure('Already at max level');
    }

    final shopCap = config.shop.levelDef(state.shopLevel).unlockMaxObjectLevel;
    if (source.level + 1 > shopCap) {
      return ActionFailure(
        'Upgrade the shop to unlock level ${source.level + 1}',
      );
    }

    final merged = source.mergeResult(newId: _nextObjectId(state));
    final newObjects = Map<BoardPosition, GameObject>.from(state.objects)
      ..remove(from)
      ..[to] = merged;

    var next = state.copyWith(
      objects: newObjects,
      nextObjectSeq: state.nextObjectSeq + 1,
      updatedAtMs: now,
    );
    next = progression.onMerged(next, merged);

    return ActionSuccess(
      next,
      message: 'Merged into ${chain.levelDef(merged.level).displayName}',
    );
  }

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

    var next = state.copyWith(
      objects: newObjects,
      coins: state.coins + value,
      updatedAtMs: now,
    );
    next = progression.onSold(next, coinsGained: value);

    return ActionSuccess(
      next,
      message: 'Sold for $value coins',
    );
  }

  ActionResult completeOrder(
    GameState state,
    String instanceId, {
    int? nowMs,
  }) {
    final now = nowMs ?? _clockMs();
    final index = state.orders.indexWhere((o) => o.instanceId == instanceId);
    if (index < 0) {
      return const ActionFailure('Order not found');
    }
    final order = state.orders[index];
    if (order.claimed) {
      return const ActionFailure('Order already claimed');
    }

    final positions = progression.findOrderConsumptions(state, order);
    if (positions == null) {
      return const ActionFailure('Not enough matching items on the board');
    }

    final newObjects = Map<BoardPosition, GameObject>.from(state.objects);
    for (final p in positions) {
      newObjects.remove(p);
    }

    final orders = List.of(state.orders)..removeAt(index);

    final attainable = config.orders.attainable(
      shopLevel: state.shopLevel,
      maxObjectLevelSeen: state.stats.maxObjectLevelSeen,
    );
    var nextSeq = state.nextOrderSeq;
    if (attainable.isNotEmpty) {
      final template = attainable[nextSeq % attainable.length];
      orders.add(
        OrderInstance(
          instanceId: 'ord_inst_$nextSeq',
          templateId: template.id,
          customerName: template.customerName,
          chainId: template.chainId,
          requiredLevel: template.requiredLevel,
          requiredQuantity: template.requiredQuantity,
          coinReward: template.coinReward,
          xpReward: template.xpReward,
        ),
      );
      nextSeq += 1;
    }

    var next = state.copyWith(
      objects: newObjects,
      coins: state.coins + order.coinReward,
      orders: orders,
      nextOrderSeq: nextSeq,
      updatedAtMs: now,
    );
    next = progression.applyXp(next, order.xpReward + config.xp.orderXpBonus);
    next = progression.onOrderCompleted(next, coinsGained: order.coinReward);

    return ActionSuccess(
      next,
      message:
          'Order for ${order.customerName} complete! +${order.coinReward} coins',
    );
  }

  ActionResult upgradeShop(GameState state, {int? nowMs}) {
    final now = nowMs ?? _clockMs();
    if (state.shopLevel >= config.shop.maxLevel) {
      return const ActionFailure('Shop is fully upgraded');
    }
    final nextLevel = state.shopLevel + 1;
    final def = config.shop.levelDef(nextLevel);
    if (state.playerLevel < def.minPlayerLevel) {
      return ActionFailure('Reach player level ${def.minPlayerLevel} first');
    }
    if (state.coins < def.cost) {
      return ActionFailure('Need ${def.cost} coins to upgrade');
    }

    var next = state.copyWith(
      coins: state.coins - def.cost,
      shopLevel: nextLevel,
      updatedAtMs: now,
    );
    next = progression.applyXp(next, def.rewardXp);
    next = progression.onShopUpgraded(next);
    next = _ensurePastryGenerator(next, nowMs: now);

    return ActionSuccess(
      next,
      message: 'Shop upgraded to ${def.name}!',
    );
  }

  GameState _ensurePastryGenerator(GameState state, {required int nowMs}) {
    if (!pastryUnlocked(state)) return state;
    final exists = state.generators.any(
      (g) => g.configId == GeneratorConfig.pastryOvenId,
    );
    if (exists) return state;
    return state.copyWith(
      generators: [
        ...state.generators,
        GeneratorState(
          configId: GeneratorConfig.pastryOvenId,
          storedOutput: 1,
          lastTickMs: nowMs,
        ),
      ],
    );
  }

  ActionResult claimMission(GameState state, String missionId, {int? nowMs}) {
    final now = nowMs ?? _clockMs();
    final index = state.missions.indexWhere((m) => m.missionId == missionId);
    if (index < 0) {
      return const ActionFailure('Mission not found');
    }
    final mission = state.missions[index];
    if (mission.status == MissionStatus.claimed) {
      return const ActionFailure('Mission already claimed');
    }
    if (mission.status != MissionStatus.completed) {
      return const ActionFailure('Mission not complete yet');
    }
    final def = config.missions.byId(missionId);
    final missions = List.of(state.missions);
    missions[index] = mission.copyWith(status: MissionStatus.claimed);

    var next = state.copyWith(
      missions: missions,
      coins: state.coins + def.coinReward,
      updatedAtMs: now,
    );
    next = progression.applyXp(next, def.xpReward);
    next = next.copyWith(
      stats: next.stats.copyWith(
        coinsEarnedLifetime: next.stats.coinsEarnedLifetime + def.coinReward,
      ),
    );

    return ActionSuccess(
      next,
      message: 'Mission claimed: +${def.coinReward} coins',
    );
  }

  ActionResult claimAchievement(
    GameState state,
    String achievementId, {
    int? nowMs,
  }) {
    final now = nowMs ?? _clockMs();
    final progress = state.achievements[achievementId];
    if (progress == null) {
      return const ActionFailure('Achievement not found');
    }
    if (!progress.unlocked) {
      return const ActionFailure('Achievement not unlocked');
    }
    if (progress.claimed) {
      return const ActionFailure('Achievement already claimed');
    }
    final def = config.achievements.definitions
        .firstWhere((a) => a.key == achievementId);
    final updated = Map.of(state.achievements);
    updated[achievementId] = progress.copyWith(claimed: true);

    var next = state.copyWith(
      achievements: updated,
      coins: state.coins + def.coinReward,
      updatedAtMs: now,
    );
    next = progression.applyXp(next, def.xpReward);

    return ActionSuccess(
      next,
      message: 'Achievement claimed: ${def.title}',
    );
  }

  ActionResult claimDaily(GameState state, {int? nowMs}) {
    final now = nowMs ?? _clockMs();
    if (state.daily.claimed) {
      return const ActionFailure('Daily reward already claimed');
    }
    if (!state.daily.isComplete) {
      return const ActionFailure('Daily challenge not complete');
    }

    int? coinReward;
    int? xpReward;
    for (final d in config.daily.pool) {
      if (d.id == state.daily.challengeId) {
        coinReward = d.coinReward;
        xpReward = d.xpReward;
        break;
      }
    }
    if (coinReward == null || xpReward == null) {
      return const ActionFailure('Unknown daily challenge');
    }

    var coins = coinReward;
    if (state.daily.activityStreak > 1) {
      coins += config.daily.streakRewardCoins;
    }

    var next = state.copyWith(
      daily: state.daily.copyWith(claimed: true),
      coins: state.coins + coins,
      updatedAtMs: now,
    );
    next = progression.applyXp(next, xpReward);

    return ActionSuccess(
      next,
      message: 'Daily claimed: +$coins coins',
    );
  }

  ActionResult dismissTutorial(GameState state) {
    return ActionSuccess(
      state.copyWith(
        tutorialStep: TutorialStep.complete,
        tutorialCompleted: true,
      ),
      message: 'Tutorial complete',
    );
  }

  ActionResult advanceTutorialManual(GameState state) {
    final steps = TutorialStep.values;
    final idx = steps.indexOf(state.tutorialStep);
    if (idx >= steps.length - 1) {
      return dismissTutorial(state);
    }
    final nextStep = steps[idx + 1];
    if (nextStep == TutorialStep.complete) {
      return dismissTutorial(state);
    }
    return ActionSuccess(state.copyWith(tutorialStep: nextStep));
  }

  int saleValue(GameObject object) =>
      config.economy.saleValueForLevel(object.level);

  bool isValuableSale(GameObject object) =>
      saleValue(object) >= config.economy.valuableSellThreshold;

  bool pastryUnlocked(GameState state) =>
      state.shopLevel >= config.pastryUnlockShopLevel;
}
