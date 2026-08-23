# REG2825 — C34L retained builtAt dual-host privacy divergence

Date: 17 August 2026
State: registered first WinPS retained-fixture rejection; zero external action

## Mistake

After the PS7 retained suite passed, Windows PowerShell kept canonical
provenance `builtAt` as a JSON string and the generic phone scanner rejected its
timestamp digits. PowerShell 7 had coerced the same ISO value to `DateTime`, so
the string scan was bypassed there. Only a synthetic fixture root was touched;
no retry, later mutation, or external action followed.

## Prevention

Validate the exact `builtAt` field with one canonical UTC grammar and semantic
instant normalization on both hosts, then exempt only that validated schema
position from phone scanning. Add raw-string and coerced-runtime host coverage
so privacy behavior cannot diverge with `ConvertFrom-Json` date coercion.
