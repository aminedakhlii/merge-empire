import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/game_state.dart';

/// Versioned local save/load. Schema migrations go here as versions grow.
abstract class SaveService {
  Future<GameState?> load();
  Future<void> save(GameState state);
  Future<void> clear();
}

class SharedPreferencesSaveService implements SaveService {
  SharedPreferencesSaveService({
    SharedPreferences? prefs,
    this.storageKey = 'merge_empire_save_v1',
  }) : _prefs = prefs;

  static const int currentSchemaVersion = 1;

  final String storageKey;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<GameState?> load() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final migrated = migrate(json);
      return GameState.fromJson(migrated);
    } on Object {
      // Malformed save: treat as missing rather than crash.
      return null;
    }
  }

  @override
  Future<void> save(GameState state) async {
    final prefs = await _ensurePrefs();
    final payload = state.copyWith(schemaVersion: currentSchemaVersion);
    await prefs.setString(storageKey, jsonEncode(payload.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(storageKey);
  }

  /// Apply sequential migrations from [json]'s schemaVersion to current.
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    var version = json['schemaVersion'] as int? ?? 0;
    var data = Map<String, dynamic>.from(json);

    while (version < currentSchemaVersion) {
      switch (version) {
        case 0:
          // Pre-versioned / missing → v1: ensure required keys.
          data = {
            'schemaVersion': 1,
            'columns': data['columns'] ?? 7,
            'rows': data['rows'] ?? 9,
            'coins': data['coins'] ?? 0,
            'gems': data['gems'] ?? 0,
            'nextObjectSeq': data['nextObjectSeq'] ?? 1,
            'updatedAtMs':
                data['updatedAtMs'] ?? DateTime.now().millisecondsSinceEpoch,
            'generators': data['generators'] ?? <dynamic>[],
            'objects': data['objects'] ?? <dynamic>[],
          };
          version = 1;
        default:
          throw StateError('No migration from schema $version');
      }
    }
    return data;
  }
}

/// In-memory save for unit tests.
class InMemorySaveService implements SaveService {
  GameState? _state;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}
