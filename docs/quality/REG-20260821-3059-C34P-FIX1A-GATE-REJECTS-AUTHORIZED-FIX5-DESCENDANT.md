# REG-20260821-3059 C34P FIX1A gate rejects authorized FIX5 descendant

## Observed failure

The FIX1A all-eight authentication gate rejected the current FIX5 MVP selection
because its parent identity assertion requires FIX1A literally. No alternate
or retry occurred before registration.

## Root cause

Like the shared gateway, the FIX1A gate does not model the explicit authorized
descendant lineage that retains the same four accepted source children and adds
live provider-readiness work.

## Impact

- shared-gateway PS7/WinPS gates are green;
- no FIX1A result is claimed from the rejected run;
- no build, Play, OPPO, provider or device action occurred.

## Prevention and authorized continuation

Reuse the exact explicit parent-or-FIX5 selection predicate with an unrelated
ticket negative fixture. Keep every FIX1A parent/child/source/test assertion and
report the active ticket truthfully in PS7 and WinPS.
