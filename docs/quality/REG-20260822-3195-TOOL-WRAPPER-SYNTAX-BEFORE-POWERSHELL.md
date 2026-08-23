# REG-20260822-3195 — Tool-wrapper syntax before PowerShell

## Incident

A JavaScript execution wrapper for a bounded PowerShell source locator failed
with `SyntaxError: Unexpected string`. The nested PowerShell command never ran.

## Impact

- Repository mutations before registration: `0`
- External actions: `0`
- APK builds: `0`
- OPPO actions: `0`

## Root cause

The wrapper carried a dense quoted PowerShell locator instead of the simplest
validated single-call form.

## Permanent prevention

Use one plain awaited tool call with a simple literal command and plain output
projection. Split pattern location from bounded source reads, and never infer
that a wrapper parser failure executed its nested command.
