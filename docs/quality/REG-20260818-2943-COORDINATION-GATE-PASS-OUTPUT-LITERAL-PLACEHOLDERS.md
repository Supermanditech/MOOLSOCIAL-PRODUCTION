# REG2943 — Coordination gate pass output literal placeholders

## Observed event

The Facebook inventory agent passed the implementation memory gate and the coordination script exited 0, but its only result line emitted literal `policy={0}; role={1}; task={2}; claims={3}; activeTasks={4}; registry={5}` placeholders. The agent correctly treated this as semantically incomplete evidence and stopped before source/web/mutation/provider/private/device action.

## Root cause

The final PowerShell output used a concatenated string containing format placeholders without applying the `-f` operator to the complete format expression.

## Mandatory prevention

Construct one complete format string and apply `-f` with exact policy ID, role, task, claim count, active-task count and registry generation. Self-assert that no `{N}` placeholder remains before output. Direct PS7 and WinPS gate runs must emit identical concrete evidence.
