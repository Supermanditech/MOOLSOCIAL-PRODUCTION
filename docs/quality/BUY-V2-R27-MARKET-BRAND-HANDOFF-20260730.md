# Buy V2 R27 market-hierarchy and brand handoff

Recorded: 30 July 2026

State: `FOUNDER_REJECTED_SUPERSEDED_BY_R28`

The founder rejected R27 after device review because its M watermark appeared
squeezed/corrupted and its horizontal category rail required too much sideways
scrolling. R27 remains preserved as an uncommitted historical device candidate;
R28 supersedes it. This is not a release, deployment, production-signing event,
commit, push or authorization to modify the founder-FINAL HTML.

## Result

Tickets `BUY-FV2-060` through `BUY-FV2-062` are implemented and verified:

- the shared Buy hierarchy now separates brand/context/account from a dedicated
  responsive search band;
- a compact M watermark tile is used across Buy while the complete
  `MoolSocial` name remains visibly present in every shared header context;
- Shop, Wholesale and Medicine use shallow horizontal category discovery and
  independently configured MoolSocial-owned continuation cards;
- Orders keeps real order content first and supports established order search;
- a prominent destination-aware cart card opens the correct vertical or
  aggregate cart; and
- the existing native scanner, account, checkout, address, payment,
  prescription, order and tracking contracts remain intact.

R26 remains preserved as rejected evidence. Its first compact wordmark clipped
to `MoolSo` on the real OPPO. R27 replaces that visual treatment with the M
watermark plus fully visible contextual `MoolSocial` naming.

## Repository and protected identities

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Frozen source fingerprint:
  `DBB4BBA084FC5522E30B7AF51952A9A3BE637378DD7897D5D9B15D772EBE22EC`
- Social protected tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- Screens 01–03 protected lock: passed
- Founder-FINAL Buy reference: 25 immutable files passed
- Approved HTML screenbook: unchanged and read-only

## Exact candidate and OPPO identity

- Package: `com.moolsocial.app`
- Version: `1.0.0` (`versionCode 2026073027`)
- Candidate id: `BUY-R27-MARKET-BRAND`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Candidate, device package and pulled installed-base SHA-256:
  `8192B002A7F0372CC3A10872A26C498D0DC4E28FA3AF5531453A0B0528679BFF`
- R27 evidence:
  `artifacts/quality/buy-flutter-r27-market-brand-oppo-20260730-20`
- Preserved rejected R26 evidence:
  `artifacts/quality/buy-flutter-r26-market-hierarchy-oppo-20260730-19`

## Verification completed

- Flutter analysis: no issues
- Focused Buy screen suite: 38/38 passed
- Same-source affected regression 1: 102/102 passed
- Same-source affected regression 2: 102/102 passed
- Responsive capture matrix: 64 Android/iOS-size and 140%-text images
- Route interaction contract: 154 unique routes passed
- Customer-copy Flutter gate: passed
- Customer-copy founder-HTML gate: 9 states passed through a temporary read-only
  localhost server, which was stopped after the gate
- Brand integrity: passed
- Approved Screens 01–03 and reference locks: passed
- Protected Social baseline: 119 files and exact tree passed
- Git diff hygiene: passed; only existing LF-to-CRLF warnings were reported
- Final startup diagnostic recorded candidate id
  `BUY-R27-MARKET-BRAND`
- Runtime review found no app fatal exception, ANR, `E/flutter` or unhandled
  Flutter exception. Two OPPO `OplusStatistics` provider errors are OEM
  telemetry noise and are not emitted by the Flutter application.

## OPPO replay completed

The checksum-matched R27 replay covers:

- settled Shop header, search, category selection and three-column grid;
- the monthly household-basket continuation action;
- live Shop search for `tomato`;
- native camera/barcode/QR scanner;
- globally reachable account;
- settled Wholesale, Medicine and Orders destinations;
- Shop product add and prominent Shop cart;
- Shop-scoped cart and Orders aggregate cart;
- active order cards with honest progress; and
- the live Shop order-tracking screen with percentage, route, current stage,
  next action and update control.

No application-source change was made during device replay.

## Boundary

- Founder visual acceptance is still required.
- Do not change the approved HTML, Screens 01–03 or Social.
- Do not commit, push, deploy or publish without explicit founder authorization.
- Preserve R26 and all earlier evidence; R27 supersedes R26 only as the current
  founder-review candidate.
