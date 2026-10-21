# AdMob setup (Phase 3)

## Development

The app ships with **Google’s official test ad unit IDs** only (`AdsConfig` / `AdUnitIds.test`).

- Android app ID (test): `ca-app-pub-3940256099942544~3347511713`
- iOS app ID (test): `ca-app-pub-3940256099942544~1458002511`
- Banner / interstitial / rewarded: matching Google sample units in `lib/core/config/ads_config.dart`

Platform manifests:

- Android: `APPLICATION_ID` meta-data in `AndroidManifest.xml`
- iOS: `GADApplicationIdentifier` in `Info.plist`

## Production (owner-supplied)

1. Create AdMob apps + ad units.
2. Set `AdsConfig.environment = AdsEnvironment.production`.
3. Fill `AdUnitIds.productionUnconfigured` (or a future override) with **real** unit IDs.
4. If production IDs are empty, the app refuses to pretend it has them and keeps test units / no-op behavior.

**Do not invent production AdMob IDs.**

## Frequency defaults

| Format | Limits |
|--------|--------|
| Interstitial | min 180s, min 3 milestones, max 4/day; never during board drag |
| Rewarded | max 5/day, max 3/hour; optional only; claim-once via SDK callback |

## Failure behavior

Ads initialize and load asynchronously. Failures never block generate/merge/sell/save. Offline play is unaffected.
