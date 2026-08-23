# REG2821 — C34L retained wrong-digest-keys exact class

Date: 17 August 2026
State: registered fresh PS7 exact-class fixture failure; diagnosis pending

## Mistake

The fresh PS7 retained-evidence run passed its positive and earlier expanded
negatives through wrong capture, then the wrong-digest-keys negative did not
match its expected rejection class. The helper captured but did not emit the
observed rejection, so no diagnosis, retry, or mutation followed. Only unique
synthetic retained-fixture roots were touched; no real or external action occurred.

## Prevention

Exact-class helpers must include the sanitized observed rejection in their
failure output. After registration, perform one bounded read-only diagnostic,
then correct either the oracle or validation ordering while retaining separate
wrong-key and wrong-digest-value negatives.
