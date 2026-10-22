import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/game_state.dart';

/// Versioned local save/load with backup + validation for crash recovery.
abstract class SaveService {
  Future<GameState?> load();
  Future<void> save(GameState state);
  Future<void> clear();
}

class SharedPreferencesSaveService implements SaveService {
  SharedPreferencesSaveService({
    SharedPreferences? prefs,
    this.storageKey = 'merge_empire_save_v1',
    this.backupKey = 'merge_empire_save_backup_v1',
  }) : _prefs = prefs;

  static const int currentSchemaVersion = 3;

  final String storageKey;
  final String backupKey;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<GameState?> load() async {
    final prefs = await _ensurePrefs();

    final primary = _decode(prefs.getString(storageKey));
    if (primary != null) return primary;

    // Crash / corruption: fall back to last known good backup.
    final backup = _decode(prefs.getString(backupKey));
    if (backup != null) {
      // Promote backup so the next launch has a healthy primary.
      await prefs.setString(storageKey, jsonEncode(backup.toJson()));
      return backup;
    }
    return null;
  }

  GameState? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!looksLikeSave(json)) return null;
      final migrated = migrate(json);
      final state = GameState.fromJson(migrated);
      return validateState(state) ? state : null;
    } on Object {
      return null;
    }
  }

  /// Structural sanity checks before trusting persisted JSON.
  static bool looksLikeSave(Map<String, dynamic> json) {
    return json.containsKey('schemaVersion') ||
        (json.containsKey('columns') && json.containsKey('rows'));
  }

  /// Reject obviously inconsistent states (negative currency, bad board size).
  static bool validateState(GameState state) {
    if (state.columns < 1 || state.rows < 1) return false;
    if (state.coins < 0 || state.gems < 0) return false;
    if (state.playerLevel < 1 || state.shopLevel < 1) return false;
    if (state.nextObjectSeq < 1) return false;
    for (final pos in state.objects.keys) {
      if (pos.column < 0 ||
          pos.row < 0 ||
          pos.column >= state.columns ||
          pos.row >= state.rows) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> save(GameState state) async {
    if (!validateState(state)) {
      throw StateError('Refusing to persist invalid GameState');
    }
    final prefs = await _ensurePrefs();
    final payload = state.copyWith(schemaVersion: currentSchemaVersion);
    final encoded = jsonEncode(payload.toJson());

    // Write backup of previous primary first (if any), then primary.
    // SharedPreferences commits are per-key; dual keys limit loss on crash.
    final previous = prefs.getString(storageKey);
    if (previous != null && previous.isNotEmpty && previous != encoded) {
      await prefs.setString(backupKey, previous);
    }
    await prefs.setString(storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(storageKey);
    await prefs.remove(backupKey);
  }

  /// Apply sequential migrations from [json]'s schemaVersion to current.
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    var version = json['schemaVersion'] as int? ?? 0;
    var data = Map<String, dynamic>.from(json);

    while (version < currentSchemaVersion) {
      switch (version) {
        case 0:
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
        case 1:
          data = {
            ...data,
            'schemaVersion': 2,
            'playerXp': data['playerXp'] ?? 0,
            'playerLevel': data['playerLevel'] ?? 1,
            'shopLevel': data['shopLevel'] ?? 1,
            'nextOrderSeq': data['nextOrderSeq'] ?? 1,
            'orders': data['orders'] ?? <dynamic>[],
            'missions': data['missions'] ?? <dynamic>[],
            'achievements': data['achievements'] ?? <dynamic>[],
            'daily': data['daily'] ??
                {
                  'dayKey': '',
                  'challengeId': '',
                  'progress': 0,
                  'target': 1,
                  'claimed': false,
                  'activityStreak': 0,
                  'uniqueActiveDays': 0,
                },
            'stats': data['stats'] ??
                {
                  'mergeCount': 0,
                  'ordersCompleted': 0,
                  'coinsEarnedLifetime': 0,
                  'collectCount': 0,
                  'shopUpgrades': 0,
                  'maxObjectLevelSeen': 1,
                  'lastSeenDayKey': '',
                },
            'tutorialStep': data['tutorialStep'] ?? 'welcome',
            'tutorialCompleted': data['tutorialCompleted'] ?? false,
            'soundEnabled': data['soundEnabled'] ?? true,
            'hapticsEnabled': data['hapticsEnabled'] ?? true,
          };
          version = 2;
        case 2:
          data = {
            ...data,
            'schemaVersion': 3,
            'removeAdsEntitlement': data['removeAdsEntitlement'] ?? false,
            'adCounters': data['adCounters'] ??
                {
                  'interstitialShownToday': 0,
                  'interstitialDayKey': '',
                  'lastInterstitialAtMs': 0,
                  'milestonesSinceInterstitial': 0,
                  'rewardedShownToday': 0,
                  'rewardedDayKey': '',
                  'rewardedHourWindowStartMs': 0,
                  'rewardedShownThisHour': 0,
                  'lastRewardedClaimId': '',
                  'pendingRewardedClaimId': '',
                },
          };
          version = 3;
        default:
          throw StateError('No migration from schema $version');
      }
    }
    return data;
  }
}

/// In-memory save for unit tests (supports optional backup for recovery tests).
class InMemorySaveService implements SaveService {
  GameState? _state;
  GameState? _backup;

  GameState? get backup => _backup;

  @override
  Future<GameState?> load() async {
    if (_state != null && SharedPreferencesSaveService.validateState(_state!)) {
      return _state;
    }
    if (_backup != null &&
        SharedPreferencesSaveService.validateState(_backup!)) {
      _state = _backup;
      return _backup;
    }
    return null;
  }

  @override
  Future<void> save(GameState state) async {
    if (!SharedPreferencesSaveService.validateState(state)) {
      throw StateError('Refusing to persist invalid GameState');
    }
    if (_state != null) _backup = _state;
    _state = state;
  }

  /// Test helper: corrupt primary while leaving backup intact.
  void corruptPrimaryKeepBackup() {
    _state = null;
  }

  @override
  Future<void> clear() async {
    _state = null;
    _backup = null;
  }
}
