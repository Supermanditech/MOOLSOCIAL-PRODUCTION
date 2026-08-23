# REG2921 — FIX3 journey nested parser quoting expansion

## Observed event

After the bounded REG2915 resolver correction was applied and read back, the journey-adapter subagent launched a nested `pwsh -Command` using an outer double-quoted payload. The outer host expanded `$tokens`, `$errors`, and `$_`, so the inner parser command failed before either owner was parsed.

## Impact

- The parser launcher exited 1; it provides zero owner-parser evidence.
- The already-applied bounded adapter correction is preserved.
- No checker edit, behavioral test, real journey, device, private, build, browser, provider, or external action followed.

## Root cause

An already-prohibited nested double-quoted PowerShell parser wrapper was used instead of parsing in the current host or invoking a literal script file.

## Mandatory prevention

1. Use `[Management.Automation.Language.Parser]::ParseFile` directly in the current host with locally declared variables.
2. For the second host, use a direct `-File` parser gate or a safely literal script owner; never interpolate a nested command payload.
3. Preserve full per-owner parser errors and exit metadata.
