# C30T PowerShell service diagnostic interpolation parser error

Date: 2026-08-13

The first compact Cloud Run predeployment read did not execute. PowerShell parsed `$s:` in a diagnostic string as an invalid variable reference and failed during parsing, before any CLI call.

Permanent prevention: use braced variables or format strings when punctuation immediately follows an interpolated PowerShell variable.
