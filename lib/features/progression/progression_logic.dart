import '../../core/config/achievements_config.dart';
import '../../core/config/daily_config.dart';
import '../../core/config/game_config.dart';
import '../../core/config/missions_config.dart';
import '../../core/config/orders_config.dart';
import '../../core/config/tutorial_config.dart';
import '../../core/models/achievement_progress.dart';
import '../../core/models/board_position.dart';
import '../../core/models/daily_challenge_state.dart';
import '../../core/models/game_object.dart';
import '../../core/models/game_state.dart';
import '../../core/models/mission_progress.dart';
import '../../core/models/order_instance.dart';

/// Day-key helper for offline daily challenges (local calendar).
String localDayKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? tryParseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Progression helpers: XP, orders, shop, missions, achievements, daily, tutorial.
class ProgressionLogic {
  ProgressionLogic(this.config);

  final GameConfig config;

  GameState applyXp(GameState state, int xpGain) {
    if (xpGain <= 0) return state;
    var xp = state.playerXp + xpGain;
    var level = state.playerLevel;
    while (xp >= config.xp.xpToNextLevel(level)) {
      xp -= config.xp.xpToNextLevel(level);
      level += 1;
    }
    return state.copyWith(playerXp: xp, playerLevel: level);
  }

  Map<String, AchievementProgress> initialAchievements() {
    return {
      for (final def in config.achievements.definitions)
        def.key: AchievementProgress(id: def.key),
    };
  }

  List<MissionProgress> initialMissions() {
    return [
      for (final def in config.missions.definitions)
        MissionProgress(
          missionId: def.id,
          progress: 0,
          status: MissionStatus.active,
        ),
    ];
  }

  DailyChallengeState initialDaily(DateTime now) {
    final key = localDayKey(now);
    final def = config.daily.challengeForDayKey(key);
    return DailyChallengeState(
      dayKey: key,
      challengeId: def.id,
      progress: 0,
      target: def.target,
      activityStreak: 1,
      uniqueActiveDays: 1,
    );
  }

  List<OrderInstance> seedOrders(GameState state, {required int startSeq}) {
    final attainable = config.orders.attainable(
      shopLevel: state.shopLevel,
      maxObjectLevelSeen: state.stats.maxObjectLevelSeen,
    );
    if (attainable.isEmpty) return const [];

    final result = <OrderInstance>[];
    var seq = startSeq;
    for (var i = 0; i < config.orders.activeSlots; i++) {
      final template = attainable[i % attainable.length];
      result.add(_fromTemplate(template, 'ord_inst_$seq'));
      seq++;
    }
    return result;
  }

  OrderInstance _fromTemplate(OrderTemplate t, String instanceId) =>
      OrderInstance(
        instanceId: instanceId,
        templateId: t.id,
        customerName: t.customerName,
        chainId: t.chainId,
        requiredLevel: t.requiredLevel,
        requiredQuantity: t.requiredQuantity,
        coinReward: t.coinReward,
        xpReward: t.xpReward,
      );

  /// Refresh daily challenge using local clock safeguards (see [DailyConfig]).
  GameState syncDaily(GameState state, DateTime now) {
    final today = localDayKey(now);
    final current = state.daily;

    if (current.dayKey.isEmpty) {
      return state.copyWith(
        daily: initialDaily(now),
        stats: state.stats.copyWith(lastSeenDayKey: today),
      );
    }

    if (current.dayKey == today) {
      return state.copyWith(
        stats: state.stats.copyWith(lastSeenDayKey: today),
      );
    }

    final previous = tryParseDayKey(current.dayKey);
    final todayDt = tryParseDayKey(today);
    if (previous == null || todayDt == null) {
      final def = config.daily.challengeForDayKey(today);
      return state.copyWith(
        daily: DailyChallengeState(
          dayKey: today,
          challengeId: def.id,
          progress: 0,
          target: def.target,
          activityStreak: 1,
          uniqueActiveDays: current.uniqueActiveDays + 1,
        ),
        stats: state.stats.copyWith(lastSeenDayKey: today),
      );
    }

    final deltaDays = todayDt.difference(previous).inDays;

    // Clock rolled backward: keep current challenge (soft anti-rollback).
    if (deltaDays < 0) {
      return state.copyWith(
        stats: state.stats.copyWith(lastSeenDayKey: current.dayKey),
      );
    }

    final def = config.daily.challengeForDayKey(today);
    var streak = current.activityStreak;
    if (deltaDays == 1) {
      streak += 1;
    } else if (deltaDays > config.daily.maxForwardJumpDays) {
      streak = 1; // large forward jump → reset streak
    } else {
      streak = 1; // skipped 1–max days without consecutive play
    }

    return state.copyWith(
      daily: DailyChallengeState(
        dayKey: today,
        challengeId: def.id,
        progress: 0,
        target: def.target,
        activityStreak: streak,
        uniqueActiveDays: current.uniqueActiveDays + 1,
      ),
      stats: state.stats.copyWith(lastSeenDayKey: today),
    );
  }

  GameState unlockAchievement(GameState state, AchievementId id) {
    final key = id.name;
    final existing = state.achievements[key];
    if (existing == null || existing.unlocked) return state;
    final updated = Map<String, AchievementProgress>.from(state.achievements);
    updated[key] = existing.copyWith(unlocked: true);
    return state.copyWith(achievements: updated);
  }

  GameState bumpMission(
    GameState state,
    MissionType type, {
    int amount = 1,
    int? levelCreated,
  }) {
    final missions = <MissionProgress>[];
    for (final m in state.missions) {
      if (m.status != MissionStatus.active) {
        missions.add(m);
        continue;
      }
      final def = config.missions.byId(m.missionId);
      if (def.type != type) {
        missions.add(m);
        continue;
      }
      if (type == MissionType.createLevel &&
          def.levelTarget != null &&
          levelCreated != def.levelTarget) {
        missions.add(m);
        continue;
      }
      final progress = m.progress + amount;
      final done = progress >= def.target;
      missions.add(
        m.copyWith(
          progress: progress > def.target ? def.target : progress,
          status: done ? MissionStatus.completed : MissionStatus.active,
        ),
      );
    }
    return state.copyWith(missions: missions);
  }

  GameState bumpDaily(
    GameState state,
    DailyChallengeType type, {
    int amount = 1,
  }) {
    DailyChallengeDef? matched;
    for (final d in config.daily.pool) {
      if (d.id == state.daily.challengeId) {
        matched = d;
        break;
      }
    }
    if (matched == null || matched.type != type || state.daily.claimed) {
      return state;
    }
    final progress = state.daily.progress + amount;
    return state.copyWith(
      daily: state.daily.copyWith(
        progress: progress > state.daily.target ? state.daily.target : progress,
      ),
    );
  }

  GameState advanceTutorial(GameState state, TutorialStep reached) {
    if (state.tutorialCompleted) return state;
    final order = TutorialStep.values;
    final currentIdx = order.indexOf(state.tutorialStep);
    final reachedIdx = order.indexOf(reached);
    if (reachedIdx <= currentIdx) return state;
    if (reached == TutorialStep.complete) {
      return state.copyWith(
        tutorialStep: TutorialStep.complete,
        tutorialCompleted: true,
      );
    }
    return state.copyWith(tutorialStep: reached);
  }

  /// After a successful merge.
  GameState onMerged(GameState state, GameObject merged) {
    var next = state;
    final stats = next.stats.copyWith(
      mergeCount: next.stats.mergeCount + 1,
      maxObjectLevelSeen: merged.level > next.stats.maxObjectLevelSeen
          ? merged.level
          : next.stats.maxObjectLevelSeen,
    );
    next = next.copyWith(stats: stats);
    next = applyXp(next, config.xp.mergeXp);
    next = bumpMission(next, MissionType.mergeCount);
    next = bumpMission(
      next,
      MissionType.createLevel,
      levelCreated: merged.level,
    );
    next = bumpDaily(next, DailyChallengeType.mergeCount);
    next = unlockAchievement(next, AchievementId.firstMerge);
    if (next.stats.mergeCount >= 100) {
      next = unlockAchievement(next, AchievementId.merges100);
    }
    next = advanceTutorial(next, TutorialStep.merge);
    return next;
  }

  GameState onCollected(GameState state, GameObject object) {
    var next = state.copyWith(
      stats: state.stats.copyWith(
        collectCount: state.stats.collectCount + 1,
        maxObjectLevelSeen: object.level > state.stats.maxObjectLevelSeen
            ? object.level
            : state.stats.maxObjectLevelSeen,
      ),
    );
    next = bumpMission(next, MissionType.collectItems);
    next = advanceTutorial(next, TutorialStep.generate);
    return next;
  }

  GameState onSold(GameState state, {required int coinsGained}) {
    var next = state.copyWith(
      stats: state.stats.copyWith(
        coinsEarnedLifetime: state.stats.coinsEarnedLifetime + coinsGained,
      ),
    );
    next = applyXp(next, config.xp.sellXp(coinsGained));
    next = bumpMission(next, MissionType.earnCoins, amount: coinsGained);
    next = bumpDaily(next, DailyChallengeType.earnCoins, amount: coinsGained);
    if (state.tutorialStep == TutorialStep.sellOrOrder ||
        state.tutorialStep == TutorialStep.merge) {
      next = advanceTutorial(next, TutorialStep.sellOrOrder);
      next = next.copyWith(
        tutorialStep: TutorialStep.complete,
        tutorialCompleted: true,
      );
    }
    return next;
  }

  GameState onOrderCompleted(GameState state, {required int coinsGained}) {
    var next = state.copyWith(
      stats: state.stats.copyWith(
        ordersCompleted: state.stats.ordersCompleted + 1,
        coinsEarnedLifetime: state.stats.coinsEarnedLifetime + coinsGained,
      ),
    );
    next = bumpMission(next, MissionType.completeOrders);
    next = bumpMission(next, MissionType.earnCoins, amount: coinsGained);
    next = bumpDaily(next, DailyChallengeType.completeOrders);
    next = bumpDaily(next, DailyChallengeType.earnCoins, amount: coinsGained);
    next = unlockAchievement(next, AchievementId.firstOrder);
    if (!next.tutorialCompleted) {
      next = next.copyWith(
        tutorialStep: TutorialStep.complete,
        tutorialCompleted: true,
      );
    }
    return next;
  }

  GameState onShopUpgraded(GameState state) {
    var next = state.copyWith(
      stats: state.stats.copyWith(
        shopUpgrades: state.stats.shopUpgrades + 1,
      ),
    );
    next = bumpMission(next, MissionType.upgradeShop);
    next = unlockAchievement(next, AchievementId.firstUpgrade);
    next = unlockAchievement(next, AchievementId.firstLocation);
    return next;
  }

  GameState maybeUnlockActivity7(GameState state) {
    if (state.daily.uniqueActiveDays >= 7) {
      return unlockAchievement(state, AchievementId.activity7Day);
    }
    return state;
  }

  /// Consume board objects matching an order; returns null positions if insufficient.
  List<BoardPosition>? findOrderConsumptions(
    GameState state,
    OrderInstance order,
  ) {
    final matches = <BoardPosition>[];
    for (final entry in state.objects.entries) {
      final o = entry.value;
      if (!o.locked &&
          o.chainId == order.chainId &&
          o.level == order.requiredLevel) {
        matches.add(entry.key);
        if (matches.length >= order.requiredQuantity) break;
      }
    }
    if (matches.length < order.requiredQuantity) return null;
    return matches;
  }
}
