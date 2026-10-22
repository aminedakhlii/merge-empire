import 'package:flutter_test/flutter_test.dart';
import 'package:merge_empire/core/config/achievements_config.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/core/config/tutorial_config.dart';
import 'package:merge_empire/core/models/board_position.dart';
import 'package:merge_empire/core/models/game_object.dart';
import 'package:merge_empire/core/models/mission_progress.dart';
import 'package:merge_empire/features/game/game_logic.dart';
import 'package:merge_empire/features/progression/progression_logic.dart';

void main() {
  late GameLogic logic;
  var clock = DateTime(2026, 10, 21, 12).millisecondsSinceEpoch;
  var idCounter = 0;

  setUp(() {
    clock = DateTime(2026, 10, 21, 12).millisecondsSinceEpoch;
    idCounter = 0;
    logic = GameLogic(
      config: GameConfig.standard,
      clockMs: () => clock,
      idFactory: () => ++idCounter,
    );
  });

  group('orders', () {
    test('seeds three attainable orders', () {
      final state = logic.createInitialState(nowMs: clock);
      expect(state.orders.length, 3);
      final shopCap =
          logic.config.shop.levelDef(state.shopLevel).unlockMaxObjectLevel;
      final levels = <int>{};
      for (final o in state.orders) {
        expect(o.requiredLevel, lessThanOrEqualTo(shopCap));
        levels.add(o.requiredLevel);
      }
      // Shop L1 unlocks up to L3 → early slots should not all be identical L1.
      expect(levels.length, greaterThan(1));
    });

    test('complete order consumes items and grants rewards once', () {
      var state = logic.createInitialState(nowMs: clock);
      final order = state.orders.first;
      final objects = <BoardPosition, GameObject>{};
      for (var i = 0; i < order.requiredQuantity; i++) {
        objects[BoardPosition(i, 0)] = GameObject(
          id: 'need_$i',
          chainId: order.chainId,
          level: order.requiredLevel,
        );
      }
      state = state.copyWith(objects: objects, coins: 0);

      final result = logic.completeOrder(state, order.instanceId, nowMs: clock);
      expect(result, isA<ActionSuccess>());
      final next = (result as ActionSuccess).state;
      expect(next.coins, order.coinReward);
      expect(next.stats.ordersCompleted, 1);
      expect(next.orders.length, 3); // replaced
      expect(
        next.achievements[AchievementId.firstOrder.name]?.unlocked,
        isTrue,
      );

      // Cannot reclaim same instance (gone) — completing again with old id fails.
      final again = logic.completeOrder(next, order.instanceId, nowMs: clock);
      expect(again, isA<ActionFailure>());
    });
  });

  group('shop', () {
    test('upgrade spends coins and raises shop level with feedback fields', () {
      var state = logic.createInitialState(nowMs: clock);
      final nextDef = logic.config.shop.levelDef(2);
      state = state.copyWith(
        coins: nextDef.cost,
        playerLevel: nextDef.minPlayerLevel,
      );

      final result = logic.upgradeShop(state, nowMs: clock);
      expect(result, isA<ActionSuccess>());
      final next = (result as ActionSuccess).state;
      expect(next.shopLevel, 2);
      expect(next.coins, 0);
      expect(next.stats.shopUpgrades, 1);
      expect(
        next.achievements[AchievementId.firstUpgrade.name]?.unlocked,
        isTrue,
      );
    });

    test('shop has at least 10 levels', () {
      expect(logic.config.shop.maxLevel, greaterThanOrEqualTo(10));
    });
  });

  group('xp', () {
    test('merges grant xp and can level up', () {
      var state = logic.createInitialState(nowMs: clock);
      state = state.copyWith(
        objects: {
          const BoardPosition(0, 0):
              const GameObject(id: 'a', chainId: 'coffee', level: 1),
          const BoardPosition(1, 0):
              const GameObject(id: 'b', chainId: 'coffee', level: 1),
        },
        playerXp: logic.config.xp.xpToNextLevel(1) - 1,
      );

      final result = logic.moveOrMerge(
        state,
        const BoardPosition(0, 0),
        const BoardPosition(1, 0),
        nowMs: clock,
      );
      final next = (result as ActionSuccess).state;
      expect(next.playerLevel, greaterThanOrEqualTo(2));
      expect(next.stats.mergeCount, 1);
    });
  });

  group('missions and achievements', () {
    test('mission completes and claims once', () {
      var state = logic.createInitialState(nowMs: clock);
      // Force merge mission near complete.
      state = state.copyWith(
        missions: [
          for (final m in state.missions)
            if (m.missionId == 'm_merge_5')
              m.copyWith(progress: 5, status: MissionStatus.completed)
            else
              m,
        ],
      );

      final claim = logic.claimMission(state, 'm_merge_5', nowMs: clock);
      expect(claim, isA<ActionSuccess>());
      final next = (claim as ActionSuccess).state;
      expect(
        next.missions.firstWhere((m) => m.missionId == 'm_merge_5').status,
        MissionStatus.claimed,
      );

      final again = logic.claimMission(next, 'm_merge_5', nowMs: clock);
      expect(again, isA<ActionFailure>());
    });

    test('achievement claims once', () {
      var state = logic.createInitialState(nowMs: clock);
      final key = AchievementId.firstMerge.name;
      final unlocked = Map.of(state.achievements);
      unlocked[key] = unlocked[key]!.copyWith(unlocked: true);
      state = state.copyWith(achievements: unlocked);

      final claim = logic.claimAchievement(state, key, nowMs: clock);
      expect(claim, isA<ActionSuccess>());
      final next = (claim as ActionSuccess).state;
      expect(next.achievements[key]!.claimed, isTrue);

      final again = logic.claimAchievement(next, key, nowMs: clock);
      expect(again, isA<ActionFailure>());
    });
  });

  group('daily clock safeguards', () {
    test('backward clock keeps challenge', () {
      final prog = ProgressionLogic(GameConfig.standard);
      var state = logic.createInitialState(nowMs: clock);
      state = state.copyWith(
        daily: state.daily.copyWith(progress: 3),
      );

      final yesterday = DateTime(2026, 10, 20, 12);
      final synced = prog.syncDaily(state, yesterday);
      expect(synced.daily.dayKey, state.daily.dayKey);
      expect(synced.daily.progress, 3);
    });

    test('next day rolls new challenge and bumps streak', () {
      final prog = ProgressionLogic(GameConfig.standard);
      var state = logic.createInitialState(nowMs: clock);
      final tomorrow = DateTime(2026, 10, 22, 12);
      final synced = prog.syncDaily(state, tomorrow);
      expect(synced.daily.dayKey, localDayKey(tomorrow));
      expect(synced.daily.progress, 0);
      expect(synced.daily.activityStreak, state.daily.activityStreak + 1);
    });

    test('claim daily once when complete', () {
      var state = logic.createInitialState(nowMs: clock);
      state = state.copyWith(
        daily: state.daily.copyWith(
          progress: state.daily.target,
          claimed: false,
        ),
      );
      final claim = logic.claimDaily(state, nowMs: clock);
      expect(claim, isA<ActionSuccess>());
      final next = (claim as ActionSuccess).state;
      expect(next.daily.claimed, isTrue);
      expect(logic.claimDaily(next, nowMs: clock), isA<ActionFailure>());
    });
  });

  group('tutorial', () {
    test('starts at welcome and can dismiss', () {
      final state = logic.createInitialState(nowMs: clock);
      expect(state.tutorialStep, TutorialStep.welcome);
      expect(state.tutorialCompleted, isFalse);

      final dismissed = logic.dismissTutorial(state) as ActionSuccess;
      expect(dismissed.state.tutorialCompleted, isTrue);
    });
  });

  group('chains', () {
    test('coffee and pastry chains have at least 10 levels', () {
      expect(logic.config.coffeeChain.maxLevel, greaterThanOrEqualTo(10));
      expect(logic.config.pastryChain.maxLevel, greaterThanOrEqualTo(10));
    });
  });
}
