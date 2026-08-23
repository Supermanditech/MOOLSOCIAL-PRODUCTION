# UAW-C34P FIX8 global-social-login robustness and reuse assessment

Date: 22 August 2026

State: selected-ticket assessment candidate

## Customer outcome and classification

Ticket: `UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR`

Classification: `mvp_required`.

The ticket fixes confirmed authentication, App Check, method-truth and
post-login defects in the founder-selected global-login path. It adds no
product depth and is required before one OPPO candidate can truthfully test
provider login, return, retained session and relaunch.

## Reuse inventory

The repair reuses all existing production owners:

- locked Screen03 and the current `JourneySession` lifecycle;
- `FirebaseSocialAuthGateway` and its Google, X, Instagram and Facebook
  adapters;
- limited-use App Check token acquisition and backend replay consumption;
- `PublicAuthRuntimeConfiguration` provider qualification;
- the existing release bootstrap frame and bounded stage receipts;
- foreground `didPushRouteInformation` and cold-start route parsing;
- Firebase Auth session, sign-out and rollback seams;
- current approved-UI, FIX1A, FIX5, FIX6 and APK plugin-integrity gates.

No new screen, route, provider adapter, backend function, provider permission,
SQL Connect owner or business-domain persistence owner is necessary.

## New necessary work

One thin runtime-policy flag and one shared Firebase-authenticated-session
bootstrap adapter are necessary because no current composition simultaneously
uses live providers, App Check, truthful availability and a non-SQL retained
session in the Dev sideload lane. One focused test owner is necessary to bind
that composition end to end; existing tests inject leaf fakes and do not mount
the production `main.dart` decision boundary.

## Duplicate search result

The repository contains only two account-bootstrap implementations:
`ReviewAccountBootstrapGateway` and `DataConnectAccountBootstrapGateway`.
Neither verifies a real Firebase-authenticated session without creating or
requiring provisional business data. No existing live global-auth audit mode
or equivalent main-composition test exists.

## Implementation disposition

- `reuse`
- `thin_policy_adapter`
- `new_necessary_work`
- `test_only_acceptance`

## Explicit exclusions

SQL Connect, unfinished main/sub-action data models, new UI/routes, Apple,
unattested Mobile OTP, new provider permissions, backend product expansion,
APK/AAB build, OPPO mutation, private login, real messages, Play and Production
remain outside the source-repair ticket.

## Robustness and timeline

The repair removes a release false pass without duplicating architecture. It
is bounded to shared authentication and startup owners, preserves the complete
database-mapping hold, and fits the robust-MVP window. Estimated source and
host-qualification impact: one to two days before separate candidate/device
authorization.
