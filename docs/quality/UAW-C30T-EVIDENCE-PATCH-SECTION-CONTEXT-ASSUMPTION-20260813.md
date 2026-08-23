# C30T evidence patch section-context assumption — 2026-08-13

## Failure

A combined state-and-evidence patch assumed an existing Chat deployment note contained a `Prevention` heading. The note ended with `Bounded recovery`, so `apply_patch` rejected the complete patch before making changes.

## Impact

- No part of the rejected patch was applied.
- No external state, build, upload, install or device state changed.

## Prevention

Inspect every exact target anchor before mutation and split machine-state, ticket-state and evidence updates into bounded patches.
