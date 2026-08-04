# BUY-FV2-137 R40 search/category motion handoff

## Decision state

`BUY-FV2-137` is device-qualified and awaits founder visual acceptance. It is
not complete. The active R38 protected baseline remains authoritative until
the founder accepts the exact R40.2 object below and a new additive protected
baseline is created.

## Exact candidate

- Candidate: `BUY-R40-137-SEARCH-CATEGORY-MOTION-FIX1`
- Mode: profile
- Version: `1.0.0-r40.2`
- Version code: `2026073157`
- Bytes: `132886713`
- APK SHA-256:
  `E66142811F4B5A86CC240A19CFFEF30CB6F32ECBC6DD60B93744018B735409E0`
- App/test source fingerprint:
  `6C783D5F202BF63BCC88CD4B35345523870B8FABA006527C047755FB12C007D6`
- Candidate protected Buy tree:
  `a0c626ffd5c95ff8a190d1624c6d582c48a437cfd992c82d006974acd1d3a7c6`
- Active R38 protected Buy tree:
  `363ebe4c7342ba0118f9a7108e83fa8c2b0b3ded23332c7dd42a32849f9a5cd7`

The built candidate and the APK pulled from the OPPO are exact byte-for-byte
matches.

## Bounded runtime delta

Only two protected runtime files differ from R38:

1. `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`
   - Search band/control duration now resolves
     `BuyV2Motion.expandCollapse`.
   - The incoming primary/Search content owner uses one opacity plus at most
     eight logical pixels of vertical settle over the same token.
   - Outgoing content is removed immediately so semantics and hit ownership
     are never duplicated.
2. `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
   - Category modal forward and reverse durations explicitly resolve the same
     `expandCollapse` token.

Reduced motion resolves every affected duration to zero while final content,
focus, semantics, Back and selection remain usable. Layout, copy, routes,
catalogue data and business rules are unchanged.

## Retained ineligible build

`BUY-R40-137-SEARCH-CATEGORY-MOTION`, version `1.0.0-r40.1`, remains retained
as nonqualifying evidence. Its direct profile command omitted the existing
device-review, emulator-isolation and candidate-ID defines, so the release
configuration guard stopped before first Flutter frame. R40.2 rebuilt the same
source with the sanctioned non-secret review defines; no credential and no
runtime correction was introduced.

## Qualification

- Focused suite: 14/14 total—four Search/category tests, seven accepted tap
  acknowledgement tests and three motion-theme tests.
- Responsive proof: Android 360x800 and iOS 390x844, including 320 px at 140%
  text scale, normal/mid/final states and zero-duration reduced motion.
- Physical OPPO proof:
  - resting Buy;
  - focused Search and suggestions;
  - Search close;
  - category modal;
  - category selection and catalogue update;
  - 17.422-second native motion recording, 6,147,702 bytes, SHA-256
    `B31DF4582C877D451AF6CB681258637B52D6C6D51DF2CA7B3725FDA2DCA1F65F`;
  - empty final package-PID failure scan.
- Warm frame trace: 18 seconds, 96 pointer events and 273 joined frames;
  Dart-frame p90 1.554 ms, build-scope p90 1.5 ms, scoped-raster p90
  0.232 ms, submit-inclusive raster p90 14.093 ms, presentation p95
  17.352 ms, one frame over 33 ms (0.366%), zero over 100 ms, maximum
  41.985 ms and zero shader/compile events.
- Full `flutter analyze`: clean.
- Full Buy regression 1: 167/167 passed, four opt-in captures skipped.
- Full Buy regression 2: 167/167 passed, four opt-in captures skipped.
- Passing gates: approved UI locks, app brand, founder-FINAL Buy reference,
  154 interaction routes, user-facing copy, nine HTML customer states,
  backend boundary and self-test, data-egress boundary and self-test, and the
  119-file protected Social tree.
- Expected pending gate: the default R38 Buy protected gate rejects the exact
  registered candidate tree. It must not be weakened or overwritten.
- Final source fingerprint equals the prebuild fingerprint exactly.

## Founder-visible evidence

- Physical motion video:
  `artifacts/quality/buy-fv2-137-search-category-motion-oppo-20260731-46/124-oppo-search-category-motion-native.mp4`
- Physical Search-open state:
  `artifacts/quality/buy-fv2-137-search-category-motion-oppo-20260731-46/74-oppo-search-open-qualified.png`
- Physical category-open state:
  `artifacts/quality/buy-fv2-137-search-category-motion-oppo-20260731-46/76-oppo-category-open-qualified.png`
- Native-video contact sheet:
  `artifacts/quality/buy-fv2-137-search-category-motion-oppo-20260731-46/128-oppo-native-motion-contact-sheet-2s.png`
- Complete additive evidence:
  `artifacts/quality/buy-fv2-137-search-category-motion-oppo-20260731-46`

## Separate founder route finding

During qualification the founder reported that leaving Buy makes return to Buy
difficult. OPPO reproduction confirmed root Back exits to the launcher,
relaunch lands on Social, Buy is hidden, and recovery takes Mool then Buy.
This is registered separately as `BUY-FV2-138` and deliberately not mixed into
R40.2. It is the next implementation ticket after R40.2 acceptance.

Evidence:
`artifacts/quality/buy-fv2-route-continuity-founder-finding-20260731-47`

## Required next action

The founder reviews the exact R40.2 video/captures and chooses accept or change.
On acceptance, create a new additive protected Buy baseline for the exact
candidate tree, update the default gate to that new baseline, rerun closure
gates, and close `BUY-FV2-137`. Then begin `BUY-FV2-138` route continuity.

No commit, push, deployment or publication is authorized by this handoff.
