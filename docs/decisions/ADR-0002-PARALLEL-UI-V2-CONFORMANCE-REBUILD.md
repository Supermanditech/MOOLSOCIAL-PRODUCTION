# ADR-0002 — parallel UI V2 conformance rebuild

Date: 20 July 2026  
Status: **Accepted by product owner**  
Decision scope: complete MoolSocial mobile presentation layer

## Context

The current Flutter application contains valuable, tested technical foundations
but its UI/UX is not accepted as a faithful implementation of the approved HTML
prototype. Patching the current shared presentation components in place risks
propagating further visual regressions. Starting a separate production
repository would discard or duplicate verified identity, business logic, API,
native-platform, CI and test work and create a larger integration risk.

## Decision

MoolSocial will keep the existing production repository and build a fresh,
parallel Flutter UI V2 presentation layer on:

`remediation/prototype-conformance-2026-07-20`

This is a clean presentation rebuild, not a second application:

- existing domain models, sessions/controllers, gateways, API adapters,
  Firebase/native configuration, package identity, business rules and CI are
  reused;
- current Flutter presentation code remains available as a read-only rollback
  reference while V2 is built;
- new V2 screens and design components are implemented separately from the
  current UI and call the same tested non-UI owners;
- production remains native Flutter for Android and iOS;
- approved HTML is a design and interaction specification, never a production
  WebView.

No new production repository will be created. The old UI will not be gradually
patched into a mixture of old and new shared components.

## Approved HTML lifecycle

Each screen is finalized before its Flutter V2 implementation:

1. start from the existing HTML screen;
2. correct its UI, wording, actions, sub-actions and all visible states;
3. review it at the canonical phone viewports and supported text scale;
4. obtain explicit founder approval;
5. save an immutable versioned HTML reference, its assets, reference images and
   a screen interaction contract inside this repository;
6. record a checksum in the approved-reference manifest;
7. create a new version rather than overwriting an accepted reference.

One "screen" includes every state needed to complete its intent: sheets,
dialogs, menus, loading, empty, invalid, cancelled, duplicate, retry, offline,
permission-denied, failure and completion where applicable.

## Flutter V2 lifecycle

For each approved screen or tightly connected journey slice:

1. add semantic, copy and tap-graph conformance tests against the approved
   contract;
2. implement the native Flutter V2 screen without copying old presentation
   decisions by default;
3. use the existing controller/session/API boundary;
4. capture HTML and Flutter at identical viewport, state and text scale;
5. run an automated visual comparison plus a human side-by-side review;
6. replay every tap, sub-tap and nested tap on the connected OPPO;
7. run the complete affected journey and failure matrix;
8. obtain founder `Accepted` or `Rejected` status;
9. preserve accepted work as an atomic branch commit;
10. run two full regressions before final candidate promotion.

Flutter-generated goldens cannot approve themselves. A baseline update requires
an immutable approved HTML/reference record and an issue-register entry.

## Code boundary

The implementation will introduce clearly isolated V2 presentation and
conformance-test owners. Final directory names may follow existing feature
boundaries, but they must preserve these rules:

- V2 UI imports non-UI domain/session/service contracts;
- old UI and V2 UI do not import one another;
- shared V2 design tokens/components are introduced only after all affected
  approved references are inventoried;
- routing can select V2 on the remediation candidate without changing
  authoritative business behavior;
- no V2 presentation code is merged partially into `main`.

## First proof-of-process

The first connected slice is:

`Install contract → first open → language/area → sign in → OTP → Universal`

Screen 00 may be a store/release contract rather than an in-app Flutter screen.
The in-app V2 proof begins at first open and ends only when Universal is visible
and every entry action has its approved owner.

The process is not scaled to the remaining screens until this slice proves:

- accepted HTML references are immutable and reproducible;
- Flutter matches at the agreed phone dimensions;
- the OPPO tap journey completes;
- existing non-UI contracts remain green;
- the founder accepts the result.

## Main and promotion policy

- `main` remains frozen for user-facing UI work at rollback baseline
  `ed2a44d`, tagged `baseline-ui-before-conformance-2026-07-20`.
- The V2 branch can contain accepted checkpoints but is never partially merged.
- Every launch-scope screen/state must be `Accepted` or `Explicitly deferred`.
- The complete candidate is built and replayed on Android and iOS from one
  commit.
- After founder acceptance and all release gates, `main` is fast-forwarded to
  the exact tested candidate commit.
- Old presentation code is removed only after the V2 candidate is accepted and
  rollback evidence is preserved.

## Rejected alternatives

### New production repository

Rejected because it duplicates stable non-UI work, package/native setup,
history, CI and contracts and creates a high-risk final integration.

### In-place correction of the current Flutter UI

Rejected as the primary method because shared old components can change many
screens before their approved references are inventoried.

### HTML inside a Flutter WebView

Rejected because it weakens native accessibility, navigation, performance,
platform integration, testing and long-term maintainability.

