# C30T PowerShell script LASTEXITCODE null misclassification — 2026-08-13

## Mistake

The regression-memory PowerShell gate completed successfully and printed `Codex regression memory passed`, but its read-only wrapper then tested `$LASTEXITCODE`. Because a PowerShell script invocation does not necessarily assign that native-process variable, the null value was incorrectly classified as a nonzero failure.

## Correction

Repository PowerShell gates are invoked with terminating errors enabled and are allowed to complete normally. `$LASTEXITCODE` is checked only immediately after a native executable whose exit code is part of the command contract.

## Prevention

Do not append a generic `$LASTEXITCODE -ne 0` assertion after a `.ps1` invocation. Use the script's terminating-error contract, or require the script to return an explicit structured status if an additional assertion is needed.
