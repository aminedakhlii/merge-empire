import 'package:flutter_test/flutter_test.dart';
import 'package:merge_empire/core/config/ads_config.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/core/models/ad_counters.dart';
import 'package:merge_empire/features/analytics/analytics_service.dart';
import 'package:merge_empire/features/game/game_logic.dart';
import 'package:merge_empire/features/purchases/purchases_service.dart';
import 'package:merge_empire/monetization/ads/ad_service.dart';
import 'package:merge_empire/monetization/ads/frequency_controller.dart';
import 'package:merge_empire/monetization/ads/mock_ad_service.dart';
import 'package:merge_empire/features/progression/progression_logic.dart';

void main() {
  group('AdsConfig', () {
    test('uses Google test unit IDs in test environment', () {
      const config = AdsConfig.standard;
      expect(config.environment, AdsEnvironment.test);
      expect(config.activeUnits.banner, AdUnitIds.test.banner);
      expect(config.activeUnits.banner, contains('3940256099942544'));
    });

    test('production without owner IDs is flagged and does not invent IDs', () {
      const config = AdsConfig(environment: AdsEnvironment.production);
      expect(config.productionIdsMissing, isTrue);
      expect(config.productionUnits.banner, isEmpty);
      // Falls back to test units rather than fabricating production IDs.
      expect(config.activeUnits.banner, AdUnitIds.test.banner);
    });
  });

  group('AdFrequencyController', () {
    late AdFrequencyController freq;
    final now = DateTime(2026, 10, 21, 15);
    final nowMs = now.millisecondsSinceEpoch;

    setUp(() {
      freq = const AdFrequencyController(AdsConfig.standard);
    });

    test('blocks interstitial during board interaction', () {
      var c = const AdCounters(milestonesSinceInterstitial: 5);
      c = freq.rollDay(c, now);
      expect(
        freq.canShowInterstitial(
          c,
          nowMs: nowMs,
          boardInteracting: true,
          adsRemoved: false,
          consentAllowsAds: true,
        ),
        isFalse,
      );
    });

    test('requires milestones, interval, and daily cap', () {
      var c = freq.rollDay(const AdCounters(), now);
      expect(
        freq.canShowInterstitial(
          c,
          nowMs: nowMs,
          boardInteracting: false,
          adsRemoved: false,
          consentAllowsAds: true,
        ),
        isFalse,
      );

      c = c.copyWith(milestonesSinceInterstitial: 3);
      expect(
        freq.canShowInterstitial(
          c,
          nowMs: nowMs,
          boardInteracting: false,
          adsRemoved: false,
          consentAllowsAds: true,
        ),
        isTrue,
      );

      c = freq.recordInterstitialShown(c, nowMs);
      expect(c.milestonesSinceInterstitial, 0);
      expect(c.interstitialShownToday, 1);

      // Interval not elapsed.
      expect(
        freq.canShowInterstitial(
          c.copyWith(milestonesSinceInterstitial: 3),
          nowMs: nowMs + 1000,
          boardInteracting: false,
          adsRemoved: false,
          consentAllowsAds: true,
        ),
        isFalse,
      );

      // Daily cap.
      c = c.copyWith(
        interstitialShownToday: 4,
        milestonesSinceInterstitial: 3,
        lastInterstitialAtMs: nowMs - 200000,
      );
      expect(
        freq.canShowInterstitial(
          c,
          nowMs: nowMs,
          boardInteracting: false,
          adsRemoved: false,
          consentAllowsAds: true,
        ),
        isFalse,
      );
    });

    test('rewarded claim-once and hourly/daily limits', () {
      var c = freq.rollDay(const AdCounters(), now);
      c = freq.rollHour(c, nowMs);
      expect(
        freq.canShowRewarded(
          c,
          nowMs: nowMs,
          adsRemoved: false,
          consentAllowsAds: true,
        ),
        isTrue,
      );

      c = freq.beginRewardedSession(c, 'claim_a');
      final claimed = freq.claimRewarded(c, 'claim_a', nowMs);
      expect(claimed, isNotNull);
      expect(claimed!.lastRewardedClaimId, 'claim_a');
      expect(claimed.pendingRewardedClaimId, isEmpty);

      // Duplicate claim rejected.
      expect(freq.claimRewarded(claimed, 'claim_a', nowMs), isNull);

      // Wrong pending id rejected.
      final pending = freq.beginRewardedSession(claimed, 'claim_b');
      expect(freq.claimRewarded(pending, 'claim_other', nowMs), isNull);
    });

    test('ads removed or consent denied blocks formats', () {
      final c = freq.rollDay(
        const AdCounters(milestonesSinceInterstitial: 5),
        now,
      );
      expect(
        freq.canShowInterstitial(
          c,
          nowMs: nowMs,
          boardInteracting: false,
          adsRemoved: true,
          consentAllowsAds: true,
        ),
        isFalse,
      );
      expect(
        freq.canShowRewarded(
          c,
          nowMs: nowMs,
          adsRemoved: false,
          consentAllowsAds: false,
        ),
        isFalse,
      );
    });
  });

  group('MockAdService', () {
    test('does not grant reward without SDK callback path', () async {
      final ads = MockAdService(rewardOnShow: false);
      var earned = false;
      final result = await ads.showRewarded(
        claimId: 'x',
        onUserEarnedReward: (_) => earned = true,
      );
      expect(result, RewardedAdResult.dismissedWithoutReward);
      expect(earned, isFalse);
    });

    test('invokes earned callback only when configured', () async {
      final ads = MockAdService(rewardOnShow: true);
      var earnedId = '';
      final result = await ads.showRewarded(
        claimId: 'y',
        onUserEarnedReward: (id) => earnedId = id,
      );
      expect(result, RewardedAdResult.earned);
      expect(earnedId, 'y');
    });
  });

  group('GameLogic rewarded grant', () {
    test('grants coins once per claim id from SDK path', () {
      final logic = GameLogic(
        config: GameConfig.standard,
        clockMs: () => 1_000_000,
      );
      var state = logic.createInitialState(nowMs: 1_000_000);
      state = logic.beginRewardedClaim(state, 'rw_1');
      final coinsBefore = state.coins;

      final ok = logic.grantRewardedBonus(state, 'rw_1', nowMs: 1_000_000);
      expect(ok, isA<ActionSuccess>());
      final next = (ok as ActionSuccess).state;
      expect(next.coins, coinsBefore + logic.config.ads.rewardedCoinBonus);

      final again = logic.grantRewardedBonus(next, 'rw_1', nowMs: 1_000_001);
      expect(again, isA<ActionFailure>());
    });

    test('rejects grant without pending session (no fabricated rewards)', () {
      final logic = GameLogic(
        config: GameConfig.standard,
        clockMs: () => 1_000_000,
      );
      final state = logic.createInitialState(nowMs: 1_000_000);
      final result = logic.grantRewardedBonus(state, 'forged', nowMs: 1_000_000);
      expect(result, isA<ActionFailure>());
    });
  });

  group('Purchases feature flag', () {
    test('remove ads purchase returns featureDisabled when flagged off', () async {
      final purchases = MockPurchasesService(enabled: false);
      expect(await purchases.purchaseRemoveAds(), PurchaseResult.featureDisabled);
      expect(purchases.removeAdsOwned, isFalse);
    });
  });

  group('Analytics abstraction', () {
    test('records structured events without backend', () async {
      final analytics = MockAnalyticsService();
      await analytics.initialize();
      await analytics.logEvent(AnalyticsEvents.merge, {'level': 2});
      expect(analytics.events.any((e) => e.name == AnalyticsEvents.merge), isTrue);
    });
  });

  group('day key helper still stable', () {
    test('localDayKey format', () {
      expect(localDayKey(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });
}
