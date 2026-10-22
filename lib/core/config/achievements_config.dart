enum AchievementId {
  firstMerge,
  firstOrder,
  merges100,
  firstUpgrade,
  firstLocation,
  activity7Day,
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.coinReward,
    required this.xpReward,
  });

  final AchievementId id;
  final String title;
  final String description;
  final int coinReward;
  final int xpReward;

  String get key => id.name;
}

class AchievementsConfig {
  const AchievementsConfig({required this.definitions});

  final List<AchievementDef> definitions;

  AchievementDef byId(AchievementId id) =>
      definitions.firstWhere((a) => a.id == id);

  static const AchievementsConfig standard = AchievementsConfig(
    definitions: [
      AchievementDef(
        id: AchievementId.firstMerge,
        title: 'First Blend',
        description: 'Complete your first merge',
        coinReward: 10,
        xpReward: 10,
      ),
      AchievementDef(
        id: AchievementId.firstOrder,
        title: 'Open for Business',
        description: 'Fulfill your first customer order',
        coinReward: 15,
        xpReward: 12,
      ),
      AchievementDef(
        id: AchievementId.merges100,
        title: 'Century Barista',
        description: 'Reach 100 merges',
        coinReward: 100,
        xpReward: 50,
      ),
      AchievementDef(
        id: AchievementId.firstUpgrade,
        title: 'Renovator',
        description: 'Upgrade the shop for the first time',
        coinReward: 25,
        xpReward: 20,
      ),
      AchievementDef(
        id: AchievementId.firstLocation,
        title: 'Home Base',
        description: 'Establish the neighborhood coffee shop',
        coinReward: 5,
        xpReward: 5,
      ),
      AchievementDef(
        id: AchievementId.activity7Day,
        title: 'Week of Aroma',
        description: 'Play on 7 different local days',
        coinReward: 75,
        xpReward: 40,
      ),
    ],
  );
}
