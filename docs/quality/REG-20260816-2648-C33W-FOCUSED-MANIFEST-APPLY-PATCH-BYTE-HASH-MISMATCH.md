# REG2648 — C33W focused-manifest byte hash mismatch

Date: 2026-08-16 IST

Both C33W cycles passed, but the mandatory final source replay rejected the
candidate because the focused manifest file hash differed from the inherited
hash stored in state and aggregate.

The focused manifest was recreated through `apply_patch`, which normalized its
line-ending bytes, while C33W retained C33V's byte hash without an exact
pre-seal readback. The 73-file test list and its tests passed; the immutable
evidence binding did not.

Reject C33W before build at `0/0/0/0`. Preserve its two cycle summaries only as
non-promotable evidence. An exact successor must bind the actual byte hash
before sealing, pass cycles-0 source gates in both hosts, and run two new
cycles. Never inherit an evidence-file hash after recreating its bytes.
