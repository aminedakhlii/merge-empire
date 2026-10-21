class PlayerStats {
  const PlayerStats({
    this.mergeCount = 0,
    this.ordersCompleted = 0,
    this.coinsEarnedLifetime = 0,
    this.collectCount = 0,
    this.shopUpgrades = 0,
    this.maxObjectLevelSeen = 1,
    this.lastSeenDayKey = '',
  });

  final int mergeCount;
  final int ordersCompleted;
  final int coinsEarnedLifetime;
  final int collectCount;
  final int shopUpgrades;
  final int maxObjectLevelSeen;
  final String lastSeenDayKey;

  PlayerStats copyWith({
    int? mergeCount,
    int? ordersCompleted,
    int? coinsEarnedLifetime,
    int? collectCount,
    int? shopUpgrades,
    int? maxObjectLevelSeen,
    String? lastSeenDayKey,
  }) =>
      PlayerStats(
        mergeCount: mergeCount ?? this.mergeCount,
        ordersCompleted: ordersCompleted ?? this.ordersCompleted,
        coinsEarnedLifetime: coinsEarnedLifetime ?? this.coinsEarnedLifetime,
        collectCount: collectCount ?? this.collectCount,
        shopUpgrades: shopUpgrades ?? this.shopUpgrades,
        maxObjectLevelSeen: maxObjectLevelSeen ?? this.maxObjectLevelSeen,
        lastSeenDayKey: lastSeenDayKey ?? this.lastSeenDayKey,
      );

  Map<String, dynamic> toJson() => {
        'mergeCount': mergeCount,
        'ordersCompleted': ordersCompleted,
        'coinsEarnedLifetime': coinsEarnedLifetime,
        'collectCount': collectCount,
        'shopUpgrades': shopUpgrades,
        'maxObjectLevelSeen': maxObjectLevelSeen,
        'lastSeenDayKey': lastSeenDayKey,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        mergeCount: json['mergeCount'] as int? ?? 0,
        ordersCompleted: json['ordersCompleted'] as int? ?? 0,
        coinsEarnedLifetime: json['coinsEarnedLifetime'] as int? ?? 0,
        collectCount: json['collectCount'] as int? ?? 0,
        shopUpgrades: json['shopUpgrades'] as int? ?? 0,
        maxObjectLevelSeen: json['maxObjectLevelSeen'] as int? ?? 1,
        lastSeenDayKey: json['lastSeenDayKey'] as String? ?? '',
      );
}
