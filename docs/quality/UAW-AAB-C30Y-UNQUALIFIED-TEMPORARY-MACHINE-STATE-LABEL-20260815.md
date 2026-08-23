# UAW AAB C30Y unqualified temporary machine-state label

Date: 2026-08-15
Regression: `REG-20260815-2191-AAB-C30Y-UNQUALIFIED-TEMPORARY-MACHINE-STATE-LABEL`
Status: registered before retry

## Finding

The authority-withdrawal recovery wrote newly worded temporary values for the
C30X machine and source qualification states. Those labels are not accepted by
the already-qualified C30X state machine and therefore cannot remain.

No release authority was consumed and counts remain `0/0/0`.

## Permanent prevention

- Recovery uses only exact machine-state values already accepted by C30X.
- Additional context is recorded in blockers and retained evidence, not in a
  new state enum.
- New state labels require their own authorized gate change and qualification;
  they are never invented during release recovery.

## Resolution

The state and aggregate were restored to the already-qualified exact values
`source_requalification_pending_C30Y_FIX4_negative_classifier_complete` and
`pending_two_fresh_post_C30Y_FIX4_cycles`. The corrected dual-host FIX4 replay
then passed with state, aggregate, manifest and `0/0/0` counts unchanged.
