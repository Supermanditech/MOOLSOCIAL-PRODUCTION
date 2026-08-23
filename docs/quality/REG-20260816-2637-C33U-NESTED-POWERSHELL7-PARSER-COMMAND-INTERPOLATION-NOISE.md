# REG2637 — C33U nested PowerShell 7 parser command produced contradictory output

Date: 2026-08-16 IST

The Windows PowerShell AST parse passed for five bounded C33U lifecycle owners.
The first nested PowerShell 7 command then emitted an interpolation error for
`$errors` and also printed its pass marker. That output is invalid and does not
qualify any PowerShell 7 parse.

PowerShell 7 parser checks must be invoked with one literal command per file,
a constant failure message and clean native exit. A pass marker accompanied by
any error record is always rejected. C33U remained unsealed and all build,
Play, device and external authorities remained held.
