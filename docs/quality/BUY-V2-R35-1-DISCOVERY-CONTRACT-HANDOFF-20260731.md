# Buy V2 R35.1 discovery-contract handoff

Date: 31 July 2026

State: `COMPLETE_TEST_ONLY_DISCOVERY_HARDENING`

Ticket `BUY-FV2-116` exhaustively protects the established Shop, Wholesale and
Medicine discovery boundary. It changes no application runtime, UI, backend,
approved HTML, protected media, Social source or business rule.

## Protected discovery invariants

All 176 established offer IDs are searched in each of the three commerce
verticals:

- the owning vertical must return the searched offer;
- either other vertical must return no result;
- every returned result must retain the active vertical's ownership;
- additional same-vertical substring matches remain valid under the
  established contains-search contract.

All 84 category selections are compared with exact ordered catalogue
membership:

- Shop and Wholesale categories match their destination and category ID;
- Medicine categories match their destination and category ID;
- Medicine `rx` is the exact aggregate of prescription-required products;
- empty categories remain truthful empty projections;
- each established “All” projection retains its explicit 18-item bound.

For every category, suggestions must:

- contain at most four titles;
- be non-empty and unique case-insensitively;
- come from the active visible projection;
- keep search results inside the same destination and category;
- disappear after a query is entered.

Orders must expose no product suggestions.

Test-file SHA-256:

`9680A494CDD6CCC51BDD16131959DE95D99750A4E24704F30EF857BC9BA41876`

The first focused run expected every exact offer-ID query to return a
singleton. It correctly failed for `s-potato`, whose established substring
search also returns `s-potato-chips`. This was a test-contract error, not a
runtime defect. The final guard requires the target offer and vertical
isolation while preserving valid same-vertical substring matches. Both logs
remain in evidence.

## Verification

- Focused discovery tests: `3/3` passed.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `132/132` passed; four opt-in captures skipped.
- Complete Buy regression 2: `132/132` passed; four opt-in captures skipped.
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
- The temporary read-only HTML server and managed headless Chrome exited;
  ports 8765 and 9223 were verified free.

## Protected and device identity

- Starting HEAD:
  `b9b4d4f72cd7e9f1ff86b5ed34791444761b4613`
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

`artifacts/quality/buy-r35-1-discovery-contract-hardening-20260731-37`

Evidence includes the initial contract-test failure, final focused output,
exact source fingerprints, full analysis, two same-source regressions, all
protected/security/reference/copy gates, HTML lifecycle and read-only OPPO
identity.

Push, deploy, publication and production release remain unauthorized.
