# UAW AAB C30Y cycle 2 analyzer orchestration timeout

Date: 2026-08-14
Regression: `REG-20260814-2187-AAB-C30Y-CYCLE2-ANALYZER-ORCHESTRATION-TIMEOUT`
Status: registered before retry

## Finding

The first post-FIX4 cycle-2 analyzer attempt used a ten-second shell-command
timeout for a whole-mobile analyzer that normally requires substantially
longer. The orchestration layer terminated the command before it returned a
native exit. No cycle-2 analyzer exit file was produced, so the attempt is not
qualification evidence.

The command did not invoke an AAB build, upload, install, deployment or device
mutation. Release action counts remain `0/0/0`, and one-build authority remains
unconsumed.

## Permanent prevention

- Long-running qualification commands receive a sufficient command timeout.
- Progress is collected with bounded asynchronous cell waits, not by expiring
  the underlying command.
- A retry uses a new attempt-specific evidence stem and never overwrites a
  partial or completed prior attempt.
- Only a retained log plus an exact native exit of zero may be bound into a
  cycle summary.

## Resolution

The isolated recovery used a sufficient command timeout and unique evidence:

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-reg2187-analyzer-recovery-attempt-02.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-reg2187-analyzer-recovery-attempt-02.exit.txt`

The native exit is exactly zero and the retained analyzer output reports
`No issues found!`. The interrupted qualification evidence remains
superseded; two fresh versioned cycles are still required before release
authority can become available.
