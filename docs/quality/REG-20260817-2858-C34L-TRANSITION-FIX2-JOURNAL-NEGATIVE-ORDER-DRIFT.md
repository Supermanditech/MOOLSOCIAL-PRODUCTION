# REG2858 — C34L transition FIX2 journal negative order drift

Date: 17 August 2026
State: registered first PS7 journal fixture failure after FIX2 ordering

## Mistake

The first direct PS7 journal suite after adding FIX2 fixture builders reached an
existing negative whose detailed/aggregate lifecycle histories diverge. The new
required pre-reconciliation equality check correctly rejected earlier, but the
fixture still expected a later journal failure class. Cleanup completed; no
final-evidence builder ran, no retry or mutation followed, and no external,
private, or device action occurred.

## Prevention

Identify the exact existing negative by its bounded fixture label, decide whether
history divergence is its intended target, and update only that oracle/setup.
Keep separate history-equality and later journal-class negatives so validation
ordering is explicit and deterministic.
