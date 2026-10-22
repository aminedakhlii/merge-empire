/// Persisted ad frequency / claim state (schema v3+).
class AdCounters {
  const AdCounters({
    this.interstitialShownToday = 0,
    this.interstitialDayKey = '',
    this.lastInterstitialAtMs = 0,
    this.milestonesSinceInterstitial = 0,
    this.rewardedShownToday = 0,
    this.rewardedDayKey = '',
    this.rewardedHourWindowStartMs = 0,
    this.rewardedShownThisHour = 0,
    this.lastRewardedClaimId = '',
    this.pendingRewardedClaimId = '',
  });

  final int interstitialShownToday;
  final String interstitialDayKey;
  final int lastInterstitialAtMs;
  final int milestonesSinceInterstitial;

  final int rewardedShownToday;
  final String rewardedDayKey;
  final int rewardedHourWindowStartMs;
  final int rewardedShownThisHour;

  /// Last successfully claimed reward id (prevents duplicate grants).
  final String lastRewardedClaimId;

  /// In-flight reward session awaiting SDK callback + claim.
  final String pendingRewardedClaimId;

  AdCounters copyWith({
    int? interstitialShownToday,
    String? interstitialDayKey,
    int? lastInterstitialAtMs,
    int? milestonesSinceInterstitial,
    int? rewardedShownToday,
    String? rewardedDayKey,
    int? rewardedHourWindowStartMs,
    int? rewardedShownThisHour,
    String? lastRewardedClaimId,
    String? pendingRewardedClaimId,
  }) =>
      AdCounters(
        interstitialShownToday:
            interstitialShownToday ?? this.interstitialShownToday,
        interstitialDayKey: interstitialDayKey ?? this.interstitialDayKey,
        lastInterstitialAtMs:
            lastInterstitialAtMs ?? this.lastInterstitialAtMs,
        milestonesSinceInterstitial: milestonesSinceInterstitial ??
            this.milestonesSinceInterstitial,
        rewardedShownToday: rewardedShownToday ?? this.rewardedShownToday,
        rewardedDayKey: rewardedDayKey ?? this.rewardedDayKey,
        rewardedHourWindowStartMs:
            rewardedHourWindowStartMs ?? this.rewardedHourWindowStartMs,
        rewardedShownThisHour:
            rewardedShownThisHour ?? this.rewardedShownThisHour,
        lastRewardedClaimId: lastRewardedClaimId ?? this.lastRewardedClaimId,
        pendingRewardedClaimId:
            pendingRewardedClaimId ?? this.pendingRewardedClaimId,
      );

  Map<String, dynamic> toJson() => {
        'interstitialShownToday': interstitialShownToday,
        'interstitialDayKey': interstitialDayKey,
        'lastInterstitialAtMs': lastInterstitialAtMs,
        'milestonesSinceInterstitial': milestonesSinceInterstitial,
        'rewardedShownToday': rewardedShownToday,
        'rewardedDayKey': rewardedDayKey,
        'rewardedHourWindowStartMs': rewardedHourWindowStartMs,
        'rewardedShownThisHour': rewardedShownThisHour,
        'lastRewardedClaimId': lastRewardedClaimId,
        'pendingRewardedClaimId': pendingRewardedClaimId,
      };

  factory AdCounters.fromJson(Map<String, dynamic> json) => AdCounters(
        interstitialShownToday: json['interstitialShownToday'] as int? ?? 0,
        interstitialDayKey: json['interstitialDayKey'] as String? ?? '',
        lastInterstitialAtMs: json['lastInterstitialAtMs'] as int? ?? 0,
        milestonesSinceInterstitial:
            json['milestonesSinceInterstitial'] as int? ?? 0,
        rewardedShownToday: json['rewardedShownToday'] as int? ?? 0,
        rewardedDayKey: json['rewardedDayKey'] as String? ?? '',
        rewardedHourWindowStartMs:
            json['rewardedHourWindowStartMs'] as int? ?? 0,
        rewardedShownThisHour: json['rewardedShownThisHour'] as int? ?? 0,
        lastRewardedClaimId: json['lastRewardedClaimId'] as String? ?? '',
        pendingRewardedClaimId: json['pendingRewardedClaimId'] as String? ?? '',
      );
}
