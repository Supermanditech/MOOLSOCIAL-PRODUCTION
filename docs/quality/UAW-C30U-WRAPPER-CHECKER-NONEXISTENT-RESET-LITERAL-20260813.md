# C30U wrapper checker nonexistent reset literal

## Incident

The C30U build-wrapper checker required a literal assignment resetting
`secondBuildPerformed` to false. The wrapper preserves the already sealed false
state and contains no such assignment, so the checker failed falsely.

## Root cause

A desired invariant was converted into an assumed source literal without
checking the current wrapper implementation.

## Permanent prevention

Assert exact verified wrapper patterns. For preserved state, forbid assignment
to true and retain the machine-state false invariant rather than requiring an
invented reset line.

No build or external mutation occurred.
