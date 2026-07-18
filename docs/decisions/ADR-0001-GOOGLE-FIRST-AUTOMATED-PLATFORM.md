# ADR-0001: Google-first automated production platform

Status: accepted
Date: 2026-07-18
Decision owner: founder

## Decision

Use a Google-first application platform:

| Layer | Selection |
| --- | --- |
| Mobile | Flutter and Dart |
| Mobile UI foundation | Material 3 plus a MoolSocial-owned design system |
| Authentication | Firebase Authentication / Identity Platform |
| Relational backend | Firebase SQL Connect with Cloud SQL for PostgreSQL |
| Privileged workflows | Cloud Functions 2nd gen, TypeScript, Mumbai |
| Abuse protection | Firebase App Check with Play Integrity / App Attest |
| Push | Firebase Cloud Messaging |
| Release controls | Remote Config and feature flags |
| Quality telemetry | Crashlytics, Performance Monitoring and Analytics |
| Mobile delivery | App Distribution, Test Lab and Play Console tracks |
| Web and Superadmin | Next.js and TypeScript on separate App Hosting backends |
| Images and documents | Cloud Storage with lifecycle and quota policies |
| Social video | YouTube Connect at launch; no open-ended owned video CDN |
| Payments | Razorpay behind a provider-neutral payment adapter |

## Why this wins for MoolSocial

SQL Connect declares the relational model and allowed operations, then creates
the PostgreSQL schema, secure server endpoints and type-safe Flutter/web SDKs.
This removes most handwritten CRUD, DTO mapping and client networking code while
retaining PostgreSQL for transactional commerce and a future migration path.

Firebase adds maintained Flutter SDKs, pre-built authentication widgets,
emulators, attestation, push, feature flags, crash monitoring, staged app
distribution and device testing under one operating console. Cloud SQL, SQL
Connect, Cloud Run and Functions are available in Mumbai for low-latency Indian
transactions. Static web content remains globally cached; dynamic web may use
Singapore until App Hosting offers an India region.

## Options rejected now

### Supabase

Technically suitable, but rejected by founder preference and because the
Google-first toolchain gives MoolSocial one supported Flutter-to-staging path.
This is not a judgment that Supabase is unreliable.

### AWS Amplify Gen 2

Amplify has Flutter libraries and automated TypeScript infrastructure.
For MoolSocial, however, Amplify Data is centered on AppSync patterns and the
relational, transaction-heavy parts would require more Lambda/CDK and service
composition. It is a valid second choice, not the lowest-effort choice here.

### Firestore as the system of record

Rejected for product, stock, checkout, settlement, workspace permission and
audit ledgers. Those domains need relational constraints and multi-row
transactions. Firestore may later be used only for a bounded use case proven to
benefit from its realtime document model.

### FlutterFlow or generated visual-app ownership

Rejected as the production source of truth. It can accelerate disposable visual
exploration, but generated UI ownership and merges would reintroduce the
regression risk this decision is meant to remove.

## Lock-in controls

1. Business records live in standard PostgreSQL.
2. Domain rules do not import Firebase packages.
3. Authentication, messaging, storage, payment and media use adapter interfaces.
4. All irreversible commands carry an idempotency key and expected version.
5. Provider webhooks first enter an immutable inbox before changing a ledger.
6. Data export and restore are tested before launch and quarterly afterward.
7. No business rule exists only in a console setting.

## Honest boundary

No platform can promise zero regressions. This decision minimizes hand-written
plumbing and makes regression evidence a deployment gate. Stock reservation,
payments, payouts, fraud controls, campaign funding, identity policy and
workspace permissions still require explicit MoolSocial domain code and tests.
