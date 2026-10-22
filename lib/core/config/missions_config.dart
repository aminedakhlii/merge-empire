enum MissionType {
  mergeCount,
  createLevel,
  completeOrders,
  earnCoins,
  upgradeShop,
  collectItems,
}

class MissionDef {
  const MissionDef({
    required this.id,
    required this.description,
    required this.type,
    required this.target,
    required this.coinReward,
    required this.xpReward,
    this.levelTarget,
  });

  final String id;
  final String description;
  final MissionType type;
  final int target;
  final int coinReward;
  final int xpReward;

  /// For [MissionType.createLevel], the object level to create.
  final int? levelTarget;
}

class MissionsConfig {
  const MissionsConfig({required this.definitions});

  final List<MissionDef> definitions;

  MissionDef byId(String id) =>
      definitions.firstWhere((m) => m.id == id);

  static const MissionsConfig standard = MissionsConfig(
    definitions: [
      MissionDef(
        id: 'm_merge_5',
        description: 'Merge 5 times',
        type: MissionType.mergeCount,
        target: 5,
        coinReward: 20,
        xpReward: 15,
      ),
      MissionDef(
        id: 'm_create_l3',
        description: 'Create a Level 3 item',
        type: MissionType.createLevel,
        target: 1,
        levelTarget: 3,
        coinReward: 25,
        xpReward: 20,
      ),
      MissionDef(
        id: 'm_orders_3',
        description: 'Complete 3 customer orders',
        type: MissionType.completeOrders,
        target: 3,
        coinReward: 40,
        xpReward: 25,
      ),
      MissionDef(
        id: 'm_earn_100',
        description: 'Earn 100 coins',
        type: MissionType.earnCoins,
        target: 100,
        coinReward: 30,
        xpReward: 20,
      ),
      MissionDef(
        id: 'm_shop_2',
        description: 'Upgrade the shop once',
        type: MissionType.upgradeShop,
        target: 1,
        coinReward: 35,
        xpReward: 25,
      ),
      MissionDef(
        id: 'm_collect_10',
        description: 'Collect 10 items from the generator',
        type: MissionType.collectItems,
        target: 10,
        coinReward: 15,
        xpReward: 12,
      ),
    ],
  );
}
