import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config/ads_config.dart';
import 'ad_service.dart';

/// AdMob-backed [AdService]. Uses [AdsConfig.activeUnits] (test IDs by default).
///
/// Fails soft: load/show errors return [AdShowResult.failed] / null banner and
/// never throw into gameplay.
class AdMobAdService implements AdService {
  AdMobAdService(this.config);

  final AdsConfig config;

  bool _initialized = false;
  bool _supported = false;
  BannerAd? _banner;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _bannerFailed = false;

  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } on Object {
      return false;
    }
  }

  String get _bannerUnit => config.activeUnits.banner;
  String get _interstitialUnit => config.activeUnits.interstitial;
  String get _rewardedUnit => config.activeUnits.rewarded;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!isMobilePlatform) {
      _supported = false;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _supported = true;
      unawaited(preloadInterstitial());
      unawaited(preloadRewarded());
    } on Object {
      _supported = false;
    }
  }

  @override
  Widget? bannerAd({required double maxWidth}) {
    if (!_supported || !config.bannerEnabled || _bannerFailed) return null;
    _ensureBanner(maxWidth);
    final ad = _banner;
    if (ad == null) return null;
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }

  void _ensureBanner(double maxWidth) {
    if (_banner != null || _bannerFailed) return;
    final width = maxWidth.floor().clamp(320, 414);
    final size = AdSize(width: width, height: 50);
    final ad = BannerAd(
      size: size,
      adUnitId: _bannerUnit,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
          _bannerFailed = true;
        },
      ),
      request: const AdRequest(),
    );
    _banner = ad;
    ad.load();
  }

  @override
  Future<void> preloadInterstitial() async {
    if (!_supported || !config.interstitialEnabled) return;
    if (_interstitial != null) return;
    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  @override
  Future<AdShowResult> showInterstitial({
    required bool boardInteracting,
  }) async {
    if (boardInteracting) return AdShowResult.skippedByPolicy;
    if (!_supported || !config.interstitialEnabled) return AdShowResult.notReady;
    final ad = _interstitial;
    if (ad == null) {
      unawaited(preloadInterstitial());
      return AdShowResult.notReady;
    }
    final completer = Completer<AdShowResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        unawaited(preloadInterstitial());
        if (!completer.isCompleted) completer.complete(AdShowResult.shown);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        unawaited(preloadInterstitial());
        if (!completer.isCompleted) completer.complete(AdShowResult.failed);
      },
    );
    try {
      await ad.show();
    } on Object {
      _interstitial = null;
      return AdShowResult.failed;
    }
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => AdShowResult.failed,
    );
  }

  @override
  Future<void> preloadRewarded() async {
    if (!_supported || !config.rewardedEnabled) return;
    if (_rewarded != null) return;
    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  @override
  Future<RewardedAdResult> showRewarded({
    required String claimId,
    required void Function(String claimId) onUserEarnedReward,
  }) async {
    if (!_supported || !config.rewardedEnabled) return RewardedAdResult.notReady;
    final ad = _rewarded;
    if (ad == null) {
      unawaited(preloadRewarded());
      return RewardedAdResult.notReady;
    }
    var earned = false;
    final completer = Completer<RewardedAdResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        unawaited(preloadRewarded());
        if (!completer.isCompleted) {
          completer.complete(
            earned
                ? RewardedAdResult.earned
                : RewardedAdResult.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        unawaited(preloadRewarded());
        if (!completer.isCompleted) {
          completer.complete(RewardedAdResult.failed);
        }
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
          onUserEarnedReward(claimId);
        },
      );
    } on Object {
      _rewarded = null;
      return RewardedAdResult.failed;
    }
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => RewardedAdResult.failed,
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    _interstitial?.dispose();
    _rewarded?.dispose();
    _banner = null;
    _interstitial = null;
    _rewarded = null;
  }
}
