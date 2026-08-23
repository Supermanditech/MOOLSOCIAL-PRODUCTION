# REG3157 - PowerShell path-line colon interpolation recurrence

## Classification

Registered parser recurrence with zero file read and zero mutation.

## Evidence

The source projector used an interpolated string containing an unbraced path variable immediately followed by `:`. PowerShell rejected it during parsing before any requested source lines were emitted.

## Prevention

Use the format operator (`-f`) for path, line and content projections. Never place a colon immediately after an unbraced PowerShell variable token.
