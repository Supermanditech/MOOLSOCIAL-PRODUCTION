# BUY-FV2-139 R42.1 full-wordmark emit handoff

## Decision state

`BUY-FV2-139` is **TECHNICALLY AND DEVICE QUALIFIED — FOUNDER VISUAL REVIEW
PENDING**. The exact candidate is installed on the connected OPPO. It is not a
founder-accepted baseline and must not replace Screen 01 v3, protected Social
or R40.3 Buy until the founder accepts this exact object.

- Candidate: `BUY-R42-139-FULL-WORDMARK-EMIT-FIX2`
- Profile version: `1.0.0-r42.1` (`2026080105`)
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- APK and final OPPO-pulled SHA-256:
  `8DBE7F1BD51E74E65D2DBB753645CC9138829EAD760E6270AE37B5FDFA42FE42`
- APK bytes: `132919481`
- Prebuild and final source fingerprint:
  `19B4C8F211E04C9EBA2C6E37D35FCAAC24DD53F7D062EE311BDBBCD1CEFDAF38`
- Source files: 1,907 under `apps/mobile/lib` and `apps/mobile/test`

## Implemented outcome

- Full `MoolSocial` is readable at the first Flutter paint and permanent final
  state; no compact `M`, `MS` enum, mark or custom painter remains.
- One fixed-size owner is shared by launch, Social and Buy. Motion never moves
  neighboring layout or hit ownership.
- One finite 1,600 ms sequence gives `Mool` and `Social` restrained contained
  perspective, rotation, translation and opacity travel, then settles to the
  full wordmark. It never loops.
- Cold scheduling paints progress zero once before consuming the one-session
  cadence, preventing a hidden/later surface from stealing visible autoplay.
- Cadence remains session/cooldown/inactivity bounded. Reduced motion renders
  the complete static wordmark immediately.
- Identity painting is limited to navy `#000080`, saffron `#FF9933`, white
  `#FFFFFF` and green `#138808`. One exact `MoolSocial` semantic owner covers
  the sequence.

## Qualification

- Full `flutter analyze --fatal-infos`: clean.
- Shared cadence/wordmark tests: 6/6 passed.
- Code-native review and start/emit/arrival/settled goldens: 5/5 passed.
- 320 px at 140% text: complete wordmark remains bounded.
- Buy regression 1: 167/167 passed, four opt-in captures skipped.
- Buy regression 2: 167/167 passed, four opt-in captures skipped.
- Existing launch/Social/Buy integration suite: 95/95 passed; combined with
  six shared wordmark tests, the captured run is 101/101.
- Passing gates: brand integrity, founder-FINAL Buy reference, 154 interaction
  routes, user-facing copy, nine HTML customer states, backend boundary and
  self-test, and data-egress boundary and self-test.
- Prebuild, post-regression and post-qualification source manifests match
  exactly. The final OPPO pull remains byte-identical to the candidate.

## OPPO evidence

The rapid device-native frame sweep captures the actual cold sequence:
native navy start, first Flutter full-wordmark paint, contained emit, settle,
then the static full wordmark on Social. The separate Buy journey shows the
same complete identity in the fixed header owner. The accessibility tree has
one exact `MoolSocial` semantic owner. Home/resume retains Buy with the same
process and no runtime failure.

The buffered cold-open trace spans 4.573 seconds and 19,508 events with 134
joined frames. Dart p90 is 2.632 ms, build p90 0.595 ms, scoped raster p90
0.232 ms, submit-inclusive p90 12.935 ms and presentation p95 16.634 ms. One
frame exceeds 33 ms (0.746%), none exceeds 100 ms and maximum presentation is
61.547 ms. The shader-library pair is 0.666 ms; remaining compile-name matches
are precompiled-code preparation. No unexplained shader/compile regression is
present.

Final cold launch completed in 2,502 ms. Fatal exception, unhandled exception,
FlutterError, RenderFlex, overflow and ANR scans are all zero.

## Evidence index

Root:
`artifacts/quality/buy-fv2-139-full-wordmark-emit-r42-1-20260801-52`

- `03-full-wordmark-code-native-review.png`: four-colour code-native review.
- `04`–`07-motion-phase-*.png`: deterministic start/emit/arrival/settled.
- `25-oppo-r42-1-wordmark-motion-contact-sheet.png`: physical cold sequence.
- `26`–`29-oppo-r42-1-*.png`: promoted device phases and Social outcome.
- `31-oppo-r42-1-buy.png`: fixed Buy full-wordmark owner.
- `32-oppo-r42-1-lifecycle-*`: Buy-preserving home/resume proof.
- `34-oppo-r42-1-cold-open-buffered-vm-timeline.json`: profile timeline.
- `37-r42-1-cold-open-frame-summary.*`: timing summary.
- `40` and `41-buy-regression-*.log`: two unchanged-source full regressions.
- `44`–`55-*.log`: passing and expected-rejection gates.
- `56-cross-surface-integration.log`: 95 existing plus six shared tests.
- `57-source-manifest-after-qualification.txt` and
  `59-final-source-and-installed-stability.txt`: final identity proof.
- `60-final-cold-launch*` and `61-final-failure-scan.txt`: final runtime scan.

Android `screenrecord` is inaccessible on this OPPO and host `scrcpy` exits
abnormally. The zero/short recorder objects and logs are retained as
nonqualifying capture-tool contamination. No runtime/source workaround was
made. The on-device rapid frame sweep is the qualifying visual-motion proof.

The earlier R42 build in
`artifacts/quality/buy-fv2-139-full-wordmark-emit-r42-20260801-51` omitted the
established device-review Dart defines and failed closed at release Firebase
configuration. It is retained as a nonqualifying provenance object. R42.1 is
the sole review candidate.

## Founder review

Review the contact sheet and the installed cold launch, then decide whether to
accept this exact full-wordmark emit as the additive Screen 01, Social and Buy
brand-motion baseline. The first perspective-turned `Social` edge can appear
as a thin vertical stroke in the painted-start frame; this is a known visual
review point, not a semantic or layout defect. Until acceptance, all previous
approved baselines remain authoritative.
