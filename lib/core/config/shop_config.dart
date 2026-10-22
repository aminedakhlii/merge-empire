/// One shop upgrade tier (≥10 levels required).
class ShopLevelDef {
  const ShopLevelDef({
    required this.level,
    required this.name,
    required this.cost,
    required this.minPlayerLevel,
    required this.generatorIntervalMs,
    required this.generatorCapacity,
    required this.unlockMaxObjectLevel,
    required this.rewardXp,
    required this.decorLabel,
  });

  final int level;
  final String name;
  final int cost;
  final int minPlayerLevel;
  final int generatorIntervalMs;
  final int generatorCapacity;
  final int unlockMaxObjectLevel;
  final int rewardXp;
  final String decorLabel;
}

class ShopConfig {
  const ShopConfig({required this.levels, this.locationId = 'neighborhood'});

  final String locationId;
  final List<ShopLevelDef> levels;

  int get maxLevel => levels.length;

  ShopLevelDef levelDef(int level) {
    if (level < 1 || level > levels.length) {
      throw ArgumentError.value(level, 'level', 'out of range 1..$maxLevel');
    }
    return levels[level - 1];
  }

  static final ShopConfig neighborhood = ShopConfig(
    levels: const [
      ShopLevelDef(
        level: 1,
        name: 'Corner Cart',
        cost: 0,
        minPlayerLevel: 1,
        generatorIntervalMs: 3000,
        generatorCapacity: 5,
        unlockMaxObjectLevel: 3,
        rewardXp: 0,
        decorLabel: 'A tiny sidewalk cart',
      ),
      ShopLevelDef(
        level: 2,
        name: 'Window Counter',
        cost: 40,
        minPlayerLevel: 1,
        generatorIntervalMs: 2800,
        generatorCapacity: 5,
        unlockMaxObjectLevel: 4,
        rewardXp: 15,
        decorLabel: 'Fresh paint & a bell',
      ),
      ShopLevelDef(
        level: 3,
        name: 'Cozy Nook',
        cost: 90,
        minPlayerLevel: 2,
        generatorIntervalMs: 2500,
        generatorCapacity: 6,
        unlockMaxObjectLevel: 5,
        rewardXp: 20,
        decorLabel: 'Warm lamps & stools',
      ),
      ShopLevelDef(
        level: 4,
        name: 'Neighborhood Café',
        cost: 160,
        minPlayerLevel: 2,
        generatorIntervalMs: 2300,
        generatorCapacity: 6,
        unlockMaxObjectLevel: 6,
        rewardXp: 25,
        decorLabel: 'Chalkboard menu',
      ),
      ShopLevelDef(
        level: 5,
        name: 'Roastery Corner',
        cost: 260,
        minPlayerLevel: 3,
        generatorIntervalMs: 2000,
        generatorCapacity: 7,
        unlockMaxObjectLevel: 7,
        rewardXp: 30,
        decorLabel: 'Bean bags on display',
      ),
      ShopLevelDef(
        level: 6,
        name: 'Pastry Partner',
        cost: 400,
        minPlayerLevel: 3,
        generatorIntervalMs: 1800,
        generatorCapacity: 7,
        unlockMaxObjectLevel: 8,
        rewardXp: 35,
        decorLabel: 'Pastry case unlocked',
      ),
      ShopLevelDef(
        level: 7,
        name: 'Barista Bar',
        cost: 600,
        minPlayerLevel: 4,
        generatorIntervalMs: 1600,
        generatorCapacity: 8,
        unlockMaxObjectLevel: 9,
        rewardXp: 40,
        decorLabel: 'Steam wand shine',
      ),
      ShopLevelDef(
        level: 8,
        name: 'Lounge Lights',
        cost: 900,
        minPlayerLevel: 5,
        generatorIntervalMs: 1400,
        generatorCapacity: 8,
        unlockMaxObjectLevel: 10,
        rewardXp: 50,
        decorLabel: 'Soft evening glow',
      ),
      ShopLevelDef(
        level: 9,
        name: 'Signature House',
        cost: 1300,
        minPlayerLevel: 6,
        generatorIntervalMs: 1200,
        generatorCapacity: 9,
        unlockMaxObjectLevel: 10,
        rewardXp: 60,
        decorLabel: 'House blend banners',
      ),
      ShopLevelDef(
        level: 10,
        name: 'Empire Flagship',
        cost: 2000,
        minPlayerLevel: 7,
        generatorIntervalMs: 1000,
        generatorCapacity: 10,
        unlockMaxObjectLevel: 10,
        rewardXp: 80,
        decorLabel: 'Neighborhood landmark',
      ),
    ],
  );
}
