enum MissionStatus { active, completed, claimed }

class MissionProgress {
  const MissionProgress({
    required this.missionId,
    required this.progress,
    required this.status,
  });

  final String missionId;
  final int progress;
  final MissionStatus status;

  MissionProgress copyWith({
    int? progress,
    MissionStatus? status,
  }) =>
      MissionProgress(
        missionId: missionId,
        progress: progress ?? this.progress,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'progress': progress,
        'status': status.name,
      };

  factory MissionProgress.fromJson(Map<String, dynamic> json) =>
      MissionProgress(
        missionId: json['missionId'] as String,
        progress: json['progress'] as int,
        status: MissionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => MissionStatus.active,
        ),
      );
}
