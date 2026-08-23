# REG2928 — FIX3 source-attestation aggregate identity diagnostic

## Observed event

After REG2927 privacy correction, the next direct PS7 authoritative-receipt-only fixture advanced into the source-attestation writer and exited 1 with the grouped sanitized rejection `capture identity, type, producer, session, nonce, preimage or artifact changed.`

## Impact

- REG2927's canonical action-count correction is proven to advance.
- The grouped message does not identify the mismatched field and is insufficient for correction.
- WinPS was not run; no field diagnosis, retry, later edit/test, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause boundary

At least one authoritative receipt/capture/source-attestation identity field differs across producer and consumer, but an aggregate boolean assertion masks the exact boundary.

## Mandatory prevention

1. After registration, compare each non-private field independently and emit only the exact sanitized field name and expected contract class, never raw values.
2. Verify ticket/type/producer/session/nonce/preimages/artifact/vector/receipt-journal bindings one field at a time.
3. Correct only the proven producer-consumer schema drift and retain a negative for every field class.
4. Inventory and clean only exact failed-run fixture residue after ownership/confinement/privacy proof.
5. Parse, rerun fresh PS7, then WinPS.
