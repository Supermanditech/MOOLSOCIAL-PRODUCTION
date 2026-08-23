# C30M external PowerShell switch-colon string-coercion rejection

- ID: `REG-20260812-1459-C30M-EXTERNAL-POWERSHELL-SWITCH-COLON-STRING-COERCION-REJECTION`
- Date: 2026-08-12
- Scope: local provider-only package-content qualification
- Result: parameter binding rejected after the complete backend suite passed; no cloud action occurred

The package passed a switch expression using
`-AllowReviewedExistingRuntime:$AllowReviewedExistingRuntime` across a new
`powershell.exe` process boundary. It arrived as a string and could not bind to
`SwitchParameter`. C30M builds an explicit argument array and appends the bare
switch only when true; the complete qualifier is rerun from the start.
