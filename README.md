# MoolSocial Production

## Product implementation contracts

- [Apple-inspired full-app design memory](docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md)
- [Universal intent-completion production backlog](docs/delivery/UNIVERSAL-INTENT-PRODUCTION-BACKLOG.md)

This is the production codebase. The HTML screenbook remains a requirements and
replay reference; production delivery happens here as end-to-end vertical
journeys.

## Locked stack

- Flutter 3.44.6 / Dart 3.12.2 for Android and iOS.
- Firebase Authentication, App Check, Remote Config, Cloud Messaging,
  Analytics, Crashlytics and Performance Monitoring.
- Firebase SQL Connect over Cloud SQL for PostgreSQL for relational product,
  order, workspace, money and audit data.
- Cloud Functions 2nd gen in `asia-south1` for privileged workflows, provider
  webhooks and asynchronous commands.
- Next.js and TypeScript for the public/business web and a separately deployed
  Superadmin surface.
- Firebase Local Emulator Suite, App Distribution and Test Lab for automated
  local, staging and real-device gates.

The PostgreSQL schema and domain contracts are the portability boundary.
Firebase SDK calls stay behind adapters.

## First production journey

`PROD-JRN-001`: install/open → setup language/area → authenticate → restore the
requested destination → open the universal Mool shell.

The initial Flutter shell is intentionally backed by a development session
adapter. It enables deterministic UI and clean-state regression testing before
live Firebase project identifiers are provisioned. Development OTP is `123456`
and is never a release authentication provider.

## Local commands

```powershell
cd "C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION"
.\scripts\check.ps1
```

Run the mobile app:

```powershell
cd "C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION\apps\mobile"
flutter run
```

Install the clean review build on an authorized USB-connected Android phone:

```powershell
cd "C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION"
.\scripts\run-phone-review.ps1
```

This script refuses to continue unless both local backend emulators are
listening. It reverses only ports 9099 and 9399, clears the demo Auth users and
app state unless `-KeepAppState` is supplied, installs the APK and opens
`com.moolsocial.app`.

Generate SQL Connect SDKs after the emulator is configured:

```powershell
firebase dataconnect:sdk:generate --project demo-moolsocial-local
```

No command in this repository targets production by default. Staging and
production deployment require explicit project aliases and protected GitHub
environments.

Cross-platform build, environment and store rules are defined in
`docs/delivery/CROSS-PLATFORM-DELIVERY.md`.
