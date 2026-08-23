# REG2850 — C34L capture FIX2 action-name privacy false positive

Date: 17 August 2026
State: registered first PS7 source-attestation fixture rejection

## Mistake

The first direct PS7 source-attestation FIX2 positive Play fixture failed because
the recursive forbidden-property regex treated exact required action-count field
`passwordlessEmailSend` as private due to the substring `email`. Parsers passed,
fixture cleanup ran, and no real, external, or private action occurred.

## Prevention

Enforce exact object schemas first and allow the exact eight action-count/four
authority names only in their approved positions before forbidden-name scanning.
Retain rejection for unknown or private-shaped property names everywhere else.
