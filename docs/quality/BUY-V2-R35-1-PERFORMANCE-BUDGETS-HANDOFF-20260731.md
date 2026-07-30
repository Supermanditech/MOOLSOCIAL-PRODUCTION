# Buy V2 R35.1 performance-budget handoff

Date: 31 July 2026

State: `COMPLETE_TEST_ONLY_PERFORMANCE_HARDENING`

Ticket `BUY-FV2-111` adds conservative deterministic performance regression
budgets to the established in-process native Buy seam. It changes no
application runtime, UI, backend, approved HTML, protected media or Social
source.

## Scope and limits

The budgets exercise only the current founder-approved local catalogue and
session behavior. They are intended to detect catastrophic algorithmic
regressions with ample CI variance, not to benchmark release hardware.

They do not prove:

- million-product catalogue scale;
- server search ranking or relevance;
- pagination/cursor correctness;
- cache hit rate or invalidation;
- API/network latency;
- inventory, price or checkout concurrency;
- database capacity or query plans.

Those require approved backend contracts, replaceable vertical adapters,
authoritative infrastructure and server/load tests.

## Workloads

### Search and filter projection

- 400 deterministic cycles across Shop, Wholesale and Medicine;
- 1,200 total destination projections;
- exact offer-ID query and destination-specific filter paths alternate;
- every result is checked against its active destination;
- 8,000 ms guard.

Worst observed elapsed time: `174 ms`.

### Mixed cart and checkout projection

- all 172 current unrestricted offers;
- established Shop/Wholesale/Medicine minimum-order quantities;
- exact expected item and price totals;
- 500 repeated checkout line, fulfilment-group, count and total projections;
- 86,000 projected line observations;
- 8,000 ms guard.

Worst observed elapsed time: `286 ms`.

### Vertical state traversal

- 2,000 deterministic cycles across three verticals;
- 6,000 destination/query/filter transitions;
- independently selected categories verified after the workload;
- transient query and filter resets verified;
- 8,000 ms guard.

Worst observed elapsed time: `19 ms`.

Performance-test SHA-256:

`A7F2E772BA96E1AC6BF3233887F8DC4410C4E5D2006444A4F0265655A4B07E62`

## Verification

- Focused performance tests: `3/3` passed.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `114/114` passed; four opt-in capture generators
  skipped.
- Complete Buy regression 2: `114/114` passed; four opt-in capture generators
  skipped.
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
- Temporary HTML server exited and port 8765 was verified free.

## Protected and device identity

- Starting HEAD:
  `9be6e1f02e502e544946ff9400c09d12abc94047`
- Protected Buy runtime files: `28`
- Protected Buy tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- OPPO: `2b3e0f71`
- Installed version: `1.0.0-r35.1`
- Installed version code: `2026073045`
- On-device base APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`

Because runtime bytes did not change, no APK rebuild or reinstall was
required.

## Evidence

`artifacts/quality/buy-r35-1-performance-budgets-20260731-32`

Evidence includes focused measured output, test/source fingerprint, full
analysis, two complete regressions, all protected/security/reference/copy
gates, HTML server lifecycle and read-only OPPO identity.

## Future server-scale gate

After approved contracts exist, add independent load suites for Shop,
Wholesale and Medicine. They must cover cursor stability, vertical-specific
filters/ranking, cache policy, p95/p99 latency, inventory/price freshness,
checkout idempotency, unknown-outcome reconciliation and admission controls.
Do not reinterpret these local budgets as evidence for those properties.
