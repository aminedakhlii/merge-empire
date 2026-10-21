import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consent/consent_service.dart';
import '../core/config/ads_config.dart';
import '../core/config/purchases_config.dart';
import '../features/analytics/analytics_service.dart';
import '../features/game/game_controller.dart';
import '../features/purchases/purchases_service.dart';
import 'ads/ad_service.dart';
import 'ads/admob_ad_service.dart';
import 'ads/frequency_controller.dart';

final adsConfigProvider = Provider<AdsConfig>((ref) => AdsConfig.standard);

final purchasesConfigProvider =
    Provider<PurchasesConfig>((ref) => PurchasesConfig.standard);

final adFrequencyControllerProvider = Provider<AdFrequencyController>((ref) {
  return AdFrequencyController(ref.watch(adsConfigProvider));
});

final consentServiceProvider = Provider<ConsentService>((ref) {
  return PermissiveConsentService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return LoggingAnalyticsService();
});

final purchasesServiceProvider = Provider<PurchasesService>((ref) {
  return FeatureFlaggedPurchasesService(ref.watch(purchasesConfigProvider));
});

final adServiceProvider = Provider<AdService>((ref) {
  final config = ref.watch(adsConfigProvider);
  if (AdMobAdService.isMobilePlatform) {
    final service = AdMobAdService(config);
    ref.onDispose(service.dispose);
    return service;
  }
  return NoOpAdService();
});

final consentAllowsAdsProvider = Provider<bool>((ref) {
  return ref.watch(consentServiceProvider).canRequestAds;
});

final adsRemovedProvider = Provider<bool>((ref) {
  final purchases = ref.watch(purchasesServiceProvider);
  final game = ref.watch(gameControllerProvider);
  return purchases.removeAdsOwned || game.game.removeAdsEntitlement;
});
