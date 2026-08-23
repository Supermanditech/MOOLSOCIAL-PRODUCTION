# C30T Chat thread-message clear short-circuit rejection — 2026-08-13

## Finding

The first per-thread feedback clear helper used short-circuit OR around two map-removal side effects. If the error removal returned true, the notice removal would not execute.

## Containment and correction

The issue was found before test or release qualification. Both removals must execute in separate statements; only their captured results may be combined to decide whether to notify listeners. No external state changed.
