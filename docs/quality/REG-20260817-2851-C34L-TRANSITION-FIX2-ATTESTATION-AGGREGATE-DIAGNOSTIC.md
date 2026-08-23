# REG2851 — C34L transition FIX2 attestation aggregate diagnostic

Date: 17 August 2026
State: registered fresh PS7 lifecycle failure; field diagnosis pending

## Mistake

The fresh PS7 lifecycle run passed the corrected session privacy boundary, then
failed one aggregate assertion covering source-attestation identity, preimage,
vector, artifact, and session. The message does not identify the divergent
field, so no diagnosis, retry, or later mutation followed. Cleanup completed and
no external, private, or device action occurred.

## Prevention

After registration, compare the exact expected/actual schema field names and
types once with sanitized values limited to public hashes/counts/enums. Replace
the aggregate assertion with field-class-specific errors so future fixtures
identify identity, preimage, vector, artifact, or session mismatches directly.
