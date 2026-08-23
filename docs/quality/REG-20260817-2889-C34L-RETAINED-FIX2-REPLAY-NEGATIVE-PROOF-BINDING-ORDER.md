# REG2889 — C34L retained FIX2 replay negative reaches proof binding first

- Status: registered first fresh PowerShell 7 retry failure after REG2888.
- Failure: the replayed-source-attestation fixture changed evidence bytes but left newest lifecycle proof ownership stale, so the exact proof-binding invariant rejected before the intended replay semantic.
- Root cause: the negative changed two trust dimensions at once and no longer isolated replay after proof-owner validation was strengthened.
- Prevention: after producing the replayed evidence variant, update its exact path/SHA in both detailed and aggregate newest proof records identically while preserving all other fields; then require the attestation session/replay invariant to reject. Keep the current stale-proof case as a separate proof-binding negative.
- Containment: no diagnosis, retry, WinPS, recovery, release, private, device, or external action followed.
