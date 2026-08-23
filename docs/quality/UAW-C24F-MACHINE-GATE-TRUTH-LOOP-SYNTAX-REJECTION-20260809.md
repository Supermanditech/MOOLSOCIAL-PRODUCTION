# C24F machine-gate truth-loop syntax rejection — 2026-08-09

The first C24F machine gate guessed separate `contains(...)` calls for fare and
checkout truth. The focused test stores those exact values in a literal list and
uses one `contains(truth)` assertion inside the loop.

The gate is corrected to require the literals and the loop assertion. Runtime,
focused tests and captures were already passing; this gate invocation counts as
no qualification cycle.
