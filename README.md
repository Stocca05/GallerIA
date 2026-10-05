# GallerIA

An iOS photo curator that learns your preferences locally, with a focused Italian interface and optional paid library cleanup tools. Requires iOS 17+.

## Run

Open `GallerIA.xcodeproj`, select **GallerIA**, and choose an iPhone simulator. To regenerate the project after changing targets or adding files, install XcodeGen and run `xcodegen generate`.

```sh
xcodebuild -project GallerIA.xcodeproj -scheme GallerIA \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  CODE_SIGNING_ALLOWED=NO test
```

The project includes unit tests for preference learning, persistence, undo, and invalid vectors, plus UI tests covering onboarding, denied/unrequested access, navigation, Pro and privacy. UI tests save screenshots as result attachments.

## Product behavior

- Rating a photo never deletes it. Preferences are trained in batches of ten; undo applies to the uncommitted batch.
- Photo access can be limited, full, denied, or empty. The app remains navigable in every state.
- Recommendations are personal affinities, not objective image-quality judgments.
- Cleanup checks up to 500 recent photos, 100 screenshots and 100 recent videos. Similarity is a suggestion, not proof of duplication. Videos are not ranked by file size.
- Deletion requires explicit selection, an app confirmation and the system Photos confirmation. Failures are surfaced.
- Image features and preferences are stored locally. iCloud-only Photos assets may be downloaded by Apple's photo library for analysis. There is no external AI backend.
- Pro uses verified StoreKit 2 transactions. Local flags cannot grant paid access. Pending transactions, cancellation, restoration and revoked entitlements are handled.
- The widget opens the app; it does not invent library statistics.

## Before App Store release

1. Configure a **non-consumable** product in App Store Connect with ID `com.stocca.GallerIA.pro.lifetime`, pricing and localized descriptions. Until available, the purchase button is disabled with an explanation. The former simulated monthly subscription has been removed.
2. Validate purchase, restore, pending approval and refund/revocation using StoreKit testing and an App Store sandbox account on a signed build. No real payment has been performed during development.
3. Configure your signing team, app record, support URL, public privacy-policy URL, App Privacy answers and screenshots. The in-app privacy explanation is not a substitute for the public store listing.
4. Test on physical devices with limited photo access, iCloud-only media, large libraries, offline mode, Dynamic Type and device authentication. Compare actual photo groups before enabling any broader scan limits.
5. The shipped interface is Italian. Existing English resource strings cover legacy views only; complete localization before advertising English support.

Legacy experimental files (Watch, games, simulated sensitive-content detection) are preserved from the original working tree but are not promoted in the primary product flows. The Watch target is not embedded in the iPhone app. A production content-safety classifier is not provided.

## Verified in this revision

On iPhone 18 Pro / iOS 27 Simulator: build and install succeeded; seven unit tests and two UI tests passed. The five UI captures include onboarding, library permission entry, selection without authorization, Pro unavailable-product state, and privacy. Selected captures are in `Docs/Screenshots`. Purchases and deletion of real media have not been exercised; verify these on a signed sandbox/device build before release.
