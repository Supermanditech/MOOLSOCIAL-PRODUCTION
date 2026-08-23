# C30T PowerShell XML singleton unwrapping

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Scope: read-only OPPO Chat filter automation

The first Chat filter helper wrapped the source XML nodes before filtering, but PowerShell unwrapped the single filtered result during pipeline assignment. Indexing the resulting scalar did not return the intended XML element and produced an empty bounds value.

The mandatory bounds assertion stopped execution before any tap, so Chat and device state did not change. The retry must cast the complete pipeline result to `[array]`, require exactly one element, retrieve that element explicitly, and read its `bounds` attribute with `GetAttribute` before calculating numeric coordinates.
