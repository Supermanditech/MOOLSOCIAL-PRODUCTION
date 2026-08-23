# REG2848 — C34L OPPO FIX2 artifact-role negative UTC mask

Date: 17 August 2026
State: registered first PS7 child behavioral exact-class failure

## Mistake

The first PS7 OPPO FIX2 child gate reached a duplicate/cross-kind artifact-role
negative but rejected earlier because the mutated source attestation no longer
contained exactly one canonical `producedUtc` wire token. The intended role
failure class was masked. Parsers had passed; fixture cleanup completed and no
real device, external, or private action occurred. No diagnosis or retry followed.

## Prevention

Preserve exact raw UTC tokens when constructing a role-only negative, mutate
only the targeted role/path field, and assert raw-token cardinality before the
writer call. Keep separate UTC-wire and artifact-role exact-class negatives.
