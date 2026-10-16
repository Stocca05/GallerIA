# GallerIA release preparation

The repository builds an iPhone app for iOS 17+. A passing simulator suite is not a production release certification. Do not upload until the following external configuration and device checks are complete.

## Configure the public product

1. Publish a privacy policy and support page with a working contact method. Fill `PrivacyPolicyURL` and `SupportURL` in `Resources/ReleaseConfiguration.plist`. The app exposes configured links in Settings, Help and the Pro screen. Empty links are deliberately not replaced by invented addresses.
2. Create a **non-consumable** in App Store Connect with ID `com.stocca.GallerIA.pro.lifetime`. Choose the actual price, territories, localized description and review screenshot there. Finish required agreements, banking and tax setup in your Apple developer account.
3. Configure the signing team, bundle IDs, App Store record, copyright owner, age rating, export-compliance answers, support URL and privacy disclosures. The app currently targets iPhone and ships an Italian interface. Do not advertise complete English support.
4. Review the metadata and privacy-policy draft under `Docs/AppStore/`. Replace the draft owner/contact details before publishing it. Verify the final archived app's privacy report, including Apple frameworks and any future SDKs.

## Local verification

```sh
xcodegen generate
python3 Scripts/check_release.py
xcodebuild -project GallerIA.xcodeproj -scheme GallerIA \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test
```

Simulator tests use ad-hoc signing so StoreKit verification is exercised without a distribution certificate.

The release check intentionally fails while public URLs are missing. `--development` lets CI report these blockers while checking the remaining local assets. The checker validates configuration and packaging; it does not verify website content or approval eligibility.

Build an optimized simulator version and inspect its packaging:

```sh
xcodebuild -project GallerIA.xcodeproj -scheme GallerIA -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/GallerIARelease \
  CODE_SIGNING_ALLOWED=NO build
python3 Scripts/check_release.py --bundle /tmp/GallerIARelease/Build/Products/Release-iphonesimulator/GallerIA.app
```

## StoreKit testing

`Tests/Fixtures/GallerIA.storekit` is a **local test catalog**, included only in the test bundle. Its price is illustrative and does not configure App Store pricing. `GallerIA StoreKit` enables it when running from Xcode; use `GallerIA` with StoreKit Configuration set to None for real sandbox tests. Automated tests exercise verified local entitlement activation and refund revocation. No local setting grants Pro.

On a signed sandbox build, verify purchase, cancellation, Ask to Buy/pending approval, restore after reinstall, offline startup with existing entitlement, refund and revocation. Local StoreKit tests cannot replace App Store sandbox validation.

## Device acceptance checklist

- Limited/full/denied/revoked access; empty library; large library; iCloud-only and offline assets; interrupted and resumed scans.
- Protect a memory, relaunch, and verify it cannot be deleted through recommendations, screenshots, videos or similar-photo cleanup. Remove protection explicitly in Settings. Photos favorites remain protected independently.
- Compare similar photos at full preview size. Review suggested selections and confirm at least one available photo per known group survives. Similarity is a review aid, not proof of duplication.
- Cancel the app confirmation and the Photos confirmation separately. Neither must record deletion feedback. Confirm a test deletion, check the real Photos library and recover it from Recently Deleted; repeat with iCloud enabled.
- Confirm that duplicate/temporary-content decisions do not change aesthetic training, while explicit like/dislike choices do. Verify persisted preferences after relaunch and migration from an older build.
- Enable the privacy lock only on a device with a configured passcode. Check authentication cancellation, backgrounding during authentication, app-switcher snapshots and returning while an editor/preview sheet is open. Verify Face ID/Touch ID and passcode fallback.
- VoiceOver, larger text, Reduce Motion, small iPhones, low storage and a restored device backup. Check that saved-data failures are visible and corrupted protection data blocks deletion until an explicit reset.
- Verify privacy and support links on a separate device, real restore flows, and store screenshots matching this build. Then archive with distribution signing, validate in Organizer and distribute through TestFlight before submitting.

## References

- [Apple App Review preparation](https://developer.apple.com/app-store/review/)
- [Required-reason API declarations](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [StoreKit testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
- [Non-consumable In-App Purchase setup](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/)
