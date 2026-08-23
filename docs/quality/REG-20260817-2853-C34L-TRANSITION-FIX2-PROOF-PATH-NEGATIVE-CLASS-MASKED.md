# REG2853 — C34L transition FIX2 proof-path negative class masked

Date: 17 August 2026
State: registered expanded PS7 lifecycle exact-class failure

## Mistake

The expanded PS7 lifecycle suite passed the new attestation/capture/device
negatives through wrong device, then its proof-history `evidencePath` mutation
rejected outside the expected detailed/aggregate-history class. The helper
reported only that the class was unexpected; no sanitized actual message,
diagnosis, retry, or later mutation followed. Cleanup completed and no external,
private, or device action occurred.

## Prevention

Capture the sanitized actual rejection once, keep every other proof/history
field valid, and order validation so exact detailed/aggregate history equality
and newest proof `evidencePath` binding have deterministic distinct errors.
Retain separate history-divergence and proof-path negatives.
