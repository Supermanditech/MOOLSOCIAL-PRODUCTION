# REG3177 - FIX8 nested pwsh runtime-define array flattened

## Classification

Registered prebuild invocation transport rejection with zero Flutter or build action.

## Evidence

The final APK gate was launched through an outer Windows PowerShell command
that passed a string array to nested `pwsh`. The nested process received later
runtime defines as positional arguments and rejected before the gate body ran.
This reproduces the REG3073 transport class. Candidate and build counters remain
at zero.

## Prevention

Invoke `check-apk-regression-gate-state.ps1` in the current PowerShell process
with the array object intact, matching the build wrapper's call semantics. Do
not transport a PowerShell array through a nested executable argument boundary.
