# Required owner inputs (§30)

Do **not** invent these values. The app runs with development/test configuration until they are supplied.

| Item | Where to set | Status in MVP |
|------|----------------|---------------|
| Apple Developer Program access | App Store Connect / Xcode team | **Owner** |
| App Store Connect app record | ASC | **Owner** |
| Google Play Console account | Play Console | **Owner** |
| Final Android `applicationId` | `android/app/build.gradle.kts` + `ProductionConfig` | Empty / default Flutter id |
| Final iOS bundle ID | Xcode / `ProductionConfig` | Default Flutter id |
| AdMob app + unit IDs (production) | `ProductionConfig.adMob` / manifests | Test IDs only |
| Privacy Policy HTTPS URL | `ProductionConfig.privacyPolicyUrl` | Placeholder only |
| Terms of Service HTTPS URL | `ProductionConfig.termsOfServiceUrl` | Placeholder only |
| Support contact email | `ProductionConfig.supportEmail` | Empty |
| Final app display name | Store metadata + `ProductionConfig` | Working title “Merge Empire” |
| Final artwork / licensing | `assets/branding/` | Default generated — **replace** |
| Remove Ads IAP product + price | Store consoles + `PurchasesConfig` | Feature-flagged off |
| Firebase (optional analytics) | Project + `AnalyticsService` impl | Logging/no-op abstraction |

See also `docs/admob-setup.md` and `docs/release-checklist.md`.
