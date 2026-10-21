/// Definition of one mergeable object within a chain.
class ObjectLevelDef {
  const ObjectLevelDef({
    required this.level,
    required this.id,
    required this.displayName,
    required this.shortLabel,
  });

  final int level;
  final String id;
  final String displayName;
  final String shortLabel;
}

/// A merge chain with at least 10 levels (Phase 1 coffee chain).
class ChainConfig {
  const ChainConfig({
    required this.id,
    required this.displayName,
    required this.levels,
  });

  final String id;
  final String displayName;
  final List<ObjectLevelDef> levels;

  int get maxLevel => levels.length;

  ObjectLevelDef levelDef(int level) {
    if (level < 1 || level > levels.length) {
      throw ArgumentError.value(level, 'level', 'out of range 1..$maxLevel');
    }
    return levels[level - 1];
  }

  static const String coffeeChainId = 'coffee';

  static final ChainConfig coffee = ChainConfig(
    id: coffeeChainId,
    displayName: 'Coffee',
    levels: const [
      ObjectLevelDef(
        level: 1,
        id: 'coffee_bean',
        displayName: 'Coffee Bean',
        shortLabel: 'Bean',
      ),
      ObjectLevelDef(
        level: 2,
        id: 'coffee_grounds',
        displayName: 'Grounds',
        shortLabel: 'Grnd',
      ),
      ObjectLevelDef(
        level: 3,
        id: 'coffee_filter',
        displayName: 'Filter',
        shortLabel: 'Filt',
      ),
      ObjectLevelDef(
        level: 4,
        id: 'empty_cup',
        displayName: 'Empty Cup',
        shortLabel: 'Cup',
      ),
      ObjectLevelDef(
        level: 5,
        id: 'espresso',
        displayName: 'Espresso',
        shortLabel: 'Esp',
      ),
      ObjectLevelDef(
        level: 6,
        id: 'coffee_cup',
        displayName: 'Coffee Cup',
        shortLabel: 'Coff',
      ),
      ObjectLevelDef(
        level: 7,
        id: 'latte',
        displayName: 'Latte',
        shortLabel: 'Lat',
      ),
      ObjectLevelDef(
        level: 8,
        id: 'cappuccino',
        displayName: 'Cappuccino',
        shortLabel: 'Cap',
      ),
      ObjectLevelDef(
        level: 9,
        id: 'premium_brew',
        displayName: 'Premium Brew',
        shortLabel: 'Prem',
      ),
      ObjectLevelDef(
        level: 10,
        id: 'signature_blend',
        displayName: 'Signature Blend',
        shortLabel: 'Sig',
      ),
    ],
  );

  static ChainConfig byId(String id) {
    switch (id) {
      case coffeeChainId:
        return coffee;
      default:
        throw ArgumentError.value(id, 'id', 'unknown chain');
    }
  }
}
