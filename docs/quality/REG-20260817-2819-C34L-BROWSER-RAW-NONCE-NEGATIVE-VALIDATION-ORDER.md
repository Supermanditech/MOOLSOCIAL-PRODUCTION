# REG2819 — C34L browser raw-nonce negative validation order

Date: 17 August 2026
State: registered first PS7 blocker exact-class fixture failure; zero external action

## Mistake

The first direct PS7 blocker selftest reached the existing raw-nonce negative,
but the strengthened exact top-level schema rejected the injected `nonce` as
an unknown field before the intended privacy class, `must never contain a raw
session nonce`. The exact-class fixture therefore failed. Unique fixture cleanup
completed and no browser, provider, release, private, or external action occurred.

## Prevention

Check explicit forbidden raw-secret property names and values before the general
unknown-field allowlist, then apply the exact schema. Preserve separate unknown
benign-field and raw-nonce negatives so privacy and schema failure classes are
both deterministic.
