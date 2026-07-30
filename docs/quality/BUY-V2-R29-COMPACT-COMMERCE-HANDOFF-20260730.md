# Buy V2 R29 compact-commerce handoff

Recorded: 30 July 2026

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`

Founder visual acceptance remains pending. R29 is an uncommitted native
Flutter candidate. It is not a release, deployment, production-signing event,
commit, push or authorization to modify the founder-FINAL HTML.

## Result

Tickets `BUY-FV2-066` through `BUY-FV2-073` are implemented and device
verified:

- Shop, Wholesale and Medicine use one compact menu-only category action,
  leaving the reclaimed row for an established MoolSocial feature;
- the category owner is a dock-anchored white/glass panel with a smaller
  `Find a category` field, separate close action and semantic category icons;
- tapping DC or Buy Chat again returns to the exact prior Buy state;
- product cards, product detail and Cart use `+` at zero and `− quantity +`
  above zero through the existing session/cart contracts;
- shared Buy search remains compact at rest, expands when edited and returns
  cleanly when closed;
- the shared MoolSocial mark uses a light high-contrast tile while retaining
  the approved tricolour geometry and contextual product name; and
- Shop, Wholesale, Medicine, Orders, Cart and Buy Chat retain the shared
  navigation, progress, vertical isolation and customer-copy contracts.

No HTML, Screen 01–03, Social/YouTube, category identifier, backend field,
API contract or business rule changed.

## Device-found renderer correction preserved during R29

The first device replay found that heavy Buy depth changes could settle the
new content while the OPPO had painted only part of the shared header. Earlier
attempts using header keys, repaint boundaries and one/two-frame retries are
preserved as rejected evidence.

The final native implementation stages depth changes:

1. paint the complete branded header with honest `Opening …` progress;
2. prebuild the destination invisibly; and
3. reveal the destination with a fresh isolated header generation.

The exact final APK shows a complete header in captured Wholesale, Medicine
and MoolSocial Assist opening frames, followed by complete settled screens.
The Chat repeat tap returns to the live `MS-240782` tracking state. Reduced
motion uses a static progress acknowledgement.

## Repository and protected identities

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Final 28-file source fingerprint:
  `B7911CDD3D770F3E7260C18B7B2388E92C59819A266147CBF4D70E248E54CCCB`
- Social protected tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- Screens 01–03 protected lock: passed
- Founder-FINAL Buy reference: 25 immutable files passed
- Approved HTML screenbook: unchanged and read-only

The source fingerprint matched before regression, after both regressions and
after the checksum-matched OPPO replay.

## Exact candidate and OPPO identity

- Package: `com.moolsocial.app`
- Version: `1.0.0` (`versionCode 2026073029`)
- Candidate id: `BUY-R29-COMPACT-COMMERCE`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Candidate and pulled installed-base SHA-256:
  `3136A7CFA4EB1C3A001422F18C8C49CF1CE775F673EA68EFF71BC1D4956918CD`
- Candidate APK:
  `moolsocial-buy-r29-compact-commerce-review-debug.apk`
- Evidence:
  `artifacts/quality/buy-flutter-r29-compact-commerce-oppo-20260730-22`

The final rebuild is also byte-for-byte identical to the separately preserved
post-staged-depth-transition APK. The earlier pre-staged final artifact remains
preserved with SHA-256
`351EE47A65F61341672B43D126789DB6D61F60FEF2F0542E5709CA2154D8EA7C`.

## Verification completed

- Full Flutter analysis: no issues
- Corrected focused Buy suite: `84/84` passed
- Responsive capture generation: `2/2` passed
- Responsive capture replay: `2/2` passed
- Final responsive matrix: 73 Android/iOS-size and 140%-text images
- Complete regression 1: `113/113` passed
- Complete regression 2: `113/113` passed
- Route interaction contract: 154 unique routes passed
- Customer-copy Flutter gate: passed
- Customer-copy founder-HTML gate: 9 states passed at `390 × 844`; the
  temporary read-only server and headless browser were stopped afterward
- Brand integrity: passed
- Approved Screens 01–03 and reference locks: passed
- Protected Social baseline: 119 files and exact tree passed
- Git diff hygiene: passed; only existing LF-to-CRLF warnings were reported
- Installed APK checksum: exact match
- Startup diagnostic: correct candidate id and authenticated `stage=ready`
- Runtime audit: no app fatal exception, package ANR, `E/flutter` or unhandled
  Flutter exception found

One failed focused-suite observation is preserved: the test sampled Cart
during the newly honest transition progress instead of waiting for settled
Cart. Production notice placement was still present. The test was corrected
to settle the deliberate transition; the focused `84/84` suite and both
complete `113/113` regressions then passed.

One final HTML-gate harness launch attempt is also preserved: Windows split
paths containing spaces before either process started. The corrected launch
passed all nine states and its exact server/Chrome PIDs were stopped.

## OPPO replay completed

The checksum-matched final replay covers:

- native Shop with compact category action, MoolSocial value feature and
  complete three-column product row;
- dock-anchored glass category panel with semantic icons;
- adaptive search expansion and real filtered results;
- real camera, barcode and QR scanner with compact manual-code recovery;
- grid `+`, inline quantity stepper and prominent mini-cart;
- Cart quantity increase plus DC Account open/repeat-return to the same Cart;
- complete `Opening Wholesale` and `Opening Medicine` frames and settled
  vertical catalogues;
- prescription centre, product-specific Rx selection and Medicine Cart line;
- Orders with active progress, live tracking percentage, route and milestones;
- complete `Opening MoolSocial Assist`, settled Assist and repeat-Chat return
  to the exact live tracking screen; and
- final Shop category glass state for founder review.

The early `r29-final2-oppo-shop` capture is the expanded Mool rail after the
first Mool tap; the actual Buy Shop evidence is
`r29-final2-oppo-buy-shop`. Both are preserved and neither is substituted for
the other.

## Acceptance boundary

This record proves implementation, same-source regression,
protected-reference, exact checksum installation and physical-device replay.
It does not claim founder visual acceptance or production release acceptance.
No commit, push, deploy, publication, HTML edit, Social edit or production
signing was performed.
