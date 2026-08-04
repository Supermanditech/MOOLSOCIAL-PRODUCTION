# BUY-FV2 R53 first-party promotion motion handoff

## Current state

**TECHNICALLY/DEVICE QUALIFIED AND FOUNDER APPROVED ON THE CUMULATIVE R55.4
OPPO BINARY** on 2 August 2026.

Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

Candidate `BUY-R53-FIRST-PARTY-PROMOTION-MOTION-FIX1`, profile `1.0.0-r53`
(`2026080205`), owns only `BuyV2PromotionCard`, `_CataloguePromotionRail` and
`_OrdersContinuationRail`.

R53 adds one finite fixed-geometry entry reveal and one bounded icon/arrow
acknowledgement. The existing destination callback fires immediately. Motion
does not loop, auto-scroll, fake a wait, invent an offer, activate advertising,
or create analytics/backend/campaign state. Reduced motion resolves directly
to the complete static card; off-screen `TickerMode` pauses controller travel.

The exact profile candidate and pulled OPPO install are 133,509,297 bytes with
SHA-256
`6C1743A9C43468B6CF4BD40D0ED648D2A4B61D95A491838C5606B2DC1F221B80`.
The sealed 2,306-file source remains exact at SHA-256
`7515088ED6D5F0FC66B61645EDA147C50C082C971753164C26DB2AD70A8F8C0C`.

## Qualification

- Analysis is clean; the focused suite passes 71 tests; two complete Buy
  regressions each pass 181 tests with four established capture-only skips;
  all positive and protected/fail-closed gates reach their expected outcomes.
- Real OPPO taps immediately open the existing Shop basket sheet, select the
  existing Wholesale flexible-pack state, open the existing Medicine
  prescription sheet and return the Orders continuation action to Shop.
- Same-process lifecycle resume passes. The launch-screen regression check
  resolves normally into Social and the phone is parked on Shop for review.
- The corrected 90-frame profile trace has presentation p95 19.589 ms, maximum
  19.876 ms, zero frames over 33/100 ms and zero shader/compile events.
- OPPO blocked compact display overrides; the unchanged-source 320 px / 140%
  deterministic gates pass and the device limitation is explicit. No recorder
  output is claimed: every attempted OPPO/scrcpy file was invalid.
- Known OPPO profile Impeller font-atlas messages are preserved and classified;
  no crash, `FlutterError`, `RenderFlex` or ANR occurs.

Complete evidence and dispositions are preserved in
`artifacts/quality/buy-first-party-promotion-motion-r53-20260802-80`, including
`88-device-qualification-summary.md`. The founder subsequently approved the
finite staggered card arrival, immediate real action, bounded icon/arrow
acknowledgement, fixed geometry and absence of looping or paid-ad behavior on
the cumulative R55.4 binary.
