import '../config/chain_config.dart';

/// A mergeable object occupying one board cell.
class GameObject {
  const GameObject({
    required this.id,
    required this.chainId,
    required this.level,
    this.locked = false,
  });

  final String id;
  final String chainId;
  final int level;
  final bool locked;

  bool canMergeWith(GameObject other) =>
      !locked &&
      !other.locked &&
      id != other.id &&
      chainId == other.chainId &&
      level == other.level;

  GameObject mergeResult({required String newId}) => GameObject(
        id: newId,
        chainId: chainId,
        level: level + 1,
      );

  ObjectLevelDef definition(ChainConfig chain) => chain.levelDef(level);

  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'level': level,
        'locked': locked,
      };

  factory GameObject.fromJson(Map<String, dynamic> json) => GameObject(
        id: json['id'] as String,
        chainId: json['chainId'] as String,
        level: json['level'] as int,
        locked: json['locked'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameObject &&
          id == other.id &&
          chainId == other.chainId &&
          level == other.level &&
          locked == other.locked;

  @override
  int get hashCode => Object.hash(id, chainId, level, locked);
}
