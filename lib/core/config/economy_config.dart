/// Central economy balancing. Sale value = baseValue × levelMultiplier[level].
class EconomyConfig {
  const EconomyConfig({
    this.startingCoins = 0,
    this.baseSaleValue = 5,
    this.levelMultipliers = const [
      0, // unused index 0
      1, // L1
      2, // L2
      4, // L3
      8, // L4
      16, // L5
      32, // L6
      64, // L7
      128, // L8
      256, // L9
      512, // L10
    ],
    this.valuableSellThreshold = 50,
  });

  final int startingCoins;
  final int baseSaleValue;
  final List<int> levelMultipliers;

  /// Objects at or above this sale value show a confirmation before selling.
  final int valuableSellThreshold;

  int saleValueForLevel(int level) {
    if (level < 1 || level >= levelMultipliers.length) {
      throw ArgumentError.value(level, 'level', 'no multiplier configured');
    }
    return baseSaleValue * levelMultipliers[level];
  }

  static const EconomyConfig standard = EconomyConfig();
}
