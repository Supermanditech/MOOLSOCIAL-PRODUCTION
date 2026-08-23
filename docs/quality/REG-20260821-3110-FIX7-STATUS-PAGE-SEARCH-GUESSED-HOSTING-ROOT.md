# REG-20260821-3110 — FIX7 status-page search guessed hosting root

Date: 21 August 2026
State: registered; lookup result rejected

## Failure

A read-only `rg` lookup for the FIX7 confirmation status page included the
guessed positional root `hosting`, which does not exist in the production
repository. Ripgrep exited with a path error.

## Impact

- No search result from the compound lookup was accepted.
- No source, test, build, provider, Play, OPPO or private state changed.

## Root cause

A conventional web-root name was supplied from memory instead of resolving
the current Hosting owner from the repository file inventory or `firebase.json`.

## Prevention

Resolve every web/Hosting root from exact current configuration or a bounded
`rg --files` inventory first. Search only returned literal existing paths and
run expected-absence queries separately with explicit exit-1 handling.
