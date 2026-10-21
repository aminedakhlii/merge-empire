/// Analytics abstraction. Gameplay must not depend on backend availability.
abstract class AnalyticsService {
  Future<void> initialize();

  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]);

  Future<void> setUserProperty(String name, String? value);
}

/// Structured event names (Phase 3 required set).
abstract final class AnalyticsEvents {
  static const firstOpen = 'first_open';
  static const sessionStart = 'session_start';
  static const merge = 'merge';
  static const orderComplete = 'order_complete';
  static const shopUpgrade = 'shop_upgrade';
  static const sell = 'sell';
  static const adImpression = 'ad_impression';
  static const adRewardEarned = 'ad_reward_earned';
  static const adInterstitialShown = 'ad_interstitial_shown';
  static const adFailed = 'ad_failed';
  static const consentUpdate = 'consent_update';
  static const purchaseRemoveAds = 'purchase_remove_ads';
  static const missionClaim = 'mission_claim';
  static const dailyClaim = 'daily_claim';
}

/// In-memory recorder for tests.
class MockAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, Object?> params})> events = [];
  final Map<String, String?> userProperties = {};
  int initializeCount = 0;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> params = const {},
  ]) async {
    events.add((name: name, params: Map<String, Object?>.from(params)));
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    userProperties[name] = value;
  }
}

/// No-op / console analytics until Firebase is owner-wired.
class LoggingAnalyticsService implements AnalyticsService {
  LoggingAnalyticsService({this.logToConsole = false});

  final bool logToConsole;

  @override
  Future<void> initialize() async {
    await logEvent(AnalyticsEvents.sessionStart);
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> params = const {},
  ]) async {
    if (logToConsole) {
      // ignore: avoid_print
      print('[analytics] $name $params');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {}
}
