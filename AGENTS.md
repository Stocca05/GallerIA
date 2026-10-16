# Repository Guidelines

## Project Structure & Module Organization
GallerIA is an iOS 17+ photo curator built with SwiftUI and local preference learning. `Sources/GallerIAApp.swift` is the entry point. Organize code under `Sources/Views`, `Sources/ViewModels`, `Sources/Models`, and `Sources/Managers`; keep view presentation separate from photo access, persistence, editing, and StoreKit services. Assets live in `Sources/Assets.xcassets`, localized strings in `Resources/{it,en}.lproj`, and reference screenshots in `Docs/Screenshots`. `Tests/` contains unit tests and `UITests/` contains UI tests. `Widget/` supplies the widget extension; the legacy `Watch/` target is not embedded in the iPhone app.

## Build, Test, and Development Commands
- `open GallerIA.xcodeproj`: open Xcode, select the **GallerIA** scheme, and run on an iPhone simulator.
- `xcodegen generate`: regenerate the checked-in Xcode project from `project.yml` after adding files or changing targets. Install XcodeGen first.
- Build for an installed simulator:
  ```sh
  xcodebuild -project GallerIA.xcodeproj -scheme GallerIA \
    -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
    CODE_SIGNING_ALLOWED=NO build
  ```
  For tests, replace `build` with `test` and use `CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-`; substitute an available simulator name when necessary.

## Coding Style & Naming Conventions
Use Swift 5 language mode, four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` properties and functions. Name files after their primary type, following examples such as `GalleryView.swift` and `CleanupManager.swift`. Match nearby SwiftUI and concurrency patterns. No formatter or linter configuration is checked in. Keep user-facing copy Italian; English localization currently covers legacy views only.

## Testing Guidelines
Use XCTest, with `<Feature>Tests.swift` files and descriptive `test...` methods. Cover changed selection rules, preference learning, persistence, and invalid-input handling. Use UI tests for onboarding, permission states, navigation, and editor interactions; retain screenshot attachments. No numeric coverage threshold is configured. Validate real-library saving/deletion and StoreKit purchase flows separately on signed device or sandbox builds.

## Commit & Pull Request Guidelines
Recent commits use imperative descriptions such as “Improve library cleanup…”; older commits include `Phase N:` prefixes. Prefer concise, action-oriented subjects. In PRs, explain behavior changes, link relevant issues, report validation and device limitations, and include screenshots for UI changes.

## Release Preparation
Run `python3 Scripts/check_release.py` before distribution; configure public URLs in `Resources/ReleaseConfiguration.plist`. Follow `Docs/RELEASE.md` for device and sandbox acceptance checks.

## Privacy & Product Safeguards
Keep photo features and preferences local. Preserve explicit deletion selection, app/system confirmations, and group-preservation checks. Grant Pro access only through verified StoreKit transactions. Keep synthetic editor fixtures restricted to Debug builds.
