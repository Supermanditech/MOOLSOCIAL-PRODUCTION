# REG-20260820-3044 Cursor B2 census output bare true PowerShell name

## Observed failure

Cursor's corrected process census reached its final bounded output object but
used `currentProcessExcluded=true`. PowerShell treated `true` as an unresolved
command/name and exited one. Cursor stopped without retrying.

## Root cause

A JavaScript/JSON boolean spelling was used in PowerShell instead of the
PowerShell boolean literal `$true`.

## Impact

- B1 and the existing reconciliation worktree remain preserved;
- no repository/worktree source, manifest, stage, commit or tag action ran;
- no provider, build, Play, OPPO or external state changed;
- the failed census output is not accepted as evidence.

## Prevention and authorized retry

Use `$true` in a PowerShell object or emit the already-proven scalar marker as
text. Parse/typecheck the bounded output expression before running the census;
never retry the rejected bare-`true` command text.
