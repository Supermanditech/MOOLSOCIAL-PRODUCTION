# Universal C20E adaptive navigation test-contract correction

Ticket: `UAW-CODEX-UNIVERSAL-C20E-TEST-CONTRACT-V1-20260904`

Work ID: `universal-c20e-test-contract-v1-20260904`

Baseline: accepted Store-Live `aa335eb1497d77c859e7d34b549716350612c5c8`

## Outcome

Update the inherited C20E test contract to describe the current shared Universal navigation rail without changing product behavior.

## Exact implementation owner

`apps/mobile/test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart`

No design-system, theme, Store, Buy, Chat, backend, platform or product source is owned by this ticket.

## Required contract

- Assert full-width containment for non-overflowing 320–430 px family rails.
- Retain minimum tap size, labels, semantics, selected-action inertness, available-action routing, contrast, no unintended scrolling, indicator geometry and reduced motion.
- Bind selected color to the rendered family accent.
- Use the current AnimatedContainer selection owner and zero reduced-motion duration.

## Verification

- Focused C20E test: complete pass.
- Exact serialized ten-file set: 145 passed, 70 skipped, 0 failed.
- Full Flutter analysis: zero issues.
- Coordination and regression gates: pass.
- Atomic commit, clean remote-equal branch.

Failed repair `c48e4ecc5c3ccc7a3079d3f64988437599cc78de` and diagnostic evidence `58af65f0bb566aaf275c3a856d02d11dba3df822` remain immutable and are not integration inputs.
