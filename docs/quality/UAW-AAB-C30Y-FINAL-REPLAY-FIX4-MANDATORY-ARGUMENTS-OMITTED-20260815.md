# UAW AAB C30Y final replay FIX4 mandatory arguments omitted

Date: 2026-08-15
Regression: `REG-20260815-2190-AAB-C30Y-FINAL-REPLAY-FIX4-MANDATORY-ARGUMENTS-OMITTED`
Status: registered before retry

## Finding

The corrected final replay reached the C30Y FIX4 classifier but called it
without its mandatory `ExpectedContext` and `DiagnosticEvidencePath`
arguments. PowerShell rejected the invocation before the classifier ran.

No build, upload, install, deployment, founder input, credential read or
device mutation occurred. Release action counts remain `0/0/0`.

## Permanent prevention

- Composite replay entries retain each gate's exact required arguments.
- FIX4 always uses `candidate_incomplete` plus one new diagnostic evidence path
  per PowerShell host.
- Parameterless and parameterized gates are never treated as one invocation
  shape.

## Resolution

The corrected replay supplied `candidate_incomplete` and distinct retained
diagnostic paths for PowerShell 7 and Windows PowerShell. Both FIX4 executions
passed the exact C30X hard-gate owner/reason classification, proved unchanged
state, aggregate and manifest, and retained release actions `0/0/0`.
