# REG2780 — C34L browser timestamp JSON coercion

Date: 17 August 2026
State: registered persisted-binding fixture failure; no external action

## Mistake

The fresh PowerShell 7 PRE-AAB-3-FIX1 fixture reached newest lifecycle proof
binding but rejected `browserEvidenceProducedUtc`. The raw browser proof used
the canonical wire string, while `ConvertFrom-Json` coerced the retained nested
timestamp to a date-shaped runtime value before comparison. The agent stopped
without retry or patch; cleanup completed and no external action occurred.

## Root cause and prevention

Exact wire timestamp equality was performed on host-dependent decoded runtime
types. Use one dual-host canonicalization helper that accepts only string or
date runtime shapes, converts date values to invariant UTC milliseconds and
returns the exact canonical string. Also validate the retained raw JSON token
where wire spelling matters. Add string/date shape, same-instant different
offset, extra precision and cross-host persisted-history fixtures before wider
qualification.
