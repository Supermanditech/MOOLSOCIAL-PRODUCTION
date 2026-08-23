# C30O computer-use API reference path-recall rejection — 2026-08-12

## Disposition

Rejected as no instruction evidence. No UI input, navigation, console write or account change occurred.

## Mistake

The API refresh attempted to read `api.md` directly under the computer-use skill directory, but the referenced file is not at that recalled path.

## Root cause

The previously read skill-relative reference location was recalled from memory instead of rediscovered from the exact installed skill owner.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Inventory only the exact installed computer-use skill directory.
- Read the precise referenced API path before another Windows-control call.
