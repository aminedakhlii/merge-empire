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

  static const int currentSchemaVersion = 3;

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
          // Phase 1 → Phase 2 progression fields.
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
