# C25E bounded Buy header search output truncation rejection

- Date: 2026-08-09
- Scope: `UAW-PERSONAL-MVP-SIX-DOMAIN-ROUTE-PROJECTION-CONTINUITY-FIX8-C25E`
- Status: registered and resolved before retry

## Rejection

The first exact-file search for `_BuyHeader(` returned an unusable output-truncation response instead of the expected bounded matches. It therefore provided no reliable source-location evidence and was not reused for mutation.

## Prevention

Retry exact-file symbol location with an explicit match cap, then read only the bounded current source blocks before applying a patch. Treat tool-level truncation as non-evidence even when the query should have been small.

## Gate

`scripts/check-codex-development-regression-memory.ps1`
