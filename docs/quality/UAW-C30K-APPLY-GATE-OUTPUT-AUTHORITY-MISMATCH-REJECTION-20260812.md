# C30K apply-gate output authority mismatch rejection

## Finding

The focused gate validated the exact C30K external Dev apply state and matching ticket authority, but its final summary still printed the prior hard-coded `externalWrites=false` value.

## Disposition

Rejected before any external write and registered as `REG-20260812-1406-C30K-APPLY-GATE-OUTPUT-AUTHORITY-MISMATCH-REJECTION`.

## Permanent prevention

The gate summary now derives external-write truth from the exact validated apply-state predicate. The assertion and reported value cannot diverge.
