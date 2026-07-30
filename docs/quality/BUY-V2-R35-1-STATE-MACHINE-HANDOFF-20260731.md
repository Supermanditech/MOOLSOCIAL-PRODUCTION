# Buy V2 R35.1 deterministic state-machine handoff

Date: 31 July 2026

State: `COMPLETE_TEST_ONLY_STATE_MACHINE_HARDENING`

Ticket `BUY-FV2-113` protects the founder-approved native Buy session against
state corruption caused by mixed, realistic action ordering. It changes no
application runtime, UI, backend, approved HTML, protected media, Social
source or business rule.

## Deterministic workload

The new test executes 2,400 fixed steps covering:

- all 12 defined action families;
- Shop, Wholesale and Medicine;
- aggregate, Shop, Wholesale and Medicine cart scopes;
- add, increase, decrease and remove;
- destination and cart-scope changes;
- catalogue, cart, account and recovery navigation;
- checkout projection and scoped confirmation;
- all 172 current unrestricted offer records.

The sequence uses an explicit round-robin action schedule and a fixed
in-process number generator only for product, destination and scope selection.
It has no network, plugin, device, wall-clock, production identity or
personal-data dependency.

## Invariants after every action

After each of the 2,400 actions, the test independently reconstructs active
state from `quantityFor` and the immutable catalogue, then proves:

- global item count is the exact sum of line quantities;
- global value is the exact sum of price multiplied by quantity;
- every non-empty line respects its minimum order;
- cart destination ownership exactly matches active lines;
- the active cart scope exposes only its exact products, count and value;
- the checkout scope exposes only its exact products, count, value and
  destinations;
- fulfilment groups exactly preserve checkout products, counts, values,
  destination and seller ownership.

Periodic non-empty scoped checkouts are confirmed. Each confirmation must
remove only the exact checkout product IDs, preserve out-of-scope lines and
record the exact confirmed item count, value and destination set.

Test-file SHA-256:

`843D15B99B3C39AE8F7363A81B63AE33C642363AD7F169748148C3E2326558AE`

## Verification

- Focused deterministic state-machine test: passed.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `123/123` passed; four opt-in captures skipped.
- Complete Buy regression 2: `123/123` passed; four opt-in captures skipped.
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

The first focused attempt used low LCG bits modulo 12 for action selection and
reached only eight action families. That was a test-generator defect, not an
application failure. The final explicit round-robin action schedule reaches
all 12 families. The failed attempt remains in additive evidence.

## Protected and device identity

- Starting HEAD:
  `04aa46a74fbbef3ee0e21d4d70383dbeade5b494`
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

`artifacts/quality/buy-r35-1-state-machine-hardening-20260731-34`

Evidence includes focused attempts, exact source fingerprints, full analysis,
two same-source regressions, all protected/security/reference/copy gates, HTML
lifecycle and read-only OPPO identity.

Push, deploy, publication and production release remain unauthorized.
