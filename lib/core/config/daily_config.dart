enum DailyChallengeType {
  mergeCount,
  earnCoins,
  completeOrders,
}

class DailyChallengeDef {
  const DailyChallengeDef({
    required this.id,
    required this.description,
    required this.type,
    required this.target,
    required this.coinReward,
    required this.xpReward,
  });

  final String id;
  final String description;
  final DailyChallengeType type;
  final int target;
  final int coinReward;
  final int xpReward;
}

/// Offline daily challenges use the device local calendar day.
///
/// Clock safeguards (MVP):
/// - Day key is `yyyy-MM-dd` in local time.
/// - If the clock jumps backward vs [lastSeenDayKey], the current challenge
///   is kept and progress is not reset (anti-rollback soft guard).
/// - If the clock jumps forward more than [maxForwardJumpDays], a new day is
///   still accepted but the activity streak resets (anti-skip soft guard).
/// - Limitations: players can still manipulate the device clock; there is no
///   server authority. Documented for owners — not a security boundary.
class DailyConfig {
  const DailyConfig({
    required this.pool,
    this.maxForwardJumpDays = 2,
    this.streakRewardCoins = 10,
  });

  final List<DailyChallengeDef> pool;
  final int maxForwardJumpDays;
  final int streakRewardCoins;

  DailyChallengeDef challengeForDayKey(String dayKey) {
    final hash = dayKey.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return pool[hash % pool.length];
  }

  static const DailyConfig standard = DailyConfig(
    pool: [
      DailyChallengeDef(
        id: 'd_merge_8',
        description: 'Merge 8 times today',
        type: DailyChallengeType.mergeCount,
        target: 8,
        coinReward: 35,
        xpReward: 20,
      ),
      DailyChallengeDef(
        id: 'd_earn_50',
        description: 'Earn 50 coins today',
        type: DailyChallengeType.earnCoins,
        target: 50,
        coinReward: 30,
        xpReward: 18,
      ),
      DailyChallengeDef(
        id: 'd_orders_2',
        description: 'Complete 2 orders today',
        type: DailyChallengeType.completeOrders,
        target: 2,
        coinReward: 40,
        xpReward: 22,
      ),
    ],
  );
}
