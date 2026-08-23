# UAW AAB C30Y final replay reserved Host parameter

Date: 2026-08-15
Regression: `REG-20260815-2189-AAB-C30Y-FINAL-REPLAY-RESERVED-HOST-PARAMETER`
Status: registered before retry

## Finding

The first final pre-prompt replay declared a PowerShell helper parameter named
`Host`. PowerShell variable names are case-insensitive, so it collided with the
read-only automatic `$Host` variable. The wrapper stopped before invoking its
first child gate.

No AAB build, founder prompt, credential handling, upload, install, deployment
or device mutation occurred. Successor release action counts remain `0/0/0`.

## Permanent prevention

- Orchestration helpers use task-specific parameter names such as
  `RunnerExecutable`.
- Automatic and system variable names are never reused for helper parameters.
- A wrapper-level failure before the first child is non-qualifying and is
  registered before a corrected replay.

## Resolution

The corrected replay used `RunnerExecutable`, reached every intended child,
and completed successfully. It passed regression memory, scope, approved UI,
C31C, C30W, wrapper, FIX2, FIX1 through FIX4, and both prior cycle binders
without consuming release authority; counts remained `0/0/0`.
