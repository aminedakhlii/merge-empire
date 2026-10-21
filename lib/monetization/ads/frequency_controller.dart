import '../../core/config/ads_config.dart';
import '../../core/models/ad_counters.dart';
import '../../features/progression/progression_logic.dart';

/// Pure frequency rules for interstitials and rewarded ads.
class AdFrequencyController {
  const AdFrequencyController(this.config);

  final AdsConfig config;

  AdCounters rollDay(AdCounters counters, DateTime now) {
    final today = localDayKey(now);
    var next = counters;
    if (counters.interstitialDayKey != today) {
      next = next.copyWith(
        interstitialDayKey: today,
        interstitialShownToday: 0,
      );
    }
    if (counters.rewardedDayKey != today) {
      next = next.copyWith(
        rewardedDayKey: today,
        rewardedShownToday: 0,
      );
    }
    return next;
  }

  AdCounters rollHour(AdCounters counters, int nowMs) {
    final window = counters.rewardedHourWindowStartMs;
    if (window == 0 || nowMs - window >= const Duration(hours: 1).inMilliseconds) {
      return counters.copyWith(
        rewardedHourWindowStartMs: nowMs,
        rewardedShownThisHour: 0,
      );
    }
    return counters;
  }

  AdCounters onMilestone(AdCounters counters) => counters.copyWith(
        milestonesSinceInterstitial: counters.milestonesSinceInterstitial + 1,
      );

  /// Interstitial eligibility — never called during active board drag.
  bool canShowInterstitial(
    AdCounters counters, {
    required int nowMs,
    required bool boardInteracting,
    required bool adsRemoved,
    required bool consentAllowsAds,
  }) {
    if (!config.interstitialEnabled) return false;
    if (adsRemoved || !consentAllowsAds) return false;
    if (boardInteracting) return false;

    if (counters.milestonesSinceInterstitial < config.interstitialMinMilestones) {
      return false;
    }
    if (counters.interstitialShownToday >= config.interstitialMaxPerDay) {
      return false;
    }
    final elapsed = nowMs - counters.lastInterstitialAtMs;
    if (counters.lastInterstitialAtMs > 0 &&
        elapsed < config.interstitialMinIntervalSeconds * 1000) {
      return false;
    }
    return true;
  }

  AdCounters recordInterstitialShown(AdCounters counters, int nowMs) =>
      counters.copyWith(
        interstitialShownToday: counters.interstitialShownToday + 1,
        lastInterstitialAtMs: nowMs,
        milestonesSinceInterstitial: 0,
      );

  bool canShowRewarded(
    AdCounters counters, {
    required int nowMs,
    required bool adsRemoved,
    required bool consentAllowsAds,
  }) {
    // Remove-ads still allows optional rewarded if desired; keep blocked when
    // ads removed for consistency (owner can change later).
    if (!config.rewardedEnabled) return false;
    if (adsRemoved || !consentAllowsAds) return false;
    if (counters.rewardedShownToday >= config.rewardedMaxPerDay) return false;
    if (counters.rewardedShownThisHour >= config.rewardedMaxPerHour) {
      return false;
    }
    return true;
  }

  AdCounters beginRewardedSession(AdCounters counters, String claimId) =>
      counters.copyWith(pendingRewardedClaimId: claimId);

  /// Returns updated counters if [claimId] is valid and not yet claimed.
  AdCounters? claimRewarded(AdCounters counters, String claimId, int nowMs) {
    if (claimId.isEmpty) return null;
    if (claimId == counters.lastRewardedClaimId) return null;
    if (claimId != counters.pendingRewardedClaimId) return null;

    var next = rollHour(counters, nowMs);
    next = next.copyWith(
      rewardedShownToday: next.rewardedShownToday + 1,
      rewardedShownThisHour: next.rewardedShownThisHour + 1,
      lastRewardedClaimId: claimId,
      pendingRewardedClaimId: '',
    );
    return next;
  }

  AdCounters clearPendingRewarded(AdCounters counters) =>
      counters.copyWith(pendingRewardedClaimId: '');
}
