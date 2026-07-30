# Buy V2 R33 responsive-search, media, account and lanes handoff

Date: 30 July 2026

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`

This handoff preserves the exact R33 native Flutter candidate after the
founder's search refinement and the complete connected-OPPO replay. It does
not claim founder visual acceptance, production release acceptance, commit,
push, deployment or publication.

## Repository identity

- Workspace: `C:\GUARANTEED OUTCOME`
- Production repository:
  `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Buy source fingerprint:
  `7B293FB7D81F840BE42902A6C9F8221953D17FAA516D2656C7A11B2C5862145F`
- Fingerprinted files: 33
- Post-device comparison: zero mismatches against
  `r33-final-v4-source-manifest-prebuild.txt`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The worktree remains intentionally dirty. All tracked modifications, untracked
assets, earlier APKs, screenshots, XML trees, logs and other evidence were
preserved. No clean, reset, restore, branch switch, commit, push, deploy or
publication action was performed.

## Candidate identity

- Candidate id:
  `BUY-R33-SEARCH-MEDIA-ACCOUNT-INDEPENDENT-LANES-RESPONSIVE-SEARCH-DEVICE`
- Version: `1.0.0-r33.4`
- Version code: `2026073042`
- APK:
  `artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25/moolsocial-buy-r33-responsive-search-device-review-r2-debug.apk`
- APK bytes: `200138444`
- Candidate SHA-256:
  `9DC65FC11EA5DD3CE086457AE85ED034D396F9E8953E2E2B7B36E019E2709A15`
- Pulled installed OPPO APK SHA-256:
  `9DC65FC11EA5DD3CE086457AE85ED034D396F9E8953E2E2B7B36E019E2709A15`
- Device: OPPO CPH2375, Android 13, serial `2b3e0f71`

The preceding `1.0.0-r33.3` artifact is preserved but rejected. Its
device-review flags triggered the isolated-emulator runtime guard. R33.4
corrected only the build-time flag combination; it uses the already tested
source manifest. R33.3 must not be presented for founder review or called an
accepted candidate.

## Completed scope

Tickets `BUY-FV2-094` through `BUY-FV2-104` are implemented and automated.
They cover:

- a complete vertical-specific search-and-results owner;
- deterministic truthful media for every seeded Buy product;
- compact motion-compatible Buy Chat;
- Account origin through Orders;
- lazy horizontal continuation;
- Account prescription Add;
- Account Wholesale workspace;
- Cart-bar quantity acknowledgement;
- independently scrollable upper/lower product lanes;
- closing expanded search before deeper Buy states; and
- the founder-requested responsive single-surface search refinement.

The final search control is one soft continuous surface with no Back-arrow
owner and no nested field outline. Its active control grows from 44 to 48
pixels, keeps at least 60 percent of the width for typing, reveals clear only
for a non-empty query, uses a compact labelled finish action, preserves the
query on finish and respects reduced-motion settings. The scanner remains
available only at rest. Shop, Wholesale, Medicine and Orders share this
interaction while retaining their independent filtering contracts.

## Automated verification

- Full Flutter analysis: passed with no issue.
- Focused responsive-search tests: passed.
- Complete Buy regression 1: `104` passed, `3` opt-in screenshot generators
  skipped.
- Complete Buy regression 2: `104` passed, `3` opt-in screenshot generators
  skipped.
- Source fingerprint before, between and after regressions: unchanged.
- Responsive capture review:
  - 320 × 568
  - 320 × 568 at 140-percent text
  - 390 × 844 iOS-size
  - 430 × 932 iOS-size
- Protected Social baseline: passed, 119 files and the exact protected tree.
- Approved UI locks: passed.
- Brand integrity: passed.
- Founder-FINAL Buy reference lock: passed, 25 immutable files.
- User-facing copy: passed.
- HTML customer-copy: passed, nine states.
- Interaction contract: passed, 154 unique routes with no static no-op.

The legacy Windows PowerShell attempt at the Social script failed before
evaluation because that host lacks `System.Convert.ToHexString`. The failure
log was preserved. The same required script and all other protected gates
were rerun in PowerShell 7 and passed.

## Final connected-OPPO replay

The exact checksum-matched R33.4 APK reached authenticated startup
`stage=ready`.

Search replay:

- Shop: rest, active empty, `milk`, clear, finish and retained collapsed query.
- Wholesale: rest, `atta`, clear, finish and retained query.
- Medicine: rest, `para`, clear, finish and background/resume with the active
  query retained.
- Orders: rest and exact order-id query `MS-240782`.
- Active search exposes no scanner and no Back arrow; rest restores the
  scanner for product verticals. Orders correctly has no scanner.
- Android Back first dismissed the keyboard, then closed search while
  retaining the query. This is normal Android IME precedence.

Lane replay:

- On Shop, swiping lane 1 moved `Fresh chicken curry cut` from the third card
  to the left edge while lane 2 product bounds remained unchanged. Swiping
  lane 2 then moved `Pure cow ghee` to the left edge while lane 1 remained
  unchanged.
- Wholesale repeated the same proof with `Fresh chicken curry cut` and
  `Pure cow ghee`.
- Medicine exposes two distinct lane semantics and scroll owners. Its current
  unfiltered remaining catalogue contains one product per lane, so neither
  lane has additional displacement. Earlier checksum-matched R33 Medicine
  multi-result evidence proves upper-only and lower-only displacement using
  the unchanged lane implementation.
- Orders has no product-grid lane and was excluded from lane displacement.

Navigation/state replay:

- Active Shop search to DC mounted Account without a stale search body.
- Account to Orders opened a clean order search owner.
- Direct Orders to DC to DC returned to Orders.
- Backgrounding and hot-resuming active Medicine search retained the query and
  finish owner without a crash.

The post-resume runtime audit found no `FATAL EXCEPTION`, unhandled Flutter
exception, `E/flutter`, `RenderFlex`, overflow or disposed-state callback.

## Evidence

Durable evidence directory:

`artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`

Key final evidence:

- `r33-final-v4-buy-regression-1.log`
- `r33-final-v4-buy-regression-2.log`
- `r33-final-v4-flutter-analyze.log`
- `r33-final-v4-source-manifest-prebuild.txt`
- `r33-final-v4-pwsh-social-protected-baseline.log`
- `r33-final-v4-pwsh-approved-ui-locks.log`
- `r33-final-v4-pwsh-brand-integrity.log`
- `r33-final-v4-pwsh-buy-approved-reference.log`
- `r33-final-v4-pwsh-user-facing-copy.log`
- `r33-final-v4-pwsh-interaction-contracts.log`
- `r33-final-v4-html-customer-copy-gate.log`
- `r33-final-v5-installed-apk-checksum-match.txt`
- `r33-final-v5-oppo-shop-search-active.png`
- `r33-final-v5-oppo-shop-search-milk.png`
- `r33-final-v5-oppo-wholesale-search-atta.png`
- `r33-final-v5-oppo-medicine-search-para.png`
- `r33-final-v5-oppo-orders-search-id.png`
- `r33-final-v5-oppo-shop-lanes-before.png`
- `r33-final-v5-oppo-shop-lane1-after.png`
- `r33-final-v5-oppo-shop-lane2-after.png`
- `r33-final-v5-oppo-wholesale-lanes-before.png`
- `r33-final-v5-oppo-wholesale-lane1-after.png`
- `r33-final-v5-oppo-wholesale-lane2-after.png`
- `r33-final-v5-oppo-account-from-shop-search.png`
- `r33-final-v5-oppo-medicine-search-resume.png`
- `r33-final-v5-oppo-runtime-logcat.txt`
- `r33-final-v5-oppo-final-shop-review.png`

## Remaining authority

Founder review of R33.4 remains pending. Do not promote this candidate to a
production-accepted baseline, commit, push, deploy or publish it without
explicit founder authorization. Future subjective UI/UX, branding, theme,
colour, motion, advertising or animation changes require new founder
direction. The approved HTML screenbook remains read-only and protected
Social must remain unchanged.
