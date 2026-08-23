# REG2929 — FIX3 source-attestation sessionId contract drift

## Observed event

After REG2928 split the grouped source-attestation assertion into sanitized per-field checks, the fresh direct PS7 authoritative-only fixture exited 1 with `capture field sessionId contract class changed.` No raw session value was inspected or reported.

## Impact

- The exact producer-consumer mismatch is isolated to `sessionId`.
- WinPS was not run; no grammar edit, retry, later read/test, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause boundary

The authoritative capture producer and source-attestation consumer apply different session-ID grammar, derivation, or source-field semantics.

## Mandatory prevention

1. Read the producer and consumer session contract side by side without printing values.
2. Define one deterministic session ID derived from the approved nonce/challenge contract and require exact equality in receipt, manifest, attestation, and journal.
3. Never accept an independently caller-authored session ID in production.
4. Add wrong-session, wrong-nonce, wrong-challenge, stale, and replay negatives.
5. Inventory/clean exact fixture residue, parse, rerun fresh PS7, then WinPS.
