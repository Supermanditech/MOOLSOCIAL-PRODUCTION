# REG-20260817-2744: C34L evidence-fixture negative count off by one

## Truthful event

Source readback of the newly authored fixture-only retained-evidence checker
found nine defined negative cases but a terminal summary literal of
`negative=8`. The checker had not been executed. The evidence sub-agent stopped
before correction or test.

Only its three authorized C34L evidence/recovery script owners contain work in
progress. No real candidate state, source seal, cycle, AAB, device, Google Play,
credential, secret, deployment, or external state changed.

## Root cause

The terminal summary count was manually typed before the final negative case
inventory was reconciled.

## Prevention

- Derive the reported negative total from a counter incremented by every
  executed negative fixture.
- Assert the counter equals the exact declared case inventory before emitting
  the pass line.
- Parse and run the fixture checker on both PowerShell hosts only after source
  readback confirms no hardcoded stale total.

## Candidate consequence

C34L remains selection-only at zero release actions. The defect invalidates no
test evidence because the fixture checker had not run.
