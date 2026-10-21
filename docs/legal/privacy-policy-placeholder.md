# Privacy Policy (PLACEHOLDER)

> **⚠️ NOT A REAL PRIVACY POLICY**  
> Do **not** submit this document to Apple or Google.  
> The owner must draft, host, and link a real Privacy Policy before release.

## Owner actions required

1. Publish a real Privacy Policy at an HTTPS URL.
2. Set `ProductionConfig.privacyPolicyUrl` (see `lib/core/config/production_config.dart`).
3. Align disclosures with AdMob / UMP / ATT / analytics choices.

## Development note

Merge Empire MVP core gameplay works offline. Advertising and analytics SDKs are optional and fail soft. Until production IDs and policies are configured, the app uses Google **test** ad units and does not invent production identifiers or legal URLs.
