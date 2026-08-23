# REG-20260821-3113 — Data Connect adapter file-list InputStream projection

Date: 21 August 2026
State: registered; lookup result rejected

## Failure

A read-only Data Connect adapter lookup piped an in-memory filename array into
`Select-String` and then projected `.Path`. PowerShell returned the synthetic
label `InputStream` instead of repository-relative source paths.

## Impact

- The lookup is not accepted as adapter inventory evidence and was not retried.
- No source, test, build, provider, Play, OPPO or private state changed.

## Root cause

`Select-String` over string pipeline input does not retain the originating
filename as its Path owner.

## Prevention

When source paths matter, invoke `Select-String -LiteralPath` per already
resolved file or use `rg` with literal existing roots and bounded output. Do
not project `.Path` from an in-memory string-input match.
