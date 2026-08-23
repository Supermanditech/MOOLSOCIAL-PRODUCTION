# C30T wrapper-gate literal variable expansion — 2026-08-13

## Defect

Pre-execution review found a double-quoted wrapper-source pattern containing `$ErrorActionPreference`. PowerShell would interpolate the variable instead of matching the literal source text.

## Impact

The defect was caught before executing the gate. No build, external action or device mutation occurred.

## Prevention

PowerShell source-audit patterns containing variable names must use single-quoted strings or escape the dollar sign.
