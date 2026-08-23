# UAW AAB C30Y FIX4 replayed after build authority

Date: 2026-08-15
Regression: `REG-20260815-2192-AAB-C30Y-FIX4-REPLAYED-AFTER-BUILD-AUTHORITY`
Status: registered before retry

## Finding

The first final available-authority replay invoked the FIX4 negative classifier
after the one-build authority became available. FIX4 correctly rejected the
call because its negative probe is defined only for a no-build-authority,
zero-action context.

All earlier applicable gates in that replay passed. No founder input was
requested, no authority was consumed, and build/upload/install counts remain
`0/0/0`.

## Permanent prevention

- FIX4 is executed and evidence-bound only before build authority is available.
- Available-authority replay omits FIX4 and rebinds both final cycle summaries,
  which already contain dual-host FIX4 proof from the correct phase.
- Final pre-prompt checks validate current manifest, state, authority, counts,
  scope and all gates applicable to that phase.

## Resolution

Attempt-05 cycles 1 and 2 each passed FIX4 under withheld authority on both
PowerShell hosts, then passed the complete retained Flutter/analyzer/backend/
Hosting evidence binder. After authority promotion, the corrected replay
omitted FIX4, rebound both final summaries on both hosts, passed every
available-authority gate, and proved release actions remained `0/0/0`.
