# UAW C33G FIX3 Select-String unsupported Recurse

A persistence-coverage diagnostic passed `-Recurse` directly to `Select-String`. PowerShell rejected the parameter after the explicit-file inspection had printed valid output, so the composite command is recorded as failed and changed no file.

Recursive searches must use `rg` or an explicit `Get-ChildItem -Recurse -File | Select-String` pipeline.
