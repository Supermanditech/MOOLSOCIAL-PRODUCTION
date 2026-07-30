# Buy V2 R35.1 deterministic-session coverage handoff

Date: 31 July 2026

State: `COMPLETE_TEST_ONLY_SESSION_HARDENING`

Ticket `BUY-FV2-112` closes proven deterministic coverage gaps at the
founder-approved native Buy session seam. It changes no application runtime,
UI, backend, approved HTML, protected media, Social source or business rule.

## Protected behavior

Eight tests now protect:

- category-neutral Orders state without mutating a saved commerce category;
- exact Shop, Wholesale and Medicine cart quantities and totals;
- scope-specific cart clearing and safe catalogue ownership;
- empty cart/checkout normalization;
- direct account-child actions and repeat-tap Account return;
- fail-closed wholesale eligibility and prescription quantity limits;
- explicit Wholesale and Medicine reorder scopes;
- cart, checkout, confirmation, order-items and recovery navigation depth;
- confirmed-order product-ID projection;
- final cart removal and exact synthetic-address selection.

The address used by the new test is wholly synthetic. The protected runtime's
separate hard-coded review identity/contact/address fixture remains a recorded
release risk and was not copied into this handoff.

Test-file SHA-256:

`8719009AA07E4340315892B28B000F14FC04E33380BD271F9AE408B0A46B0FC5`

## Coverage result and limits

The same full Buy suite was instrumented before and after the test addition:

| Surface | Before | After | Change |
| --- | ---: | ---: | ---: |
| Seven protected V2 files | 3595/4290 (83.8%) | 3665/4290 (85.4%) | +70 lines |
| `buy_v2_session.dart` | 594/673 (88.3%) | 664/673 (98.7%) | +70 lines |

No production source line changed.

Nine session lines remain uncovered. They are:

- short-circuit operands whose alternate operand is already behaviorally
  covered;
- enum arms for an Orders product/cart destination that the catalogue cannot
  create;
- silent selected-order and selected-address fallback policies.

The fallback policies were deliberately excluded. A coverage number must not
turn silent substitution into an approved production contract. Camera/plugin
execution and visual presentation branches were also excluded because they
require device/runtime or founder-reviewed UI evidence, not session-only
tests.

## Verification

- Focused deterministic-session tests: `8/8` passed.
- Final instrumented Buy suite: `122/122` passed; four opt-in capture
  generators skipped.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `122/122` passed; four captures skipped.
- Complete Buy regression 2: `122/122` passed; four captures skipped.
- The source fingerprints before both regressions were identical.
- Protected Buy baseline: passed.
- Protected Social baseline: passed.
- Backend-contract boundary: passed.
- Data-egress boundary: passed.
- Approved Screens 01–03/reference locks: passed.
- Founder-FINAL Buy reference: passed.
- Brand integrity: passed.
- User-facing Flutter copy: passed.
- HTML customer copy: `9/9` states passed.
- Interaction contract: `154` routes passed.
- The temporary HTML server and headless browser exited; ports 8765 and 9223
  were verified free.

The first focused test attempt contained an invalid assumption that the Orders
screen owned `visibleProducts`. The runtime deliberately projects Shop
products internally while the Orders presentation renders `visibleOrders`.
That assertion was removed; the failed attempt is retained in additive
evidence rather than hidden.

## Protected and device identity

- Starting HEAD:
  `13b18470c594d5e2451a68ae0c1e7f5c35e9db9d`
- Protected Buy runtime files: `28`
- Protected Buy tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Protected Social files: `119`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- OPPO: `2b3e0f71`
- Installed version: `1.0.0-r35.1`
- Installed version code: `2026073045`
- On-device base APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`

Because runtime bytes did not change, no APK rebuild, reinstall or visual
device replay was warranted. The connected OPPO was used for read-only
installed-artifact identity verification.

## Evidence

`artifacts/quality/buy-r35-1-coverage-gap-audit-20260731-33`

Evidence includes the baseline and final LCOV files, coverage summaries,
focused attempts, full instrumented suite, full analysis, two same-source
regressions, all protected/security/reference/copy gates, HTML lifecycle and
read-only OPPO identity.

Push, deploy, publication and production release remain unauthorized.
