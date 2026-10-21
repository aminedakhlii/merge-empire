import '../config/tutorial_config.dart';
import 'achievement_progress.dart';
import 'board_position.dart';
import 'daily_challenge_state.dart';
import 'game_object.dart';
import 'generator_state.dart';
import 'mission_progress.dart';
import 'order_instance.dart';
import 'player_stats.dart';

/// Full persistent game snapshot (schema v2 = Phase 2 progression).
class GameState {
  const GameState({
    required this.schemaVersion,
    required this.columns,
    required this.rows,
    required this.objects,
    required this.coins,
    required this.gems,
    required this.generators,
    required this.nextObjectSeq,
    required this.updatedAtMs,
    required this.playerXp,
    required this.playerLevel,
    required this.shopLevel,
    required this.orders,
    required this.nextOrderSeq,
    required this.missions,
    required this.achievements,
    required this.daily,
    required this.stats,
    required this.tutorialStep,
    required this.tutorialCompleted,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final int schemaVersion;
  final int columns;
  final int rows;
  final Map<BoardPosition, GameObject> objects;
  final int coins;
  final int gems;
  final List<GeneratorState> generators;
  final int nextObjectSeq;
  final int updatedAtMs;

  final int playerXp;
  final int playerLevel;
  final int shopLevel;
  final List<OrderInstance> orders;
  final int nextOrderSeq;
  final List<MissionProgress> missions;
  final Map<String, AchievementProgress> achievements;
  final DailyChallengeState daily;
  final PlayerStats stats;
  final TutorialStep tutorialStep;
  final bool tutorialCompleted;
  final bool soundEnabled;
  final bool hapticsEnabled;

  int get occupiedCount => objects.length;

  int get emptyCount => columns * rows - occupiedCount;

  bool get isFull => emptyCount <= 0;

  GameObject? objectAt(BoardPosition pos) => objects[pos];

  bool isEmpty(BoardPosition pos) => !objects.containsKey(pos);

  bool inBounds(BoardPosition pos) =>
      pos.column >= 0 &&
      pos.column < columns &&
      pos.row >= 0 &&
      pos.row < rows;

  BoardPosition? firstEmptyCell() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final pos = BoardPosition(c, r);
        if (isEmpty(pos)) return pos;
      }
    }
    return null;
  }

  int countObjects({required String chainId, required int level}) {
    var n = 0;
    for (final o in objects.values) {
      if (o.chainId == chainId && o.level == level && !o.locked) n++;
    }
    return n;
  }

  GameState copyWith({
    int? schemaVersion,
    int? columns,
    int? rows,
    Map<BoardPosition, GameObject>? objects,
    int? coins,
    int? gems,
    List<GeneratorState>? generators,
    int? nextObjectSeq,
    int? updatedAtMs,
    int? playerXp,
    int? playerLevel,
    int? shopLevel,
    List<OrderInstance>? orders,
    int? nextOrderSeq,
    List<MissionProgress>? missions,
    Map<String, AchievementProgress>? achievements,
    DailyChallengeState? daily,
    PlayerStats? stats,
    TutorialStep? tutorialStep,
    bool? tutorialCompleted,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) =>
      GameState(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        columns: columns ?? this.columns,
        rows: rows ?? this.rows,
        objects: objects ?? this.objects,
        coins: coins ?? this.coins,
        gems: gems ?? this.gems,
        generators: generators ?? this.generators,
        nextObjectSeq: nextObjectSeq ?? this.nextObjectSeq,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
        playerXp: playerXp ?? this.playerXp,
        playerLevel: playerLevel ?? this.playerLevel,
        shopLevel: shopLevel ?? this.shopLevel,
        orders: orders ?? this.orders,
        nextOrderSeq: nextOrderSeq ?? this.nextOrderSeq,
        missions: missions ?? this.missions,
        achievements: achievements ?? this.achievements,
        daily: daily ?? this.daily,
        stats: stats ?? this.stats,
        tutorialStep: tutorialStep ?? this.tutorialStep,
        tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'columns': columns,
        'rows': rows,
        'coins': coins,
        'gems': gems,
        'nextObjectSeq': nextObjectSeq,
        'updatedAtMs': updatedAtMs,
        'playerXp': playerXp,
        'playerLevel': playerLevel,
        'shopLevel': shopLevel,
        'nextOrderSeq': nextOrderSeq,
        'tutorialStep': tutorialStep.name,
        'tutorialCompleted': tutorialCompleted,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'generators': generators.map((g) => g.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
        'missions': missions.map((m) => m.toJson()).toList(),
        'achievements': achievements.values.map((a) => a.toJson()).toList(),
        'daily': daily.toJson(),
        'stats': stats.toJson(),
        'objects': objects.entries
            .map(
              (e) => {
                'pos': e.key.toJson(),
                'obj': e.value.toJson(),
              },
            )
            .toList(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final objectEntries = (json['objects'] as List<dynamic>? ?? []).map((raw) {
      final entry = raw as Map<String, dynamic>;
      return MapEntry(
        BoardPosition.fromJson(entry['pos'] as Map<String, dynamic>),
        GameObject.fromJson(entry['obj'] as Map<String, dynamic>),
      );
    });

    final achievementList =
        (json['achievements'] as List<dynamic>? ?? []).map((raw) {
      return AchievementProgress.fromJson(raw as Map<String, dynamic>);
    });

    return GameState(
      schemaVersion: json['schemaVersion'] as int,
      columns: json['columns'] as int,
      rows: json['rows'] as int,
      coins: json['coins'] as int,
      gems: json['gems'] as int? ?? 0,
      nextObjectSeq: json['nextObjectSeq'] as int,
      updatedAtMs: json['updatedAtMs'] as int,
      playerXp: json['playerXp'] as int? ?? 0,
      playerLevel: json['playerLevel'] as int? ?? 1,
      shopLevel: json['shopLevel'] as int? ?? 1,
      nextOrderSeq: json['nextOrderSeq'] as int? ?? 1,
      tutorialStep: TutorialStep.values.firstWhere(
        (s) => s.name == (json['tutorialStep'] as String? ?? 'welcome'),
        orElse: () => TutorialStep.welcome,
      ),
      tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      generators: (json['generators'] as List<dynamic>? ?? [])
          .map((g) => GeneratorState.fromJson(g as Map<String, dynamic>))
          .toList(),
      orders: (json['orders'] as List<dynamic>? ?? [])
          .map((o) => OrderInstance.fromJson(o as Map<String, dynamic>))
          .toList(),
      missions: (json['missions'] as List<dynamic>? ?? [])
          .map((m) => MissionProgress.fromJson(m as Map<String, dynamic>))
          .toList(),
      achievements: {
        for (final a in achievementList) a.id: a,
      },
      daily: json['daily'] != null
          ? DailyChallengeState.fromJson(json['daily'] as Map<String, dynamic>)
          : const DailyChallengeState(
              dayKey: '',
              challengeId: '',
              progress: 0,
              target: 1,
            ),
      stats: json['stats'] != null
          ? PlayerStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const PlayerStats(),
      objects: Map<BoardPosition, GameObject>.fromEntries(objectEntries),
    );
  }
}
