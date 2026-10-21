/// IAP feature flags. Full StoreKit/Play Billing deferred when disabled.
class PurchasesConfig {
  const PurchasesConfig({
    this.removeAdsEnabled = false,
    this.removeAdsProductId = 'merge_empire_remove_ads',
  });

  /// When false, Remove Ads is interface-only (no purchase flow).
  final bool removeAdsEnabled;
  final String removeAdsProductId;

  static const PurchasesConfig standard = PurchasesConfig();
}
