# Buy V2 R35.1 order-progress integrity handoff

Date: 31 July 2026

State: `COMPLETE_TEST_ONLY_ORDER_PROGRESS_HARDENING`

Ticket `BUY-FV2-115` protects order identity, history partition and truthful
live progress in the founder-approved native Buy session. It changes no
application runtime, UI, backend, approved HTML, protected media, Social
source or business rule.

## Protected order invariants

Every established order record must have:

- a unique non-empty ID;
- Shop, Wholesale or Medicine ownership, never the Orders pseudo-destination;
- non-empty title, item summary, partner, partner role, promise and delivery
  label;
- a positive total;
- progress greater than zero and at most one;
- progress exactly `1.0` when delivered;
- progress below `1.0` while active;
- any explicit product IDs resolving to products in the same vertical.

The Active and Delivered views are proven to be disjoint. Their union must
equal all order IDs, and their counts must match the session counters. Exact
case-insensitive ID search must return only the matching order in its owning
tab.

A mixed checkout adds one unrestricted product from each commerce vertical.
Confirmation must create exactly three traceable live orders with the
appropriate `MS-NEW-`, `PO-NEW-` and `RX-NEW-` prefixes, exact vertical
product IDs and totals, non-complete progress, non-delivered status and active
tab ownership.

Test-file SHA-256:

`1F23C3CD4342BA66718E6F1C9C217A21E234FB9926FC6CE950128CCB31701DB9`

## Verification

- Focused order-progress tests: `3/3` passed.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `129/129` passed; four opt-in captures skipped.
- Complete Buy regression 2: `129/129` passed; four opt-in captures skipped.
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

## Protected and device identity

- Starting HEAD:
  `a8f0d67a221b16a99debda481c383cf9e750f251`
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

`artifacts/quality/buy-r35-1-order-progress-hardening-20260731-36`

Evidence includes focused output, exact source fingerprints, full analysis,
two same-source regressions, all protected/security/reference/copy gates, HTML
lifecycle and read-only OPPO identity.

Push, deploy, publication and production release remain unauthorized.
