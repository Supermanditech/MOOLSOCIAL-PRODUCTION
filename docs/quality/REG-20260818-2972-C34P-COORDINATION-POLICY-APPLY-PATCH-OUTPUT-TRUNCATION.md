# REG-20260818-2972 C34P coordination-policy apply-patch output truncation

Date: 18 August 2026 (IST)
State: registered after bounded readback, before any retry or implementation continuation

## Incident

The primary attempted one bounded coordination-policy patch to add the all-eight
Apple and Instagram owner paths. The tool response was truncated by the model
context boundary, so the mutation result could not be trusted from the response
alone. All implementation agents were stopped before further owner work.

## Reconciliation

A read-only bounded parse proved that the policy remained valid JSON, all seven
intended new owners landed exactly once, and no owner overlaps were introduced.
No retry of the interrupted patch was performed.

## Prevention

Keep coordination-policy mutations small, immediately parse and project only
the affected claims, and require exact-one owner cardinality plus a global
duplicate-owner count before treating a truncated mutation result as reconciled.

## Retained evidence

- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- this incident record
