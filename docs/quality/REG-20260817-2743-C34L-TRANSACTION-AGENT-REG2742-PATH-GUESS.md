# REG-20260817-2743: C34L transaction-agent REG2742 path guess

## Truthful event

After completing seven independent nonoverlapping reads covering the entire
2,716-line regression-memory owner, the transaction sub-agent attempted to read
REG2742 through the guessed filename
`REG-20260817-2742-C34L-SUBAGENT-REGRESSION-MEMORY-RAW-READ-TRUNCATION.md`.
The actual durable filename differs, so `Get-Content` exited one. The agent
stopped without discovery, retry, gate invocation, or mutation.

No candidate state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The agent reconstructed a new regression filename from the event summary after
being instructed to resolve the exact evidence path from the registry.

## Prevention

- Read the current entry's literal `evidence` path from the parsed regression
  registry before opening any newly registered REG document.
- Never turn a summary phrase into a filename.
- Reuse the returned exact path without manual substitution.

## Candidate consequence

C34L remains selection-only at zero release actions. The complete memory read
is retained as reconstruction progress, but the missing REG2742 read stopped
that agent turn before its memory gate.
