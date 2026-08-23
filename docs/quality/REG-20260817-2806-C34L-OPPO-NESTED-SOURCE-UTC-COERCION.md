# REG2806 — C34L OPPO nested source-binding UTC coercion

Date: 17 August 2026
State: registered fresh PS7 reconciliation rejection; zero real/external action

## Mistake

After source/capture UTC handling was corrected, OPPO reconciliation reparsed
the generated cold evidence. PowerShell 7 coerced nested
`sourceAttestation.producedUtc` to `DateTime`, and an exact string comparison
falsely reported that the source-attestation binding changed. Unique fixtures
were cleaned and no real or external action occurred.

## Prevention

Normalize nested string, `DateTime`, and `DateTimeOffset` timestamp values to
the canonical invariant `.fffZ` instant for semantic equality. Preserve exact
wire spelling independently through the bound evidence and attestation file
hashes/byte counts and raw-token validation at production.
