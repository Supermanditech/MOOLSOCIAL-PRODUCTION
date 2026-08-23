# UAW Personal MVP dock projection parity FIX2 preselection assessment

Date: 6 August 2026
Ticket/candidate: `UAW-PERSONAL-MVP-DOCK-PROJECTION-PARITY-FIX2`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user opening Mool from any live primary surface, including Buy,
sees exactly Social, Buy, Eat, Ride, Book and Work. Each choice reaches its
already-owned canonical native destination and standalone Pay is absent.

Checksum-matched OPPO qualification rejected FIX1 because Buy's local Mool
palette still independently hardcoded Social, Buy, Eat, Ride, Book, Pay and
Work. This is a confirmed launch-path regression against the founder-locked
MVP projection, so the successor correction is `mvp_required`.

## Reuse inventory and smallest complete scope

- Reuse `personalMoolRootActions` as the single tested projection owner.
- Reuse `_BuyDock`, the existing Buy V2 screen/session, and the existing
  `/app/social`, `/app/buy`, `/app/eat`, `/app/ride`, `/app/book` and
  `/app/work` routes.
- Replace only Buy's duplicated world list with a projection of the shared
  Personal action specs; keep Buy active by closing the local palette.
- Add deterministic tests that open the real Buy palette, assert the exact
  six-world contract/no Pay, and exercise its canonical router exits.
- Run affected Personal and complete Buy regressions twice, protected gates,
  analysis and two qualified broad regressions before any successor build.

## Duplicate search and necessity proof

No new screen, route, state owner, service or backend owner is needed. Source
search found the defect at the single hardcoded `Pay` entry in `_BuyDock`. The
shared `personalMoolRootActions` collection already expresses the correct IDs,
labels, routes and icons. Reusing it removes the drift point and is smaller and
safer than another Buy-specific configuration owner.

This is a narrow protected-Buy correction to shared launcher exposure. It does
not alter Buy catalogue, Cart, checkout, transaction-owned payment, order,
tracking, recovery, presentation baselines or accepted references. No golden
or accepted baseline will be updated.

## Explicit exclusions

- No standalone Pay surface and no removal of embedded transaction-owned
  payment methods from authorized checkout journeys.
- No Social provider activation, YouTube compliance claim or protected Social
  content redesign.
- No new UI, route, state, service, backend, workspace or provider owner.
- No screenbook, locked Screens 01-03, manifest, golden or accepted-baseline
  mutation.
- No OPPO uninstall, data clear, downgrade, signature workaround or deletion
  of FIX1/FIX7 evidence.
- No credentials, live provider message/call, funds, Production write, commit,
  push, deploy or promotion.

## Dependencies and verification

Dependencies: founder direction to fix the disclosed new-MVP defect; locked
Personal projection; existing canonical routes; immutable FIX1 rejection and
FIX7 rollback evidence; current remediation branch/HEAD and full dirty-state
preservation; MVP scope, delivery, APK and device gates.

Verification: source/config exactness; real Buy-palette exact labels and keys;
no Pay; one-tap canonical route ownership; retained Buy state and back behavior;
text-scale/reduced-motion/safe-area semantics already owned by the Buy shell;
two affected Personal runs; complete Buy suite twice; protected Social/Buy
gates; analysis and two qualified broad mobile regressions; only then one fresh
machine-authorized unique profile build; signature/badging/source/version/hash;
compatible in-place OPPO installation; checksum match and device replay of both
Social and Buy Mool entry points.

Estimated impact: **1 day**, inside the founder-locked 60-75-day window.
