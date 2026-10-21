import 'board_position.dart';
import 'game_object.dart';
import 'generator_state.dart';

/// Full persistent game snapshot for Phase 1.
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
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'columns': columns,
        'rows': rows,
        'coins': coins,
        'gems': gems,
        'nextObjectSeq': nextObjectSeq,
        'updatedAtMs': updatedAtMs,
        'generators': generators.map((g) => g.toJson()).toList(),
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
    final objectEntries = (json['objects'] as List<dynamic>).map((raw) {
      final entry = raw as Map<String, dynamic>;
      return MapEntry(
        BoardPosition.fromJson(entry['pos'] as Map<String, dynamic>),
        GameObject.fromJson(entry['obj'] as Map<String, dynamic>),
      );
    });

    return GameState(
      schemaVersion: json['schemaVersion'] as int,
      columns: json['columns'] as int,
      rows: json['rows'] as int,
      coins: json['coins'] as int,
      gems: json['gems'] as int? ?? 0,
      nextObjectSeq: json['nextObjectSeq'] as int,
      updatedAtMs: json['updatedAtMs'] as int,
      generators: (json['generators'] as List<dynamic>)
          .map((g) => GeneratorState.fromJson(g as Map<String, dynamic>))
          .toList(),
      objects: Map<BoardPosition, GameObject>.fromEntries(objectEntries),
    );
  }
}
