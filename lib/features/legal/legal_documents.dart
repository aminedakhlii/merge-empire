/// In-app legal placeholder copy.
///
/// These are **NOT** real Privacy Policy / Terms of Service documents.
/// The owner must replace [ProductionConfig] URLs and publish real policies
/// before store submission. Do not present these as binding legal terms.
abstract final class LegalPlaceholders {
  static const String privacyTitle = 'Privacy Policy (PLACEHOLDER)';
  static const String termsTitle = 'Terms of Service (PLACEHOLDER)';

  static const String privacyBody = '''
⚠️ PLACEHOLDER — NOT A REAL PRIVACY POLICY

This document is a development placeholder for Merge Empire.
It does not describe actual data practices and must not be used for App Store
or Google Play submission.

Before release, the owner must:
1. Draft and publish a real Privacy Policy.
2. Set ProductionConfig.privacyPolicyUrl to that HTTPS URL.
3. Ensure AdMob / UMP / ATT disclosures match the live policy.

Development note: Core gameplay works offline. Advertising SDKs (when enabled)
may process device advertising identifiers subject to platform consent flows.
Analytics is abstracted and not wired to a production backend in this MVP build.

Owner must supply the final policy. Do not invent a hosted legal URL.
''';

  static const String termsBody = '''
⚠️ PLACEHOLDER — NOT REAL TERMS OF SERVICE

This document is a development placeholder for Merge Empire.
It is not a binding agreement and must not be used for store submission.

Before release, the owner must:
1. Draft and publish real Terms of Service.
2. Set ProductionConfig.termsOfServiceUrl to that HTTPS URL.
3. Align IAP, refund, and content rules with Apple/Google policies.

The game is provided as-is for development testing. Virtual currency has no
real-world cash value. Optional ads and purchases (when enabled) follow
platform rules once owner configuration is complete.

Owner must supply the final Terms. Do not invent a hosted legal URL.
''';
}
