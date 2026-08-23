# REG2773 — C34L FIX1 assessment row order

Date: 17 August 2026
State: registered documentation readback; no repair execution

## Mistake

The batch assessment table inserted order `3-FIX1` after order `4`, despite the
dependency section correctly requiring the repair before the phase matrix. The
hash and ticket identities were correct, but the table could mislead execution
sequencing. No repair agent had resumed and no candidate or external action
occurred.

## Prevention

After inserting a dependency-derived child, compare table row order with the
numbered dependency list before scope-gate replay. Registration-history arrays
may remain append-only, but human execution tables must be dependency-ordered.
