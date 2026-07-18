# One Android + iOS product

## Source of truth

- `apps/mobile/lib` contains the shared Flutter UI, navigation, validation,
  domain state and generated backend clients.
- Android package: `com.supermanditech.moolsocial`.
- iOS bundle: `com.supermanditech.moolsocial`.
- Android and iOS use the same environment-specific Firebase project, SQL
  Connect connector and Cloud SQL database.
- Data, identity and business rules never fork by mobile platform.

Platform directories contain only the native shell needed for permissions,
deep links, notifications, payment handoff, signing and store metadata.

## Environment mapping

| Environment | Android app | iOS app | Backend |
| --- | --- | --- | --- |
| Development | MoolSocial Android dev | MoolSocial iOS dev | `moolsocial-dev` |
| Staging | MoolSocial Android staging | MoolSocial iOS staging | `moolsocial-staging` |
| Production | MoolSocial Android production | MoolSocial iOS production | `moolsocial-production` |

Each row is isolated. Android and iOS inside one row share users and business
data. No client can select a different environment at runtime.

## Automated gates

Every accepted source change must:

1. Pass shared format, analysis and widget tests.
2. Build an Android APK on Linux.
3. Build an iOS simulator application on a hosted macOS runner.
4. Validate SQL Connect schema and generated Flutter clients.
5. Run clean-state journey tests before promotion.

Signed Android App Bundles and signed iOS archives are promotion artifacts.
Signing credentials remain in protected CI secrets and are never stored in
the repository.

## Owner-only setup

- Google Cloud/Firebase terms, billing and project ownership.
- Google Play Console ownership and release approvals.
- Apple Developer Program/App Store Connect ownership, agreements and release
  approvals.
- Android SDK and Apple licence acceptance.

Windows is sufficient for shared Flutter development and Android validation.
iOS compilation/signing runs on macOS CI; a local Mac is not required for
day-to-day shared feature development.
