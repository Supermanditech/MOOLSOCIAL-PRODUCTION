# Buy V2 R35.1 dense flat search suggestions handoff

Date: 31 July 2026

State: `FOUNDER_APPROVED_PROTECTED_BUY_BASELINE`

R35.1 completes ticket `BUY-FV2-106`. It is the founder-directed density
correction to the additive native Flutter flat autocomplete list. Following
the checksum-matched OPPO review, the founder approved R35.1 on 31 July 2026
and authorized a scoped local baseline commit. Push, deployment, publication
and production release remain separate and unauthorized.

## Repository and candidate identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Source fingerprint:
  `2158C38B2F9905C0C76EB2C1528F654BCAB1E25A7B090FB78837F9E749DD9A74`
- Fingerprinted Buy source/test/assets: 33
- Source match before, between and after both regressions, after gates and
  after device replay: exact
- Candidate id:
  `BUY-R35-1-DENSE-FLAT-SEARCH-SUGGESTIONS-DEVICE`
- Version: `1.0.0-r35.1`
- Version code: `2026073045`
- Candidate bytes: `200138608`
- Candidate and pulled installed OPPO APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`
- Device: OPPO CPH2375, Android 13, serial `2b3e0f71`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The worktree remains intentionally dirty and every earlier tracked change,
untracked file and test artifact remains preserved. No clean, reset, restore,
branch switch, commit, push, deploy or publication action was performed.

## Founder correction and production behavior

R35 first removed the rejected suggestion card, heading, product count, scope
copy, decorative iconography and gradient. Its first checksum-matched OPPO
replay proved the hierarchy and query behavior, but the founder rejected its
48-pixel rows and remaining vertical padding as too open. That APK and its
evidence remain preserved under the R35 evidence directory.

R35.1 keeps the flat single-column reference structure and:

- uses exactly 44 Flutter logical pixels for each row, the accessibility-safe
  minimum;
- removes the list's top padding and reduces trailing padding to 8 pixels;
- shows only one truthful search icon and the catalogue-derived term;
- retains subtle separators;
- exposes no heading, count, instruction, scope paragraph, card, gradient,
  oversized icon or false clock/history affordance;
- preserves independent Shop, Wholesale and Medicine suggestion buckets;
- preserves the existing typing, tap-to-query, results, clear, finish,
  navigation and Orders contracts.

No recent-search, popularity, personalization, recommendation or backend
behavior is claimed. Until an approved suggestion API exists, the read-only
session boundary continues to derive up to four terms from products already
allowed by the active destination, category and filters.

## Automated and responsive verification

- Focused Flutter analysis: passed.
- Full Flutter analysis: passed.
- Responsive search-owner test: passed.
- Separate flat vertical-list test: passed.
- Twelve new additive R35.1 captures passed for Shop, Wholesale and Medicine
  at:
  - 320 x 568;
  - 320 x 568 with 140-percent text;
  - 390 x 844 iOS-size; and
  - 430 x 932 iOS-size.
- Every row remained exactly 44 logical pixels at all tested sizes, including
  320 width with 140-percent text.
- Complete Buy regression 1: `106` passed, `4` opt-in capture generators
  skipped.
- Complete Buy regression 2: `106` passed, `4` opt-in capture generators
  skipped.
- The 33-file source fingerprint was identical across both runs.
- Protected Social, approved UI lock, brand integrity, founder-FINAL Buy
  reference, user-facing copy and 154-route interaction gates passed.
- HTML customer-copy passed all nine states. Its temporary server was stopped
  and port 8765 was verified free.

The Android build repeated the repository's inherited future Kotlin Gradle
Plugin migration warning for several plugins. The build completed normally;
R35.1 neither introduced nor hid the warning.

## Checksum-matched OPPO replay

The exact installed APK reached the expected R35.1 candidate marker and
authenticated startup `stage=ready`.

- Shop displayed four flat rows at 88 physical pixels each on the OPPO's 2.0
  density, proving the intended 44 logical-pixel target.
- No Shop heading, scope text or suggestion card was present.
- Tapping `Fresh tomatoes` populated the shared field and returned the real
  500 g Shop offer, with no 10 kg Wholesale leakage.
- Wholesale displayed the same dense flat structure. Tapping the same term
  returned the real 10 kg trade offer, with no 500 g Shop leakage.
- Medicine displayed four separate dense terms. Tapping
  `Paracetamol 500 mg tablets` populated the field and returned its Medicine
  result.
- Clearing that term and directly typing `pain` returned
  `Pain relief gel`, proving typed and tapped searches retain one query owner.
- Backgrounding and hot-resuming the empty focused Shop state preserved all
  four rows, the selected Shop destination and the empty focused field.
- The final runtime audit found zero fatal Android exception, unhandled
  Flutter exception, `E/flutter`, `RenderFlex`, overflow, disposed-state
  callback, bad state or app ANR matches.

The app was intentionally left on the empty focused Shop search list for the
approval review that the founder completed on 31 July 2026.

## Evidence

Additive R35.1 evidence directory:

`artifacts/quality/buy-flutter-r35-1-dense-flat-search-suggestions-oppo-20260731-27`

Key evidence includes:

- all 12 `buy-v2-r35-1-dense-flat-suggestions-*.png` responsive captures;
- `r35-1-final-flutter-analyze.log`;
- `r35-1-responsive-search-test.log`;
- `r35-1-flat-vertical-lists-test.log`;
- `r35-1-final-buy-regression-1.log`;
- `r35-1-final-buy-regression-2.log`;
- all source manifests and exact-match reports;
- all protected/reference/copy/interaction gate logs;
- `r35-1-final-apk-candidate.txt`;
- `r35-1-final-installed-apk-checksum-match.txt`;
- Shop, Wholesale and Medicine OPPO PNG/XML evidence;
- `r35-1-final-device-hot-resume-summary.txt`;
- `r35-1-final-device-runtime-audit.txt`;
- `r35-1-final-repository-integrity.txt`.

The earlier founder-rejected row-density replay remains additive evidence
under:

`artifacts/quality/buy-flutter-r35-flat-search-suggestions-oppo-20260731-26`

## Remaining decisions and risks

- R35.1 is the founder-approved protected native Buy baseline.
- A future suggestion API, ranking, history or personalization contract must
  be founder/backend approved before replacing the truthful catalogue-derived
  boundary.
- A scoped local baseline commit is authorized. Push, deployment, publication
  and production release remain unauthorized.
