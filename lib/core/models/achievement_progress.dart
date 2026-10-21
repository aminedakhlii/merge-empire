class AchievementProgress {
  const AchievementProgress({
    required this.id,
    this.unlocked = false,
    this.claimed = false,
  });

  final String id;
  final bool unlocked;
  final bool claimed;

  AchievementProgress copyWith({
    bool? unlocked,
    bool? claimed,
  }) =>
      AchievementProgress(
        id: id,
        unlocked: unlocked ?? this.unlocked,
        claimed: claimed ?? this.claimed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlocked': unlocked,
        'claimed': claimed,
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        id: json['id'] as String,
        unlocked: json['unlocked'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
      );
}
