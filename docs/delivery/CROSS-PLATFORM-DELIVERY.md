# One Android + iOS product

## Source of truth

- `apps/mobile/lib` contains the shared Flutter UI, navigation, validation,
  domain state and generated backend clients.
- Android package: `com.moolsocial.app`.
- iOS bundle: `com.moolsocial.app`.
- These production identifiers are fixed before the first store registration
  and must not be renamed after an app is created in Play Console or App Store
  Connect. See `docs/delivery/APP-IDENTITY.md`.
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

## Compile-time environment boundary

`apps/mobile/lib/main.dart` selects the environment at compile time:

- debug defaults to `MOOLSOCIAL_USE_EMULATORS=true`;
- staging and release set `MOOLSOCIAL_USE_EMULATORS=false`;
- a non-emulator build must receive
  `MOOLSOCIAL_FIREBASE_API_KEY`, `MOOLSOCIAL_FIREBASE_APP_ID`,
  `MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID` and
  `MOOLSOCIAL_FIREBASE_PROJECT_ID`;
- missing live values stop application startup instead of silently connecting
  to the demo project;
- Auth and Data Connect emulator routing is enabled only inside the emulator
  branch;
- the optional `MOOLSOCIAL_DEVICE_REVIEW` build flag is accepted only with
  emulators enabled. It works around physical-device-to-laptop networking by
  using Auth emulator REST and a non-authoritative account bootstrap; it is
  never a staging or production identity path;
- the Android and iOS pipelines supply their own Firebase app ID while sharing
  the same environment project and authoritative data.

The environment is immutable inside a built artifact. Firebase identifiers are
held in protected CI environment values; provider secrets, signing keys and
payment credentials remain server-side.

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
