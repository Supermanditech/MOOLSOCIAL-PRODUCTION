# Buy V2 R28 brand proportion and category discovery handoff

Recorded: 30 July 2026

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`

Founder acceptance remains pending. R28 is an uncommitted native Flutter
candidate. It is not a release, deployment, production-signing event, commit,
push or authorization to modify the founder-FINAL HTML.

## Result

Tickets `BUY-FV2-063` through `BUY-FV2-065` are implemented and device
verified:

- the shared Buy M watermark now has a balanced landscape silhouette inside
  the unchanged header tile while the complete contextual `MoolSocial` name
  remains visible;
- Shop, Wholesale and Medicine use one stable current-category control instead
  of the rejected horizontal category rail;
- the control opens a vertically scrolling, locally searchable category panel
  with two columns below 350 logical pixels and three columns otherwise;
- the final icon-above-centred-label tiles keep category names readable on the
  OPPO while preserving fast multi-column discovery;
- one category tap selects, closes the panel and restores the full catalogue;
  and
- opening Saved after a category selection resets the active vertical to its
  complete Saved lens.

No HTML, Screen 01–03, Social, category ID, product filter, backend contract or
cross-vertical ownership rule changed.

## Device-found correction preserved during R28

The first R28 artifact correctly removed sideways category scrolling, but its
horizontal icon/label tile composition still truncated labels such as
`Best prices` and split several Medicine names on the real OPPO. That APK,
screenshots, XML and initial checksum remain preserved in the R28 evidence
directory.

The smallest correction changed only the category tile composition to place
the icon above a centred two-line label. New responsive captures use the
`buy-v2-r28-category-tile-fix-local-*` prefix, and all post-fix OPPO artifacts
use `r28-post-device-fix-*`; no earlier evidence was overwritten.

## Repository and protected identities

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Final source fingerprint:
  `E080C090A18C97800D89381D93AC25815027E9EE2CF15160FE8DD493C32A31FD`
- Social protected tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- Screens 01–03 protected lock: passed
- Founder-FINAL Buy reference: 25 immutable files passed
- Approved HTML screenbook: unchanged and read-only

## Exact candidate and OPPO identity

- Package: `com.moolsocial.app`
- Version: `1.0.0` (`versionCode 2026073028`)
- Candidate id: `BUY-R28-BRAND-CATEGORY-TILE-FIX`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Final candidate, device package and pulled installed-base SHA-256:
  `D3813583A90D102B51C9001AC15638710D93E727EA1A4337023EFF3919E95A8F`
- Final candidate APK:
  `moolsocial-buy-r28-brand-category-tile-fix-review-debug.apk`
- R28 evidence:
  `artifacts/quality/buy-flutter-r28-brand-mark-proportion-oppo-20260730-21`

The earlier unaccepted R28 artifact is preserved separately with SHA-256
`76CE2A0168AC6A8B883D9AF3F8D4E1485F38DA9BDB55C94074E69F4811D0FFBD`.

## Verification completed

- Full Flutter analysis: no issues
- Focused Buy screen suite: 39/39 passed
- Responsive capture test: 2/2 passed
- Final responsive matrix: 65 Android/iOS-size and 140%-text images
- Same-source affected regression 1: 103/103 passed
- Same-source affected regression 2: 103/103 passed
- Route interaction contract: 154 unique routes passed
- Customer-copy Flutter gate: passed
- Customer-copy founder-HTML gate: 9 states passed through a temporary
  read-only localhost server, which was stopped after the gate
- Brand integrity: passed
- Approved Screens 01–03 and reference locks: passed
- Protected Social baseline: 119 files and exact tree passed
- Git diff hygiene: passed; only existing LF-to-CRLF warnings were reported
- Final startup diagnostic records
  `BUY-R28-BRAND-CATEGORY-TILE-FIX`
- Runtime audit found no app fatal exception, ANR, `E/flutter` or unhandled
  Flutter exception. One OPPO thermal package-info line is OEM telemetry noise;
  no application failure followed.

Both full regression cycles used final source fingerprint
`E080C090A18C97800D89381D93AC25815027E9EE2CF15160FE8DD493C32A31FD`.
The post-replay source fingerprint remained identical.

## OPPO replay completed

The checksum-matched final replay covers:

- settled Shop catalogue with balanced M and complete `MoolSocial` context;
- Shop category panel with complete three-column labels and vertical scrolling;
- local search for the late `Shop supplies` category;
- one-tap `Shop supplies` selection and filtered three-product grid;
- Saved after category selection, returning to `For you` and showing all three
  saved Shop products;
- Wholesale category panel with complete `Best prices`, `Retail supplies`,
  HoReCa and grocery labels;
- Medicine category panel with complete Prescription, Diabetes, Heart & BP,
  Digestive, Respiratory and other labels; and
- one-tap Medicine Prescription selection and panel close.

The OPPO was left on the corrected Shop category panel for founder review.

## Acceptance boundary

This record proves implementation, regression, protected-reference,
checksum-install and device-replay completion. It does not claim founder
visual acceptance or production release acceptance. No commit, push, deploy,
publication, HTML edit, Social edit or production signing was performed.
