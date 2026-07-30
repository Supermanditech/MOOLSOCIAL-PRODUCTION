# Buy V2 R34 vertical search suggestions handoff

Date: 30 July 2026

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`

R34 is the additive native Flutter search-discovery refinement requested after
the completed R33.4 replay. It does not claim founder visual acceptance,
production release acceptance, commit, push, deployment or publication.

## Repository and candidate identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Source fingerprint:
  `8C8028A9ADB7665E7047D4B80B5B5CDFD09920A23402338837F3B9ADE6023AF2`
- Fingerprinted Buy source/test/assets: 33
- Post-device source comparison: exact, zero mismatches
- Candidate id: `BUY-R34-VERTICAL-SEARCH-SUGGESTIONS-DEVICE`
- Version: `1.0.0-r34`
- Version code: `2026073043`
- Candidate APK:
  `artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25/moolsocial-buy-r34-vertical-search-suggestions-device-review-debug.apk`
- Candidate bytes: `200141060`
- Candidate and pulled installed OPPO APK SHA-256:
  `9010320F14F228DFC70B60431BE06D1F3E2BDD978AA80BA2B84213F510D926A2`
- Device: OPPO CPH2375, Android 13, serial `2b3e0f71`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The worktree remains intentionally dirty and all earlier work/evidence is
preserved. No clean, reset, restore, branch switch, commit, push, deploy or
publication action was performed.

## Production behavior

Ticket `BUY-FV2-105` adds a stable read-only search suggestion boundary to the
existing Buy session. Until an approved suggestion API exists, the boundary
returns up to four unique product titles from the real products already
allowed by the active destination, category and filter. It returns no
suggestions for Orders or while a query is non-empty.

The expanded empty state automatically shows:

- `Shop suggestions` in Shop;
- `Wholesale suggestions` in Wholesale; and
- `Medicine suggestions` in Medicine.

The founder-corrected final state contains no `Try...` or `Tap...`
instructional wording. Suggestion taps call the same existing `updateQuery`
owner as direct typing and immediately show real results. Clear restores the
same destination bucket without closing search.

The implementation does not claim recent searches, popularity, trending,
recommendation, personalization or backend completion. It creates no fake
waiting or asynchronous behavior. A future established suggestion adapter can
replace the seed source behind the session boundary without changing the
presentation or query contract.

## Automated and responsive verification

- Full Flutter analysis: passed.
- Focused session test: read-only, truthful, vertical-specific buckets passed.
- Focused widget test: bucket display, tap-to-query, typing, clear and
  destination switching passed.
- Existing responsive-search tests: passed.
- Affected Buy suite: `91/91` passed.
- Complete Buy regression 1: `106` passed, `4` opt-in capture generators
  skipped.
- Complete Buy regression 2: `106` passed, `4` opt-in capture generators
  skipped.
- Source fingerprint before, between, after regressions and after OPPO replay:
  exact.
- Final additive suggestion captures: 12, covering Shop, Wholesale and
  Medicine at:
  - 320 × 568;
  - 320 × 568 at 140-percent text;
  - 390 × 844 iOS-size; and
  - 430 × 932 iOS-size.
- Suggestion controls retained at least 44-pixel targets.
- Full protected Social, approved UI lock, brand integrity, founder-FINAL Buy
  reference, user-facing copy and 154-route interaction gates passed.
- HTML customer-copy passed all nine states and its temporary local server was
  stopped with port 8765 verified free.

The Android build emitted the repository's existing future Kotlin Gradle
Plugin migration warning for several plugins. The build completed normally;
this warning was not introduced or hidden by R34.

## Checksum-matched OPPO replay

The exact installed APK reached the expected candidate marker and authenticated
startup `stage=ready`.

- Shop exposed four Shop-labelled suggestions. Tapping `Fresh tomatoes`
  populated the focused field and returned the real 500 g Shop offer.
- Clear restored all four Shop suggestions.
- Wholesale exposed four Wholesale-labelled suggestions. Tapping the same
  `Fresh tomatoes` term returned the real 10 kg trade offer, proving the bucket
  did not cross into Shop.
- Medicine exposed four Medicine-labelled suggestions. Tapping
  `Paracetamol 500 mg tablets` returned that Medicine offer.
- Clearing the tapped term and directly typing `pain` returned
  `Pain relief gel`, proving tap and typing share the same live query owner.
- Backgrounding and hot-resuming the empty expanded Shop state restored four
  Shop suggestions and an empty focused query.
- The final runtime audit found no `FATAL EXCEPTION`, unhandled Flutter
  exception, `E/flutter`, `RenderFlex`, overflow, disposed-state callback or
  app ANR.

## Evidence

Additive evidence directory:

`artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`

Key R34 files:

- `r34-final-source-manifest-before-regressions.txt`
- `r34-final-source-manifest-after-regression-1.txt`
- `r34-final-source-manifest-after-regression-2.txt`
- `r34-final-source-manifest-post-device.txt`
- `r34-final-flutter-analyze.log`
- `r34-final-buy-regression-1.stdout.log`
- `r34-final-buy-regression-2.stdout.log`
- `r34-final-regressions-source-state-match.txt`
- `r34-final-social-protected-baseline.log`
- `r34-final-approved-ui-locks.log`
- `r34-final-brand-integrity.log`
- `r34-final-buy-approved-reference.log`
- `r34-final-user-facing-copy.log`
- `r34-final-interaction-contracts.log`
- `r34-final-html-customer-copy-gate.log`
- `r34-final-apk-candidate.txt`
- `r34-final-installed-apk-checksum-match.txt`
- `r34-final-oppo-shop-suggestions.png`
- `r34-final-oppo-shop-suggestion-result.png`
- `r34-final-oppo-wholesale-suggestions-final.png`
- `r34-final-oppo-wholesale-suggestion-result-final.xml`
- `r34-final-oppo-medicine-suggestions-final.png`
- `r34-final-oppo-medicine-suggestion-result-final.xml`
- `r34-final-oppo-medicine-typed-pain-final.png`
- `r34-final-oppo-shop-suggestions-resume.png`
- `r34-final-oppo-runtime-logcat.txt`
- `buy-v2-r34-auto-suggestions-*.png`

The earlier additive `buy-v2-r34-search-suggestions-*.png` captures preserve
the first implementation wording before the founder removed the instructional
copy. They are diagnostic history, not the final visual authority.

## Remaining authority

Founder review of the installed R34 candidate remains pending. Do not promote
it to a production-accepted baseline, commit, push, deploy or publish without
explicit founder authorization. The approved HTML screenbook remains
read-only and the protected Social tree must remain unchanged.
