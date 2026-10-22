import 'package:flutter/widgets.dart';

import 'ad_service.dart';

/// Deterministic ad service for unit tests — never fabricates rewards unless
/// [rewardOnShow] is true (simulating an SDK earned-reward callback).
class MockAdService implements AdService {
  MockAdService({
    this.interstitialReady = true,
    this.rewardedReady = true,
    this.rewardOnShow = true,
    this.failInterstitial = false,
    this.failRewarded = false,
    this.showBanner = false,
  });

  bool interstitialReady;
  bool rewardedReady;
  bool rewardOnShow;
  bool failInterstitial;
  bool failRewarded;
  bool showBanner;

  int interstitialShows = 0;
  int rewardedShows = 0;
  int initializeCount = 0;
  final List<String> rewardedClaimIds = [];

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Widget? bannerAd({required double maxWidth}) {
    if (!showBanner) return null;
    // Test-only marker — not styled as a real ad creative.
    return SizedBox(
      width: maxWidth,
      height: 50,
      child: const ColoredBox(
        color: Color(0x11000000),
        child: Center(child: Text('TEST_BANNER_SLOT')),
      ),
    );
  }

  @override
  Future<void> preloadInterstitial() async {}

  @override
  Future<AdShowResult> showInterstitial({required bool boardInteracting}) async {
    if (boardInteracting) return AdShowResult.skippedByPolicy;
    if (failInterstitial) return AdShowResult.failed;
    if (!interstitialReady) return AdShowResult.notReady;
    interstitialShows++;
    return AdShowResult.shown;
  }

  @override
  Future<void> preloadRewarded() async {}

  @override
  Future<RewardedAdResult> showRewarded({
    required String claimId,
    required void Function(String claimId) onUserEarnedReward,
  }) async {
    if (failRewarded) return RewardedAdResult.failed;
    if (!rewardedReady) return RewardedAdResult.notReady;
    rewardedShows++;
    rewardedClaimIds.add(claimId);
    if (rewardOnShow) {
      onUserEarnedReward(claimId);
      return RewardedAdResult.earned;
    }
    return RewardedAdResult.dismissedWithoutReward;
  }

  @override
  void dispose() {}
}
