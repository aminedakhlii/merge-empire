# Release checklist — Merge Empire MVP

## Engineering

- [ ] `flutter analyze` clean
- [ ] `flutter test` all green
- [ ] Manual smoke: generate → merge → sell → order → shop → restart resume
- [ ] Manual: rewarded optional path; interstitial never during drag
- [ ] Manual: airplane mode — core loop still works
- [ ] Save backup recovery verified after force-kill mid-session
- [ ] No production secrets in repo

## Configuration (owner)

- [ ] Final Android `applicationId`
- [ ] Final iOS bundle ID + signing team
- [ ] Production AdMob app + banner/interstitial/rewarded unit IDs
- [ ] Manifests updated from test → production AdMob app IDs
- [ ] `AdsEnvironment.production` only after IDs filled
- [ ] Privacy Policy URL live + linked in app / stores
- [ ] Terms of Service URL live + linked
- [ ] Support email / contact
- [ ] Remove Ads IAP product created (if shipping) + `removeAdsEnabled`
- [ ] Final icons, splash, screenshots (replace defaults)

## Store

- [ ] App Store Connect record + age rating questionnaire
- [ ] Google Play Console record + Data safety form
- [ ] Store listing copy reviewed
- [ ] Real device screenshots uploaded (not branding placeholders)
- [ ] Export compliance / encryption answers
- [ ] ATT / UMP flows verified on device where required

## Sign-off

- [ ] Owner accepts unfinished items listed in acceptance report
- [ ] Version bumped if needed (`pubspec.yaml`)
- [ ] Tag release commit

See `docs/owner-inputs.md` and `docs/build-and-run.md`.
