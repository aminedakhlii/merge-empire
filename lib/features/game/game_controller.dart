import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../consent/consent_service.dart';
import '../../core/config/game_config.dart';
import '../../core/models/board_position.dart';
import '../../core/models/game_state.dart';
import '../../features/analytics/analytics_service.dart';
import '../../features/purchases/purchases_service.dart';
import '../../monetization/ads/ad_service.dart';
import '../../monetization/ads/frequency_controller.dart';
import '../../monetization/monetization_providers.dart';
import '../persistence/save_service.dart';
import 'game_logic.dart';

class GameControllerState {
  const GameControllerState({
    required this.game,
    this.selected,
    this.statusMessage,
    this.isReady = false,
    this.boardInteracting = false,
  });

  final GameState game;
  final BoardPosition? selected;
  final String? statusMessage;
  final bool isReady;

  /// True while the player is dragging on the board — blocks interstitials.
  final bool boardInteracting;

  GameControllerState copyWith({
    GameState? game,
    BoardPosition? selected,
    String? statusMessage,
    bool clearSelected = false,
    bool clearStatus = false,
    bool? isReady,
    bool? boardInteracting,
  }) =>
      GameControllerState(
        game: game ?? this.game,
        selected: clearSelected ? null : (selected ?? this.selected),
        statusMessage:
            clearStatus ? null : (statusMessage ?? this.statusMessage),
        isReady: isReady ?? this.isReady,
        boardInteracting: boardInteracting ?? this.boardInteracting,
      );
}

class GameController extends Notifier<GameControllerState> {
  GameController({
    GameLogic? logic,
    SaveService? saveService,
    AdService? adService,
    AnalyticsService? analytics,
    ConsentService? consent,
    PurchasesService? purchases,
    AdFrequencyController? frequency,
    this.autoSave = true,
    this.tickInterval = const Duration(seconds: 1),
  })  : _logicOverride = logic,
        _saveOverride = saveService,
        _adOverride = adService,
        _analyticsOverride = analytics,
        _consentOverride = consent,
        _purchasesOverride = purchases,
        _frequencyOverride = frequency;

  final GameLogic? _logicOverride;
  final SaveService? _saveOverride;
  final AdService? _adOverride;
  final AnalyticsService? _analyticsOverride;
  final ConsentService? _consentOverride;
  final PurchasesService? _purchasesOverride;
  final AdFrequencyController? _frequencyOverride;
  final bool autoSave;
  final Duration tickInterval;

  late GameLogic _logic;
  late SaveService _save;
  late AdService _ads;
  late AnalyticsService _analytics;
  late ConsentService _consent;
  late PurchasesService _purchases;
  late AdFrequencyController _frequency;
  Timer? _tickTimer;
  int _rewardSeq = 0;

  @override
  GameControllerState build() {
    _logic = _logicOverride ?? GameLogic(config: GameConfig.standard);
    _save = _saveOverride ?? SharedPreferencesSaveService();
    _ads = _adOverride ?? ref.read(adServiceProvider);
    _analytics = _analyticsOverride ?? ref.read(analyticsServiceProvider);
    _consent = _consentOverride ?? ref.read(consentServiceProvider);
    _purchases = _purchasesOverride ?? ref.read(purchasesServiceProvider);
    _frequency =
        _frequencyOverride ?? ref.read(adFrequencyControllerProvider);

    final initial = _logic.createInitialState();
    Future.microtask(_bootstrap);

    ref.onDispose(() {
      _tickTimer?.cancel();
    });

    return GameControllerState(game: initial, isReady: false);
  }

  Future<void> _bootstrap() async {
    await _consent.gatherConsent();
    unawaited(_consent.requestTrackingAuthorizationIfNeeded());
    await _analytics.initialize();
    await _purchases.initialize();
    // Ads init never blocks gameplay if it fails.
    try {
      await _ads.initialize();
    } on Object {
      unawaited(_analytics.logEvent(AnalyticsEvents.adFailed, {
        'stage': 'initialize',
      }));
    }

    final loaded = await _save.load();
    var game = loaded ?? _logic.createInitialState();
    if (game.missions.isEmpty || game.achievements.isEmpty) {
      final fresh = _logic.createInitialState(nowMs: game.updatedAtMs);
      game = game.copyWith(
        missions: game.missions.isEmpty ? fresh.missions : game.missions,
        achievements:
            game.achievements.isEmpty ? fresh.achievements : game.achievements,
        orders: game.orders.isEmpty ? fresh.orders : game.orders,
        daily: game.daily.dayKey.isEmpty ? fresh.daily : game.daily,
      );
    }
    if (_purchases.removeAdsOwned && !game.removeAdsEntitlement) {
      game = game.copyWith(removeAdsEntitlement: true);
    }
    final ticked = _logic.tickGenerators(game);
    state = GameControllerState(game: ticked, isReady: true);
    if (loaded == null) {
      unawaited(_analytics.logEvent(AnalyticsEvents.firstOpen));
    }
    await _persist();
    _startTicker();
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(tickInterval, (_) {
      final next = _logic.tickGenerators(state.game);
      if (next.generators != state.game.generators ||
          next.daily.dayKey != state.game.daily.dayKey) {
        state = state.copyWith(game: next);
        unawaited(_persist());
      } else {
        state = state.copyWith(game: next);
      }
    });
  }

  Future<void> _persist() async {
    if (!autoSave) return;
    await _save.save(state.game);
  }

  bool get _adsRemoved =>
      state.game.removeAdsEntitlement || _purchases.removeAdsOwned;

  Future<void> _apply(
    ActionResult result, {
    bool countMilestone = false,
    String? analyticsEvent,
    Map<String, Object?> analyticsParams = const {},
  }) async {
    switch (result) {
      case ActionSuccess(:final state, :final message):
        var next = state;
        if (countMilestone) {
          next = _logic.bumpAdMilestone(next);
        }
        final interacting = this.state.boardInteracting;
        this.state = GameControllerState(
          game: next,
          statusMessage: message,
          isReady: true,
          boardInteracting: interacting,
        );
        await _persist();
        if (analyticsEvent != null) {
          unawaited(_analytics.logEvent(analyticsEvent, analyticsParams));
        }
        if (countMilestone) {
          unawaited(_maybeShowInterstitial());
        }
      case ActionFailure(:final reason):
        state = state.copyWith(statusMessage: reason);
    }
  }

  Future<void> _maybeShowInterstitial() async {
    if (_adsRemoved || !_consent.canRequestAds) return;
    if (state.boardInteracting) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    var counters = _frequency.rollDay(state.game.adCounters, now);
    counters = _frequency.rollHour(counters, nowMs);

    final allowed = _frequency.canShowInterstitial(
      counters,
      nowMs: nowMs,
      boardInteracting: state.boardInteracting,
      adsRemoved: _adsRemoved,
      consentAllowsAds: _consent.canRequestAds,
    );
    if (!allowed) return;

    final result = await _ads.showInterstitial(
      boardInteracting: state.boardInteracting,
    );
    if (result == AdShowResult.shown) {
      final updated = _logic.recordInterstitialShown(state.game, nowMs: nowMs);
      state = state.copyWith(game: updated);
      await _persist();
      unawaited(_analytics.logEvent(AnalyticsEvents.adInterstitialShown));
      unawaited(_analytics.logEvent(AnalyticsEvents.adImpression, {
        'format': 'interstitial',
      }));
    } else if (result == AdShowResult.failed) {
      unawaited(_analytics.logEvent(AnalyticsEvents.adFailed, {
        'format': 'interstitial',
      }));
    }
  }

  void setBoardInteracting(bool interacting) {
    if (state.boardInteracting == interacting) return;
    state = state.copyWith(boardInteracting: interacting);
  }

  void selectCell(BoardPosition pos) {
    final object = state.game.objectAt(pos);
    if (object == null) {
      state = state.copyWith(clearSelected: true, clearStatus: true);
      return;
    }
    if (state.selected == pos) {
      state = state.copyWith(clearSelected: true);
      return;
    }
    state = state.copyWith(selected: pos, clearStatus: true);
  }

  Future<void> collectFromGenerator({
    String generatorId = 'basic_coffee_generator',
  }) async {
    await _apply(
      _logic.collectFromGenerator(state.game, generatorId: generatorId),
    );
  }

  Future<void> moveOrMerge(BoardPosition from, BoardPosition to) async {
    final before = state.game.occupiedCount;
    final result = _logic.moveOrMerge(state.game, from, to);
    final merged = result is ActionSuccess &&
        result.state.occupiedCount < before &&
        result.message?.startsWith('Merged') == true;
    await _apply(
      result,
      analyticsEvent: merged ? AnalyticsEvents.merge : null,
    );
  }

  Future<void> sellSelected() async {
    final selected = state.selected;
    if (selected == null) {
      state = state.copyWith(statusMessage: 'Select an object to sell');
      return;
    }
    await _apply(
      _logic.sellObject(state.game, selected),
      analyticsEvent: AnalyticsEvents.sell,
    );
  }

  Future<void> sellAt(BoardPosition pos) async {
    await _apply(
      _logic.sellObject(state.game, pos),
      analyticsEvent: AnalyticsEvents.sell,
    );
  }

  Future<void> completeOrder(String instanceId) async {
    await _apply(
      _logic.completeOrder(state.game, instanceId),
      countMilestone: true,
      analyticsEvent: AnalyticsEvents.orderComplete,
    );
  }

  Future<void> upgradeShop() async {
    await _apply(
      _logic.upgradeShop(state.game),
      countMilestone: true,
      analyticsEvent: AnalyticsEvents.shopUpgrade,
    );
  }

  Future<void> claimMission(String missionId) async {
    await _apply(
      _logic.claimMission(state.game, missionId),
      countMilestone: true,
      analyticsEvent: AnalyticsEvents.missionClaim,
      analyticsParams: {'mission_id': missionId},
    );
  }

  Future<void> claimAchievement(String achievementId) async {
    await _apply(
      _logic.claimAchievement(state.game, achievementId),
      countMilestone: true,
    );
  }

  Future<void> claimDaily() async {
    await _apply(
      _logic.claimDaily(state.game),
      countMilestone: true,
      analyticsEvent: AnalyticsEvents.dailyClaim,
    );
  }

  Future<void> dismissTutorial() async {
    await _apply(_logic.dismissTutorial(state.game));
  }

  Future<void> advanceTutorial() async {
    await _apply(_logic.advanceTutorialManual(state.game));
  }

  /// Optional rewarded bonus — never required for core play.
  Future<void> watchRewardedBonus() async {
    if (_adsRemoved || !_consent.canRequestAds) {
      state = state.copyWith(statusMessage: 'Rewarded ads unavailable');
      return;
    }

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    var counters = _frequency.rollDay(state.game.adCounters, now);
    counters = _frequency.rollHour(counters, nowMs);
    if (!_frequency.canShowRewarded(
      counters,
      nowMs: nowMs,
      adsRemoved: _adsRemoved,
      consentAllowsAds: _consent.canRequestAds,
    )) {
      state = state.copyWith(
        statusMessage: 'Rewarded limit reached — try again later',
      );
      return;
    }

    final claimId = 'rw_${nowMs}_${++_rewardSeq}';
    var game = _logic.beginRewardedClaim(
      state.game.copyWith(adCounters: counters),
      claimId,
    );
    state = state.copyWith(game: game);
    await _persist();

    var earned = false;
    final result = await _ads.showRewarded(
      claimId: claimId,
      onUserEarnedReward: (id) {
        earned = true;
        // Grant happens after show returns; callback only marks SDK success.
      },
    );

    if (result == RewardedAdResult.earned || earned) {
      await _apply(
        _logic.grantRewardedBonus(state.game, claimId),
        analyticsEvent: AnalyticsEvents.adRewardEarned,
        analyticsParams: {'claim_id': claimId},
      );
      unawaited(_analytics.logEvent(AnalyticsEvents.adImpression, {
        'format': 'rewarded',
      }));
    } else {
      game = _logic.clearPendingRewarded(state.game);
      state = state.copyWith(
        game: game,
        statusMessage: result == RewardedAdResult.notReady
            ? 'Rewarded ad not ready'
            : 'No reward earned',
      );
      await _persist();
      if (result == RewardedAdResult.failed) {
        unawaited(_analytics.logEvent(AnalyticsEvents.adFailed, {
          'format': 'rewarded',
        }));
      }
    }
  }

  bool canOfferRewarded() {
    if (_adsRemoved || !_consent.canRequestAds) return false;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    var counters = _frequency.rollDay(state.game.adCounters, now);
    counters = _frequency.rollHour(counters, nowMs);
    return _frequency.canShowRewarded(
      counters,
      nowMs: nowMs,
      adsRemoved: _adsRemoved,
      consentAllowsAds: _consent.canRequestAds,
    );
  }

  Future<void> openPrivacyOptions() async {
    await _consent.showPrivacyOptions();
    unawaited(_analytics.logEvent(AnalyticsEvents.consentUpdate, {
      'action': 'privacy_options',
    }));
  }

  Future<void> purchaseRemoveAds() async {
    final result = await _purchases.purchaseRemoveAds();
    if (result == PurchaseResult.success) {
      state = state.copyWith(
        game: state.game.copyWith(removeAdsEntitlement: true),
        statusMessage: 'Ads removed',
      );
      await _persist();
      unawaited(_analytics.logEvent(AnalyticsEvents.purchaseRemoveAds));
    } else if (result == PurchaseResult.featureDisabled) {
      state = state.copyWith(
        statusMessage: 'Remove Ads IAP coming soon (feature flagged off)',
      );
    } else {
      state = state.copyWith(statusMessage: 'Purchase unavailable');
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(game: state.game.copyWith(soundEnabled: enabled));
    await _persist();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(game: state.game.copyWith(hapticsEnabled: enabled));
    await _persist();
  }

  int? selectedSaleValue() {
    final selected = state.selected;
    if (selected == null) return null;
    final object = state.game.objectAt(selected);
    if (object == null) return null;
    return _logic.saleValue(object);
  }

  bool selectedIsValuable() {
    final selected = state.selected;
    if (selected == null) return false;
    final object = state.game.objectAt(selected);
    if (object == null) return false;
    return _logic.isValuableSale(object);
  }

  GameLogic get logic => _logic;

  int get rewardedBonusCoins => _logic.config.ads.rewardedCoinBonus;
}

final gameControllerProvider =
    NotifierProvider<GameController, GameControllerState>(GameController.new);
