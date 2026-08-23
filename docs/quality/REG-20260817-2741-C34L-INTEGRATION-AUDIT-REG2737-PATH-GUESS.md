# REG-20260817-2741: C34L integration-audit REG2737 path guess

## Truthful event

On its bounded reconstruction retry, the integration-audit sub-agent attempted
to read REG2737 using the guessed filename
`REG-20260817-2737-C34L-RETAINED-EVIDENCE-CHECKER-DUPLICATE-PARAMETER.md`.
That path does not exist, so `Get-Content` stopped before the intended owner was
read. The agent did not retry or edit an assigned file.

No candidate state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The agent reconstructed a new regression filename from an assumed topic instead
of resolving the exact durable owner from a bounded file inventory or the
parsed registry entry.

## Prevention

- Resolve every REG owner through `rg --files docs/quality` or the entry's
  literal `evidence` path before reading it.
- Never derive a regression filename from its numeric ID and remembered topic.
- Reuse the exact returned literal path for all later reads.

## Candidate consequence

C34L remains selection-only at zero release actions. The missing-path read is
zero REG2737 evidence for that agent turn.
