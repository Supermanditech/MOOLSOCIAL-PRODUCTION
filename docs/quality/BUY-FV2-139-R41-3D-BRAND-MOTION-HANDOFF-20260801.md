# BUY-FV2-139 R41 3D brand-motion handoff

## Decision state

`BUY-FV2-139` is implemented and device-qualified. The exact R41 candidate is
installed on the connected OPPO and awaits founder visual acceptance. It is
not a protected baseline and must not replace the accepted R40.3 Buy, protected
Social or Screen 01 locks until the founder approves this exact object.

## Exact candidate

- Candidate: `BUY-R41-139-3D-BRAND-MOTION-FIX1`
- Mode: profile device review
- Version: `1.0.0-r41`
- Version code: `2026080103`
- Bytes: `132919473`
- APK SHA-256:
  `77965744FB3FA19F5CEFB5FF38AFE11D09AA3AAD5A4CBE9C291C60882253404C`
- App/test source fingerprint:
  `6DF0C9F8FEB073E5A635C0CE47585BAA01F1E549481559C9D4F69C3C6C29C1BE`
- Installed APK: exact byte-for-byte match
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`

## Founder brand-colour memory

The authoritative palette is navy `#000080` plus Indian-flag saffron
`#FF9933`, white `#FFFFFF` and green `#138808`. No fifth colour is permitted
in the wordmark, compact mark, identity line or brand motion. This is recorded
in the durable design contract and enforced by schema 2 of the machine-readable
brand gate.

## Candidate behavior

- One 1,600 ms code-native sequence reveals `Mool`, brings in `Social`, then
  performs a bounded perspective/depth settle to the compact `M`.
- The animation never loops and never gates route readiness.
- One session owner permits one automatic entry playback.
- A deliberate brand tap may replay only after ten minutes of inactivity and a
  twenty-minute playback cooldown. A long resume uses the same limits.
- Reduced motion and accessible navigation render the static compact mark
  immediately.
- One stable `MoolSocial` semantic owner and one hit owner cover the entire
  sequence.
- Launch, Social and Buy now consume the same Flutter owner. The HTML
  screenbook is unchanged.
- The same painter exposes a combined single-glyph `MS` founder-review variant;
  no variant switch is present in the customer app. Runtime selection is `M`
  unless the founder chooses `MS`.

## Qualification

- Full `flutter analyze --fatal-infos`: clean.
- Shared motion/cadence tests: 6/6 passed.
- Code-native review and phase goldens: 4/4 passed.
- Buy regression 1: 167/167 passed, four opt-in captures skipped.
- Buy regression 2: 167/167 passed, four opt-in captures skipped.
- Existing launch, Social conformance and Buy integration suite: 95/95 passed.
- Passing gates: brand integrity, founder-FINAL Buy reference, 154 interaction
  routes, user-facing copy, nine HTML customer states, backend boundary and
  self-test, and data-egress boundary and self-test.
- OPPO cold-open buffered VM trace: 4.524 seconds, 19,682 events and 173 joined
  frames; presentation p95 17.072 ms, one frame over 33 ms (0.578%), no frame
  over 100 ms and maximum 36.348 ms. The only cold shader-library pair lasted
  0.58 ms; remaining compile-name matches were precompiled-code preparation.
- Prebuild and post-qualification source fingerprints match exactly.

## Protected-gate boundary

Three existing gates correctly reject this pre-approval candidate:

1. Screen 01 approved UI lock detects the authorized launch-logo change.
2. Protected Social detects the authorized shared/Social logo change.
3. The R40.3 Buy baseline detects the authorized Buy header-logo change.

These gates were not loosened or overwritten. Founder acceptance must create
new additive Screen 01, Social and Buy brand-motion baselines for the exact
R41 source and APK; every older baseline remains retained.

## Founder-visible evidence

- M versus MS comparison:
  `artifacts/quality/buy-fv2-139-3d-brand-motion-oppo-20260801-50/05-m-vs-ms-code-native-review.png`
- Physical OPPO `Mool`/`Social` arrival:
  `artifacts/quality/buy-fv2-139-3d-brand-motion-oppo-20260801-50/53-oppo-r41-mool-social-arrival.png`
- Physical OPPO full wordmark:
  `artifacts/quality/buy-fv2-139-3d-brand-motion-oppo-20260801-50/54-oppo-r41-full-wordmark.png`
- Physical OPPO compact settle:
  `artifacts/quality/buy-fv2-139-3d-brand-motion-oppo-20260801-50/55-oppo-r41-compact-settle.png`
- Physical OPPO Buy settled state:
  `artifacts/quality/buy-fv2-139-3d-brand-motion-oppo-20260801-50/24-oppo-r41-buy-settled.png`
- Complete evidence:
  `artifacts/quality/buy-fv2-139-3d-brand-motion-oppo-20260801-50`

## Required next action

The founder reviews the installed OPPO candidate and chooses `M`, `MS`, or a
shape/motion correction. On exact acceptance, create additive protected
baselines, rerun closure gates from unchanged source, and close
`BUY-FV2-139`. Do not commit, push, deploy or publish without separate
authorization.

## Founder rejection and authorized successor — 1 August 2026

The founder rejected R41 FIX1 after physical OPPO review. It remains immutable
technical/device evidence and is not an approved visual baseline. Findings:

- no visible motion on the reviewed cold start;
- insufficient animation in the mark itself;
- the compact M shape, size and overall result are unsuitable; and
- a single `M` or combined `MS` does not communicate MoolSocial.

The authorized successor retains the existing logo-space dimensions but makes
the complete `MoolSocial` wordmark the permanent static outcome. A restrained,
finite 3D emit must originate inside that fixed owner, animate the wordmark
itself, remain contained from adjacent controls and visibly start after a true
cold-start frame has painted. Reduced motion resolves directly to the complete
static wordmark. R40.3 Buy, protected Social and Screen 01 remain the active
approved baselines during implementation and qualification.

State: `R41_FIX1_FOUNDER_REJECTED_FULL_WORDMARK_EMIT_SUCCESSOR_AUTHORIZED`.
