# QA-024 — approved-prototype UI/UX conformance remediation

Date opened: 20 July 2026  
Status: **OPEN — launch-blocking**  
Owner report: physical-phone UI/UX materially differs from the approved HTML
prototype across screens, action words, sub-actions, taps and nested taps.

## Umbrella defect

### UI-CONFORMANCE-001

The current Flutter application is internally testable but is not yet accepted
as a faithful implementation of the approved HTML prototype.

The scope is the complete user-facing application:

- 167 HTML prototype screens and their overlays, sheets and visible states;
- 156 Flutter screens represented by 151 registered routes;
- all main actions, sub-actions, contextual actions and nested intent paths;
- user-role-specific, professional production language;
- navigation, completion feedback, empty/error/retry/offline/denied states;
- compact-phone, large-text, Android and iOS presentation.

This record deliberately does not guess the individual defects. The product
owner will provide observations screen by screen. Each observation is recorded
in the issue register below with the exact approved reference and failed mobile
tap sequence before implementation starts.

## Source-of-truth order

For each reported screen, conformance is judged in this order:

1. the product owner's current screenwise instruction;
2. the explicitly identified approved HTML file/state;
3. approved wording, visual and interaction decisions in this repository;
4. current Flutter behavior only as evidence of the defect, never as the
   approval source.

When two approved references conflict, implementation pauses for that screen
until the product owner selects one. An automated golden generated from the
Flutter app cannot resolve a product-design conflict.

## Isolation decision

Remediation is performed on:

`remediation/prototype-conformance-2026-07-20`

`main` remains the last green technical baseline. We edit the existing
production source files on the remediation branch; we do not duplicate the app
or maintain a second set of screen files. Atomic commits preserve rollback.
Nothing merges to `main` merely because tests pass.

The branch initially contains every UI/UX defect inherited from `main`. A
branch does not remove an inherited defect; only an accepted correction does.
Therefore the branch must never be described as prototype-conformant while any
screen remains unreviewed, open or rejected.

## Candidate promotion policy

- The rollback baseline is `ed2a44d`, recorded by the tag
  `baseline-ui-before-conformance-2026-07-20`.
- User-facing UI changes on `main` are frozen while this blocker is open.
- Every prototype screen/state must be classified as `Unreviewed`, `Open`,
  `Fixed — awaiting founder`, `Accepted` or `Explicitly deferred`.
- Founder acceptance of one screen preserves that checkpoint on the branch but
  does not trigger a partial merge.
- The complete branch is reviewed as one release candidate on the physical
  phone.
- Only after all launch-scope rows are `Accepted` or `Explicitly deferred` may
  `main` be fast-forwarded to the exact tested candidate commit.
- If `main` moves for an unavoidable non-UI change, that change is integrated
  into the candidate first and the affected plus two full regressions are
  repeated. Conflict resolution must not choose the old `main` UI wholesale.

At final promotion, `main` becomes the candidate tree. Git does not add the old
UI a second time. Remaining defects would appear only if they were never fixed,
if `main` changed in parallel, or if a conflict was resolved incorrectly; the
rules above prevent those three paths.

## Screenwise issue register

| ID | Prototype screen/state | Mobile route/state | Reported difference | Failed tap sequence | Status |
| --- | --- | --- | --- | --- | --- |
| UI-CONFORMANCE-001 | Complete approved prototype | Complete current app | App-wide visual, wording and tap-depth divergence | Founder physical review | Open |

New rows use `UI-CONFORMANCE-002`, `003`, and so on. One row may contain several
closely related states only when they share the same root component and
acceptance replay.

## Regression-safe correction protocol

Every screenwise correction follows this sequence:

1. **Freeze evidence** — capture the approved HTML state and current OPPO state
   at the same viewport and text scale.
2. **Inventory interactions** — list every visible tap, revealed sub-tap,
   nested tap, alternate branch and expected end intent.
3. **Write the difference contract** — record layout, component, copy,
   navigation and state changes; distinguish global token defects from
   screen-specific defects.
4. **Add failing conformance tests** — semantic/action tests plus a separately
   labelled approved-reference visual, not an auto-approved current golden.
5. **Correct the smallest owner** — design token/component first only when the
   evidence proves it is shared; otherwise change the screen owner.
6. **Replay the exact failed sequence** — on the connected OPPO from the
   required clean state.
7. **Run affected journeys** — including back/close/cancel, invalid, empty,
   duplicate, loading, retry, offline, permission-denied and provider-failure
   states where applicable.
8. **Run the full application twice** — no golden update is accepted unless the
   visual change is tied to an approved-reference record.
9. **Founder checkpoint** — provide the corrected phone screen for approval and
   record the screen as accepted or rejected.
10. **Preserve the checkpoint on the branch** — no partial UI batch merges to
    `main`; the branch remains isolated while any launch-scope screen is
    unreviewed, open or rejected.

## Change ordering

To prevent another global regression:

1. record all founder observations without immediately changing shared UI;
2. group them by true owner: design tokens, navigation shell, shared component
   or screen-specific composition;
3. correct Universal/navigation foundations first if their approved evidence
   affects every journey;
4. proceed one vertical journey at a time;
5. regenerate only explicitly affected baselines;
6. keep backend, route and authoritative state contracts unchanged unless the
   approved intent path requires a documented contract change.

## Acceptance

This blocker closes only when:

- every founder-reported row is fixed or explicitly deferred by the founder;
- every visible/reachable control in the accepted scope has an owned result;
- approved-reference comparisons pass at supported phone sizes and text scale;
- exact OPPO failure replays and affected journeys pass;
- two full regressions pass without unexplained baseline changes;
- Android and iOS builds pass from the same commit;
- the founder explicitly accepts the complete reviewed candidate;
- `main` has no parallel UI commit after the recorded rollback baseline.

Until then, the correct recommendation is:

- technical review build: available;
- approved-prototype conformance: **NO-GO**;
- production launch: **NO-GO**.
