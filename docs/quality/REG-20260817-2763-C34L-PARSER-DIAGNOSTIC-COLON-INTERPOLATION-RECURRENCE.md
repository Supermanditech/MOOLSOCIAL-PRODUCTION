# REG2763 — C34L parser diagnostic colon interpolation recurrence

Date: 17 August 2026
State: registered wrapper parse failure; no source parser or external action

## Mistake

The PRE-AAB-2 PowerShell 7 parser wrapper constructed a diagnostic row with
`"$path:$($_.Message)"`. PowerShell treated the colon immediately after the
variable name as scoped-variable syntax and rejected the wrapper before any
assigned source parser ran. The agent stopped without retry or mutation. No
candidate, seal, cycle, build, Play, OPPO, browser, device, private, secret or
external state changed.

## Root cause and prevention

The diagnostic repeated the permanent colon-after-interpolated-variable class
already present in regression memory. Parser and test wrappers must construct
rows with the format operator or explicit concatenation. Never place `:`
directly after an interpolated variable name; do not rely on manual escaping or
remembered `${...}` syntax when a non-interpolated formatter is clearer.
