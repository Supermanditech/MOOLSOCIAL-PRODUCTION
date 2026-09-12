# Universal C20E adaptive navigation test-contract correction v2

Ticket: `UAW-CODEX-UNIVERSAL-C20E-TEST-CONTRACT-V2-20260904`

Work ID: `universal-c20e-test-contract-v2-20260904`

Baseline: accepted Store-Live `aa335eb1497d77c859e7d34b549716350612c5c8`

## Outcome

Update the inherited C20E test contract to describe the current shared Universal navigation rail without changing product behavior.

## Exact implementation owner

`apps/mobile/test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart`

No design-system, theme, Store, Buy, Chat, backend, platform or product source is owned.

## Required contract

- Assert full-width containment for non-overflowing 320–430 px family rails.
- Replace obsolete narrow-width and `lessThan` expectations with current equal-width containment.
- Use the current AnimatedContainer selection owner and verify zero duration under reduced motion.
- Bind selected color to the rendered family accent instead of obsolete navy.
- Retain strong tap-size, label, semantics, inert selected action, available-action tap, contrast, no-scroll, indicator-geometry and reduced-motion assertions.

## Verification

- Focused C20E suite passes.
- Exact serialized ten-file set passes with 145 passed, 70 skipped and zero failed.
- Full Flutter analysis reports zero issues.
- Coordination and regression gates pass.
- Implementation commit is atomic, clean, pushed and remote-equal.

Failed repair `c48e4ecc5c3ccc7a3079d3f64988437599cc78de`, diagnostic commit `58af65f0bb566aaf275c3a856d02d11dba3df822` and rejected v1 bootstrap remain evidence only.
