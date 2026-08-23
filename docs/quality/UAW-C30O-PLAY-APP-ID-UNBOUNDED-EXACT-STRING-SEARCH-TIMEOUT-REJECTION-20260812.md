# C30O Play app-ID unbounded exact-string search timeout rejection

- Date: 2026-08-12
- Scope: local occurrence reconciliation for the rejected Play app ID
- Result: rejected; search timed out without mutation

## Mistake

An exact-string `rg` search for the rejected and authoritative Play app IDs was run from the repository root without bounding large artifact/evidence surfaces. The command timed out.

## Root cause

An otherwise narrow fixed-string query was applied to the full large dirty tree instead of the known C30O configuration, quality-document, and script surfaces.

## Permanent prevention

Do not repeat the repository-root search. Search only bounded text authorities such as `config`, `docs/quality`, and `scripts`, with generated artifacts/build trees excluded, then inspect and patch only exact relevant occurrences.

## Safety outcome

The timed-out search was read-only and changed no file or external state.
