import 'ads_config.dart';
import 'purchases_config.dart';

/// Owner-supplied production values.
///
/// **Do not invent** Apple/Google account details, legal URLs, AdMob production
/// IDs, bundle IDs, or IAP prices. Leave fields empty / placeholder until the
/// owner fills them. The app remains runnable via development/test config.
class ProductionConfig {
  const ProductionConfig({
    this.appDisplayName = 'Merge Empire',
    this.androidApplicationId = '', // e.g. com.yourstudio.mergeempire
    this.iosBundleId = '', // e.g. com.yourstudio.mergeempire
    this.supportEmail = '', // OWNER: support@example.com
    this.privacyPolicyUrl = '', // OWNER: https://...
    this.termsOfServiceUrl = '', // OWNER: https://...
    this.adMob = AdUnitIds.productionUnconfigured,
    this.adsEnvironment = AdsEnvironment.test,
    this.purchases = const PurchasesConfig(removeAdsEnabled: false),
    this.removeAdsPriceNote = '', // OWNER: e.g. USD 4.99 — set in store consoles
  });

  final String appDisplayName;
  final String androidApplicationId;
  final String iosBundleId;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final AdUnitIds adMob;
  final AdsEnvironment adsEnvironment;
  final PurchasesConfig purchases;
  final String removeAdsPriceNote;

  bool get hasPrivacyPolicyUrl => privacyPolicyUrl.trim().isNotEmpty;
  bool get hasTermsUrl => termsOfServiceUrl.trim().isNotEmpty;
  bool get hasSupportContact => supportEmail.trim().isNotEmpty;
  bool get hasProductionAdMobIds =>
      adMob.androidAppId.isNotEmpty &&
      adMob.iosAppId.isNotEmpty &&
      adMob.banner.isNotEmpty &&
      adMob.interstitial.isNotEmpty &&
      adMob.rewarded.isNotEmpty;

  List<String> get missingOwnerInputs {
    final missing = <String>[];
    if (androidApplicationId.isEmpty) missing.add('Android applicationId');
    if (iosBundleId.isEmpty) missing.add('iOS bundle ID');
    if (!hasPrivacyPolicyUrl) missing.add('Privacy Policy URL');
    if (!hasTermsUrl) missing.add('Terms of Service URL');
    if (!hasSupportContact) missing.add('Support contact email');
    if (!hasProductionAdMobIds) missing.add('Production AdMob app + unit IDs');
    if (removeAdsPriceNote.isEmpty) {
      missing.add('Remove Ads IAP pricing (store consoles)');
    }
    return missing;
  }

  /// Default: development-safe empty production slots.
  static const ProductionConfig unconfigured = ProductionConfig();
}
