# REG2789 — C34L browser-transition independent audit gaps

Date: 17 August 2026
State: registered independent FIX1 rejection; no external action

## Finding batch

Independent review rejected the green PRE-AAB-3-FIX1 transition/journal batch:

1. blocker and transition schemas are not composable. The blocker derives
   session ID from the nonce hash and validates source-manifest/ledger plus the
   sanitized browser route, while transition accepts an unrelated session ID,
   requires an extra `freshSessionProof` boolean outside the agreed 17 fields
   and omits the source/ledger and sanitized route semantics. The lifecycle
   positive fixture satisfies only the transition variant;
2. transition fixture confinement accepts the shared
   `tmp/c34l-release-transaction-fixtures-*` family rather than the exact
   canonical unique root containing the invoking fixture state, permitting a
   sibling fixture's aggregate/proof/evidence path;
3. when all journal JSON files are absent, reconciliation returns an empty
   chain without comparing nonempty detailed/aggregate lifecycle histories.
   The next transaction can restart sequence one and silently discard journal
   continuity; and
4. the fork-chain negative writes `preparedUtc` using a format incompatible
   with the exact `.fffZ` contract and treats any rejection as success, so the
   fixture can pass before fork detection.

All four direct lifecycle/journal runs had passed on PS7 and WinPS, but their
coverage did not prove these boundaries. No browser, state, seal, cycle, build,
Play, OPPO, private or external action occurred.

## Required correction

Use one exact browser prerequisite schema in blocker, readiness, transition and
fixtures: derived session ID, no self-asserted freshness boolean, canonical
source-manifest/ledger bindings and sanitized route semantics. Constrain every
fixture owner to the exact resolved state run root. Reject zero/missing journal
files whenever lifecycle histories are nonempty and enforce history/journal
cardinality/sequence parity. Make each chain negative reach and assert its exact
rejection class with valid timestamps. Requalify on both hosts before the phase
matrix resumes.
