# Days 1-5: universal entry tickets

## Completed locally

- `PLAT-001`: production monorepo and Flutter Android/iOS application scaffold.
- `PLAT-002`: Google-first ADR, portability boundary and 45-day delivery plan.
- `PLAT-003`: demo-only Firebase configuration that cannot reach live services.
- `DATA-001`: SQL Connect relational schema for account, preference, consent,
  installation and pending route.
- `DATA-002`: authenticated generated operations for current account bootstrap.
- `MOB-001`: boot, setup, mobile entry, OTP verification and Social routing.
- `MOB-002`: persistent five-destination navigation with Mool at the centre.
- `QA-001`: invalid setup/mobile/OTP, successful OTP/Mool route and change-method
  clean-state widget tests.
- `QA-002`: Flutter analysis and SQL Connect code-generation gates.

## Next implementation order

1. `CLOUD-001`: create separate `moolsocial-development`,
   `moolsocial-staging` and `moolsocial-production` Firebase/GCP projects;
   attach billing only to staging/production and set budget alerts.
2. `AUTH-001`: register `com.supermanditech.moolsocial`, configure SHA
   fingerprints and connect Firebase UI Auth to the Auth emulator.
3. `AUTH-002`: implement real phone OTP plus invalid, expired, resend,
   provider-cancel and account-linking behavior.
4. `DATA-003`: generate and import the Dart SQL Connect package; persist account,
   preferences, consent and return route with ownership filters.
5. `BOOT-001`: load Remote Config minimum version, maintenance and route flags;
   add offline/timeout/retry state.
6. `AREA-001`: connect explicit current-location permission and manual area
   search. Skip must never request permission.
7. `OBS-001`: add privacy-safe journey events, Crashlytics and Performance.
8. `DIST-001`: configure signing, App Distribution and internal Play track.
9. `QA-003`: emulator integration tests, Android Test Lab and connected-phone
   replay.
10. `RELEASE-001`: promote the passing commit to staging and obtain founder
    acceptance before starting consumer Buy.

## Required one-time owner actions

- Accept Android SDK licenses after reading them.
- Create or approve the three cloud projects and their billing accounts.
- Supply Play Console, Apple Developer and Razorpay organization access when
  their journey reaches staging.

These are legal/account ownership actions. They are not repeated development
work.
