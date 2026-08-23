# REG2690 — C34G generic wrapper binding was missing

## Outcome

The first C34G cycles-zero source gate failed identically in PowerShell 7 and Windows PowerShell because the generic single-AAB wrapper did not yet expose the exact C34G successor binding expected by the candidate gate. C34G remains at `0/0/0/0`; no build, Play or device action occurred.

## Prevention

Add only the explicit C34G support branch to the existing wrapper and its checker, preserving the generic build algorithm and postbuild mirror order. Rebind registry and ticket hashes before replay.
