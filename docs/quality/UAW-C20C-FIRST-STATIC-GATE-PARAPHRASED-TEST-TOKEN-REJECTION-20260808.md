# C20C first static gate — paraphrased focused-test token rejection

- Date: 2026-08-08
- Scope: C20C host implementation only
- Predecessor gate: C20B passed
- Focused widget tests: 8/8 already passed
- Device/build/install impact: none; closed

## Rejection

The new checker used five intended-coverage paraphrases instead of the exact
test descriptions and expected a formatted `glassFill` invocation to remain on
one source line. The gate therefore rejected its own brittle tokens, not the
runtime implementation.

## Permanent prevention

Focused-test coverage tokens must be copied from the current formatted test.
Method coverage should use stable symbol fragments that do not depend on Dart
line wrapping.
