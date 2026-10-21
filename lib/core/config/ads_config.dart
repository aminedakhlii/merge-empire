/// AdMob unit IDs and frequency limits.
///
/// **Development uses Google's official test IDs only.**
/// Production IDs must be supplied by the owner via [AdsConfig.production]
/// (or a future remote/config override). Never invent production IDs.
class AdUnitIds {
  const AdUnitIds({
    required this.androidAppId,
    required this.iosAppId,
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  final String androidAppId;
  final String iosAppId;
  final String banner;
  final String interstitial;
  final String rewarded;

  /// Google sample / test units (safe for development).
  /// https://developers.google.com/admob/android/test-ads
  static const AdUnitIds test = AdUnitIds(
    androidAppId: 'ca-app-pub-3940256099942544~3347511713',
    iosAppId: 'ca-app-pub-3940256099942544~1458002511',
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  /// Placeholder slots for owner-supplied production IDs.
  /// Empty strings mean "not configured — do not load production ads".
  static const AdUnitIds productionUnconfigured = AdUnitIds(
    androidAppId: '',
    iosAppId: '',
    banner: '',
    interstitial: '',
    rewarded: '',
  );
}

enum AdsEnvironment { test, production }

class AdsConfig {
  const AdsConfig({
    this.environment = AdsEnvironment.test,
    this.testUnits = AdUnitIds.test,
    this.productionUnits = AdUnitIds.productionUnconfigured,
    this.interstitialMinIntervalSeconds = 180,
    this.interstitialMinMilestones = 3,
    this.interstitialMaxPerDay = 4,
    this.rewardedMaxPerDay = 5,
    this.rewardedMaxPerHour = 3,
    this.rewardedCoinBonus = 25,
    this.bannerEnabled = true,
    this.interstitialEnabled = true,
    this.rewardedEnabled = true,
  });

  final AdsEnvironment environment;
  final AdUnitIds testUnits;
  final AdUnitIds productionUnits;

  /// Interstitial: min seconds between shows (default 180).
  final int interstitialMinIntervalSeconds;

  /// Interstitial: min gameplay milestones before first/next show (default 3).
  final int interstitialMinMilestones;

  /// Interstitial: max shows per local calendar day (default 4).
  final int interstitialMaxPerDay;

  /// Rewarded: max completions per local day (default 5).
  final int rewardedMaxPerDay;

  /// Rewarded: max completions per rolling hour (default 3).
  final int rewardedMaxPerHour;

  /// Optional coin bonus after a verified rewarded callback.
  final int rewardedCoinBonus;

  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;

  AdUnitIds get activeUnits {
    if (environment == AdsEnvironment.production) {
      // Refuse to serve if owner has not configured production IDs.
      if (productionUnits.banner.isEmpty ||
          productionUnits.interstitial.isEmpty ||
          productionUnits.rewarded.isEmpty) {
        return testUnits;
      }
      return productionUnits;
    }
    return testUnits;
  }

  /// True when we would fall back because production IDs are missing.
  bool get productionIdsMissing =>
      environment == AdsEnvironment.production &&
      (productionUnits.banner.isEmpty ||
          productionUnits.interstitial.isEmpty ||
          productionUnits.rewarded.isEmpty);

  static const AdsConfig standard = AdsConfig();
}
