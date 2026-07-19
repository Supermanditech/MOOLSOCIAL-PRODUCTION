# QA-023 — full-app production-readiness audit

Audit date: 20 July 2026  
Founder review milestone: six hours from the start of this audit cycle  
Source of truth: approved HTML references `000`–`166` plus the production
Flutter and Superadmin implementations

## Decision boundary

This audit answers two different questions separately:

1. **Is the implemented interface ready for founder screen-by-screen review?**
2. **Is MoolSocial ready to accept real users and money in production?**

A rendered or tappable screen is not evidence that a live API exists. The
screen register therefore records UI, wording, interaction evidence, visual
evidence, regression state and live-backend state independently.

## Audited inventory

| Screen group | Screens | Production client | Interaction evidence |
| --- | ---: | --- | --- |
| Install, setup, sign-in, Universal | 5 | Flutter | Journey, session and Universal tests |
| Social | 4 | Flutter | Universal nested-intent tests |
| Buy | 14 | Flutter | Home-delivery vertical-slice tests |
| Chat | 3 | Flutter | Chat flow tests |
| Eat | 4 | Flutter | Eat vertical-slice tests |
| Ride | 6 | Flutter | Ride vertical-slice tests |
| Book / Get It Done | 21 | Flutter | Book vertical-slice tests |
| Pay | 10 | Flutter | Pay vertical-slice tests |
| Work and onboarding | 7 | Flutter | Work vertical-slice tests |
| Retailer orders and delivery | 4 | Flutter | Retailer order tests |
| Retailer POS | 3 | Flutter | Retailer POS tests |
| Retailer wholesale | 9 | Flutter | Wholesale tests |
| Retailer books | 3 | Flutter | Books tests and goldens |
| Retailer business services | 4 | Flutter | Business-service tests and goldens |
| Retailer customers and campaigns | 4 | Flutter | Campaign tests and goldens |
| Retailer controls | 6 | Flutter | Control tests and goldens |
| Manufacturer | 9 | Flutter | Manufacturer tests and goldens |
| Captain | 8 | Flutter | Captain tests and goldens |
| Creator and YouTube Connect | 10 | Flutter | Creator tests and goldens |
| Earn | 6 | Flutter | Operations tests and goldens |
| Service provider | 8 | Flutter | Operations tests and goldens |
| Superadmin | 12 | Next.js | Contract, desktop/mobile intent and visual tests |
| Shared capabilities | 7 | Flutter | Shared nested-intent tests and goldens |
| **Total** | **167** | **155 Flutter + 12 Next.js** | **149 registered Flutter routes** |

The complete screen-by-screen record is
[`SCREEN-BY-SCREEN-READINESS.csv`](SCREEN-BY-SCREEN-READINESS.csv). It is
generated from the approved reference directory, refuses missing or duplicate
sequence numbers and contains one row for every screen.

The paired
[`APPROVED-TAP-INVENTORY.csv`](APPROVED-TAP-INVENTORY.csv) extracts the
interaction contract carried by those references: 2,991 unique controls,
including 2,508 initially rendered controls, 483 script-revealed controls, 885
navigation links, 79 inputs and 704 controls classified as nested or
sheet/dialog actions. These counts describe the approved reference
interaction surface; production evidence and live-API status remain separate
columns so a prototype control cannot create a false production pass.

## Findings and completed fixes

### QA23-001 — selected Work profile advertised a dead tap

- Discovery: the selected Products & Trade profile card was wrapped in an
  `InkWell` whose callback was an empty closure.
- Original replay: Work → choose Products & Trade → choose Grocery/Kirana →
  press the already-selected profile card.
- Before: the card showed tap feedback but performed no action.
- Root cause: the reusable card required a non-null callback even when its
  state was informational.
- Fix: the callback is nullable; selected cards expose no tap action while
  unselected cards remain actionable.
- Exact replay after the fix: the selected card is announced as selected and
  does not advertise a tap; Continue remains available and advances the setup.
- Permanent evidence:
  `work_vertical_slice_test.dart` verifies the selected descendant `InkWell`
  has a null callback.

### QA23-002 — retailer delivery exposed a fixed verification code

- Discovery: a delivery card told the retailer to use a hard-coded four-digit
  code in the reviewed journey.
- Original replay: Retailer workspace → order → delivery verification.
- Risk: production-looking UI taught an insecure code and could create a false
  end-intent pass.
- Fix: the screen now instructs the retailer to obtain the live four-digit
  code from the assigned captain's app. No OTP or verification value is shown
  or logged by the UI.
- Exact replay after the fix: the verification step requests a live counterpart
  code and retains a retry path for invalid input.

### QA23-003 — permission recovery actions used testing language

- Discovery: camera and microphone denial branches offered actions labelled
  “Test without …”.
- Original replay: Retailer POS → scan or voice entry → deny permission.
- Risk: internal QA language reached a customer-facing recovery decision.
- Fix: the actions are now “Continue without camera” and “Continue without
  microphone”; the surrounding explanation states what the user can complete.
- Exact replay after the fix: denial preserves the task and provides a
  production-safe manual route.

### QA23-004 — internal, example and implementation wording leaked into UI

- Discovery: role surfaces contained phrases such as example, test, schema,
  submit outcome, test audience, trace, handoff and internal explanatory copy.
- Root cause: early journey fixtures and admin governance labels were reused as
  visible product copy.
- Fix: copy was rewritten by user role and intent. Actions now describe the
  outcome: choose, add, pay, submit work proof, review request, continue,
  decline, recover value and finish.
- Coverage: Flutter Dart plus Superadmin TypeScript/JavaScript are now scanned
  by `scripts/check-user-facing-copy.ps1`.
- Result: the user-facing copy gate reports no blocked production phrases.

### QA23-005 — static no-op controls and unresolved route targets lacked a gate

- Discovery: route tests covered journeys, but the repository had no static
  guard against a new empty callback or literal route that did not exist.
- Fix: `scripts/check-interaction-contracts.ps1` now rejects empty Flutter and
  Superadmin callbacks, `href="#"`, permanently disabled controls and any
  literal `/app…` target absent from the registered route set.
- Result: 149 unique registered routes; all 835 literal application targets
  resolve; no static no-op control remains.

### QA23-006 — release builds could silently use demo Firebase services

- Discovery: `main.dart` always initialized the demo project, Auth emulator and
  Data Connect emulator.
- Risk: a release artifact could ship connected to local/demo infrastructure.
- Fix: emulator use is a compile-time debug boundary. Staging/release must
  provide their Firebase app and project identifiers and fail closed when any
  are missing. Emulator verification-code retrieval is impossible outside the
  emulator branch.
- Evidence: analyzer is clean and platform configuration tests assert the
  release boundary and optional emulator adapters.

### QA23-007 — OPPO clean uninstall returned failure after removing the app

- Original replay: build review APK → clear emulator users → uninstall the
  existing package → install clean.
- Before: OPPO returned `DELETE_FAILED_INTERNAL_ERROR`, the script stopped, but
  a package-state query proved `com.moolsocial.app` was already absent.
- Root cause: the device's uninstall response and verified end state disagreed.
- Fix: the installer now treats package absence as authoritative. It still
  fails if any package path remains and records a warning when Android reports
  a contradictory result.
- Exact replay: package absence verified → new APK installed → MainActivity
  opened successfully.

### QA23-008 — physical-device Firebase emulator verification could not finish

- Original replay: clean install → skip area → mobile OTP → emulator code →
  Verify.
- Before: request or verification timed out inside the OPPO native Firebase
  networking layer despite an authorized USB reverse.
- Fix: an explicit compile-time `MOOLSOCIAL_DEVICE_REVIEW` mode requests and
  verifies the code against the local Auth emulator over the authorized USB
  path, then uses a non-authoritative review account bootstrap.
- Safety boundary: the application rejects device review mode unless local
  emulators are enabled. Standard emulator integration and every staging or
  release build continue to use Firebase Auth plus Data Connect.
- Exact replay: clean install → a new six-digit emulator code issued for the
  masked review number → Verify → Universal Social opened. The value is not
  retained in repository evidence.

### QA23-009 — Social action rail covered copy and the Create tab on OPPO

- Discovery: the first successful physical Universal screenshot showed the
  floating rail overlapping YouTube Connect copy and part of the Create tab.
- Root cause: the rail was positioned above a full-width scrolling surface
  without a content gutter.
- Fix: Social reserves a 72-logical-pixel action gutter and expands the video
  card for compact/large-text wrapping.
- Permanent evidence: the compact 360×800, 140% text-scale test asserts both
  the connected-video copy and Create tab end before the action rail begins.
  Updated 360×800 and 412×915 visual baselines record the corrected layout.

### QA23-010 — Android retained prior review state after reinstall

- Discovery: a nominal clean-install replay opened a previously completed
  retailer setup instead of the first setup screen.
- Risk: Android package-state behaviour could let a prior session create a
  false clean-state pass.
- Root cause: uninstall/reinstall was not a sufficient clean-state guarantee
  on the reviewed OPPO build, and the device denies `pm clear` to the ADB shell
  user.
- Fix: the review installer now deletes only the debuggable package's private
  state through `run-as`, verifies no state-bearing directory remains and then
  starts the app. This path cannot be used against a release artifact.
- Exact replay: reinstall → verified private-state cleanup → first setup screen
  → Skip now → Mobile OTP → new verification code → Verify → Universal Social.

## Visual review method

The visual-board generator composes current golden evidence without altering
source screenshots:

```powershell
node scripts/create-visual-audit-board.mjs
```

Boards cover Universal, Creator, Earn, Provider, Shared, Retailer,
Manufacturer, Captain and Superadmin at phone and desktop widths. The audit
looked for clipped primary actions, inaccessible nested controls, inconsistent
navigation, internal labels, unsafe fixed values and screen-height failures.
No new clipping or unreachable primary action was found in the accepted
evidence.

## Exact failure replay summary

| Failed sequence | Fix replay | Affected-journey rerun |
| --- | --- | --- |
| Work selected profile produced feedback but no outcome | Selected state is informative, exposes no tap, Continue advances | Work suite passed |
| Retailer delivery disclosed a fixed code | Live counterpart code is requested; invalid/retry path retained | Retailer order suite passed |
| POS permission denial offered a test action | Manual production recovery remains available | Retailer POS suite passed |
| Release always selected local Firebase | Debug uses emulator; non-emulator builds require live values | Platform, session and Journey 01 suites passed |
| Admin test/schema labels reached operators | Governed, validation and pilot terminology is shown | Admin contract and browser suites passed |
| OPPO reported uninstall failure after removing the package | Package absence is verified before the clean install continues | Clean-install script replay passed |
| Native Auth emulator verification timed out on OPPO | Compile-time device-review mode uses the authorized local-emulator path and is rejected outside emulator builds | Clean OTP-to-Universal replay passed |
| Social action rail covered connected-video copy and Create | A reserved content gutter keeps copy and tabs clear of the rail at compact width and 140% text | Targeted Social journey and updated golden suite passed |
| Reinstall reopened a prior completed journey | Debug package-private data is removed and verified before launch | Exact clean setup-to-Universal replay passed |

## Current verification

| Gate | Result |
| --- | --- |
| Flutter analyzer | Passed, zero issues |
| Targeted changed-journey regression | Passed, 91 tests |
| Work exact-failure suite | Passed, 12 tests |
| Platform/session/Journey 01 boundary regression | Passed, 22 tests |
| User-facing production-copy gate | Passed |
| Interaction and route-contract gate | Passed |
| Superadmin typecheck, lint and production build | Passed |
| Superadmin contracts | Passed, 6 tests |
| Superadmin browser intent and responsive visual cycles | Passed, 62/62 twice |
| Full Flutter pre-device baseline | Passed, 312/312 twice |
| Final post-device full-regression cycle 1 | Passed, 312/312 |
| Final post-device full-regression cycle 2 | Passed, 312/312 |
| Corrected debug APK build | Passed |
| Clean OPPO install and OTP-to-Universal replay | Passed after exact failure fixes; latest build remains open at Universal |

## Cascading production backlog

The audit produced 46 ordered production tickets in
[`PRODUCTION-CASCADE-2026-07-20.md`](../delivery/PRODUCTION-CASCADE-2026-07-20.md).
They deliberately keep one journey vertical:

`contract → UI → generated client/API → authoritative data → cloud deploy →
clean-state runtime test → exact failure replay → affected regression →
staging`

The first live path is:

1. isolated dev/staging/production environments and CI;
2. real phone authentication and idempotent account bootstrap;
3. screens 000–004 on staging Android and iOS;
4. authoritative Buy, inventory, payment and ledger;
5. consumer → retailer → delivery order completion.

## Real-device and external blockers

- Google must resolve the `hello@moolsocial.com` Cloud billing/project issue
  before live Firebase dev, staging and production projects can be provisioned.
- Real Firebase app identifiers, App Check, phone-auth limits and Data Connect
  deployment are therefore not yet available.
- Payment, Maps, YouTube OAuth, media/CDN and notification provider credentials
  require owner/provider activation.
- Android signing/store approval and Apple Developer/App Store Connect
  agreements remain owner-controlled actions.
- iOS compilation and signing require hosted macOS.
- The current Android build succeeds but emits a future Flutter compatibility
  warning for seven plugins that still apply the Kotlin Gradle Plugin. This is
  ticketed as `PROD-FDN-005`; it is not a current build failure.
- A real staging black-box cycle cannot honestly pass until the corresponding
  live APIs and external providers exist.

## Recommendation

**Founder UI and interaction review: GO.** Both independent final Flutter and
Superadmin cycles passed, and the exact clean-state physical-device replay
reached the corrected Universal screen.

**Real-user production launch: NO-GO.** The interface and local deterministic
journeys are reviewable, but live identity, authoritative business APIs,
payments, external integrations, staging deployment and store release gates
remain open. No screen should be represented as production-live solely because
its review gateway and UI tests pass.
