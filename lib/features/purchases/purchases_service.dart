import '../../core/config/purchases_config.dart';

/// Purchase / entitlement abstraction. Full IAP deferred when feature-flagged off.
abstract class PurchasesService {
  Future<void> initialize();

  bool get removeAdsOwned;

  /// Attempts Remove Ads purchase when [PurchasesConfig.removeAdsEnabled].
  Future<PurchaseResult> purchaseRemoveAds();

  Future<PurchaseResult> restorePurchases();
}

enum PurchaseResult {
  success,
  cancelled,
  unavailable,
  featureDisabled,
  failed,
}

class FeatureFlaggedPurchasesService implements PurchasesService {
  FeatureFlaggedPurchasesService(this.config, {bool removeAdsOwned = false})
      : _removeAdsOwned = removeAdsOwned;

  final PurchasesConfig config;
  bool _removeAdsOwned;

  @override
  bool get removeAdsOwned => _removeAdsOwned;

  /// Test/debug helper — never call from production UI without a real receipt.
  void debugGrantRemoveAds() {
    _removeAdsOwned = true;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<PurchaseResult> purchaseRemoveAds() async {
    if (!config.removeAdsEnabled) return PurchaseResult.featureDisabled;
    // StoreKit / Play Billing not wired in Phase 3.
    return PurchaseResult.unavailable;
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!config.removeAdsEnabled) return PurchaseResult.featureDisabled;
    return PurchaseResult.unavailable;
  }
}

class MockPurchasesService implements PurchasesService {
  MockPurchasesService({
    this.removeAdsOwned = false,
    this.enabled = false,
  });

  @override
  bool removeAdsOwned;
  bool enabled;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<PurchaseResult> purchaseRemoveAds() async {
    purchaseCalls++;
    if (!enabled) return PurchaseResult.featureDisabled;
    removeAdsOwned = true;
    return PurchaseResult.success;
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    restoreCalls++;
    if (!enabled) return PurchaseResult.featureDisabled;
    return PurchaseResult.success;
  }
}
