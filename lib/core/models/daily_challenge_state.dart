class DailyChallengeState {
  const DailyChallengeState({
    required this.dayKey,
    required this.challengeId,
    required this.progress,
    required this.target,
    this.claimed = false,
    this.activityStreak = 0,
    this.uniqueActiveDays = 0,
  });

  final String dayKey;
  final String challengeId;
  final int progress;
  final int target;
  final bool claimed;
  final int activityStreak;
  final int uniqueActiveDays;

  bool get isComplete => progress >= target;

  DailyChallengeState copyWith({
    String? dayKey,
    String? challengeId,
    int? progress,
    int? target,
    bool? claimed,
    int? activityStreak,
    int? uniqueActiveDays,
  }) =>
      DailyChallengeState(
        dayKey: dayKey ?? this.dayKey,
        challengeId: challengeId ?? this.challengeId,
        progress: progress ?? this.progress,
        target: target ?? this.target,
        claimed: claimed ?? this.claimed,
        activityStreak: activityStreak ?? this.activityStreak,
        uniqueActiveDays: uniqueActiveDays ?? this.uniqueActiveDays,
      );

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'challengeId': challengeId,
        'progress': progress,
        'target': target,
        'claimed': claimed,
        'activityStreak': activityStreak,
        'uniqueActiveDays': uniqueActiveDays,
      };

  factory DailyChallengeState.fromJson(Map<String, dynamic> json) =>
      DailyChallengeState(
        dayKey: json['dayKey'] as String,
        challengeId: json['challengeId'] as String,
        progress: json['progress'] as int,
        target: json['target'] as int,
        claimed: json['claimed'] as bool? ?? false,
        activityStreak: json['activityStreak'] as int? ?? 0,
        uniqueActiveDays: json['uniqueActiveDays'] as int? ?? 0,
      );
}
