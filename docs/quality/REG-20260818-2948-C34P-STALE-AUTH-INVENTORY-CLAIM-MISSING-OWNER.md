# REG-20260818-2948 C34P stale authentication inventory claim

Date: 18 August 2026 (IST)
State: registered before any alternate lookup

## Incident

During mandatory C34P reconstruction, the primary read the exact authentication
source-map owner recorded by the prior coordination claim. The read failed
because the claimed file did not exist. The command returned no document
content. No source, test, provider, browser, device, private, account or external
state changed.

## Root cause

The inherited machine claim remained active after its prior inventory task had
closed, but its planned output owner had never been created. An active claim was
therefore incorrectly treated as proof that the literal file existed.

## Prevention

Closed prior-task claims are removed before C34P ownership is assigned. Every
claimed or referenced source-map owner must pass an exact `Test-Path` check
before a required read; a missing planned evidence owner is recorded as absent
and never retried through a guessed filename. Current authentication owners are
resolved from a bounded `rg --files` inventory and exact symbol searches.

## Retained evidence

- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- this incident record
