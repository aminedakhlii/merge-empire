import 'package:flutter/widgets.dart';

/// Result of attempting to show a full-screen ad.
enum AdShowResult {
  shown,
  skippedByPolicy,
  notReady,
  failed,
  adsRemoved,
}

/// Result of a rewarded attempt. Rewards must only be granted on [earned].
enum RewardedAdResult {
  earned,
  dismissedWithoutReward,
  notReady,
  failed,
  skippedByPolicy,
  adsRemoved,
}

/// Platform-agnostic ads API. Gameplay widgets depend on this — never on
/// `google_mobile_ads` directly.
abstract class AdService {
  Future<void> initialize();

  /// Reserved banner region. Returns null when no ad should render (no fake UI).
  Widget? bannerAd({required double maxWidth});

  Future<void> preloadInterstitial();

  Future<AdShowResult> showInterstitial({
    required bool boardInteracting,
  });

  Future<void> preloadRewarded();

  /// Shows rewarded ad. [onUserEarnedReward] is invoked only from SDK callback.
  Future<RewardedAdResult> showRewarded({
    required String claimId,
    required void Function(String claimId) onUserEarnedReward,
  });

  void dispose();
}

/// No-op service for unsupported platforms, offline, or ads-removed.
class NoOpAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  Widget? bannerAd({required double maxWidth}) => null;

  @override
  Future<void> preloadInterstitial() async {}

  @override
  Future<AdShowResult> showInterstitial({required bool boardInteracting}) async =>
      AdShowResult.notReady;

  @override
  Future<void> preloadRewarded() async {}

  @override
  Future<RewardedAdResult> showRewarded({
    required String claimId,
    required void Function(String claimId) onUserEarnedReward,
  }) async =>
      RewardedAdResult.notReady;

  @override
  void dispose() {}
}
