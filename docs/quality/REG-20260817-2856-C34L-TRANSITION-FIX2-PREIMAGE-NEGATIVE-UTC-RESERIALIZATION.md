# REG2856 — C34L transition FIX2 preimage negative UTC reserialization

Date: 17 August 2026
State: registered fresh PS7 lifecycle exact-class masking failure

## Mistake

The replay-preimage negative intended to mutate only `preStateSha256`, but it
round-tripped the attestation through `ConvertFrom-Json`/`ConvertTo-Json`.
PowerShell 7 coerced and reserialized `producedUtc`, so validation rejected the
raw UTC wire token before the intended preimage class. Cleanup completed and no
retry, later mutation, external, private, or device action followed.

## Prevention

For a single-field wire negative, assert the exact raw token occurs once and
perform one literal raw JSON substitution of the hash only. Re-hash/rebind the
file without parsing/reserializing timestamps, and retain a separate UTC-wire
negative.
