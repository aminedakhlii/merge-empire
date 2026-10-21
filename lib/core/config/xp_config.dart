/// Player XP / level curve. Integer-only balances.
class XpConfig {
  const XpConfig({
    this.mergeXp = 2,
    this.sellXpPerCoinDivisor = 5,
    this.orderXpBonus = 0,
    this.shopUpgradeXp = 15,
    this.baseXpToLevel = 40,
    this.xpPerLevelSlope = 20,
  });

  final int mergeXp;
  final int sellXpPerCoinDivisor;
  final int orderXpBonus;
  final int shopUpgradeXp;
  final int baseXpToLevel;
  final int xpPerLevelSlope;

  /// XP required to advance from [level] to level+1.
  int xpToNextLevel(int level) {
    if (level < 1) level = 1;
    return baseXpToLevel + (level - 1) * xpPerLevelSlope;
  }

  int sellXp(int coinsEarned) {
    if (coinsEarned <= 0 || sellXpPerCoinDivisor <= 0) return 0;
    return coinsEarned ~/ sellXpPerCoinDivisor;
  }

  static const XpConfig standard = XpConfig();
}
