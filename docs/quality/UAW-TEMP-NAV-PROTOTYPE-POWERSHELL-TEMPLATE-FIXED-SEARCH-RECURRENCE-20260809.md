# Temporary navigation prototype PowerShell template fixed-search recurrence

## Observation

A duplicate search intended to find the one `${icon('home')}` owner returned the complete HTML source because PowerShell expanded the JavaScript template expression inside a double-quoted command argument and passed an empty fixed-string pattern to ripgrep.

## Cause

The command crossed JavaScript-template and PowerShell-interpolation contexts despite the exact navigation render block already being known.

## Permanent prevention

- Never search for JavaScript `${...}` source through a PowerShell double-quoted literal.
- Prefer the already-known bounded numeric owner range.
- When a fixed search is still required, use a verified single-quoted PowerShell literal and cap results.

## Resolution evidence

The implementation proceeds from the already inspected `renderSubActions` numeric range; no further template-fragment search is used before the patch.
