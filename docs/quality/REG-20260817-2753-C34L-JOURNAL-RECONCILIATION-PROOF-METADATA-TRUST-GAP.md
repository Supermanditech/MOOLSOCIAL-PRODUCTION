# REG-20260817-2753: C34L journal reconciliation proof-metadata trust gap

## Truthful event

Primary end-to-end review of the dual-host green transaction journal found that
reconciliation validates state/aggregate payload hashes and chain continuity,
but it does not re-resolve and hash each retained prerequisite proof. It also
does not require the journal transition, phase, proof path/hash, preimages,
counts, authorities, ticket and attempt to equal the proof record embedded in
both postimages. A missing or altered proof owner, or semantic journal-metadata
tamper that left payload hashes untouched, could therefore survive crash
reconciliation.

This was found by source review after fixture qualification. No real C34L
state, aggregate, source seal, cycle, AAB, Google Play, device, credential,
secret, deployment, or external state changed.

## Root cause

The journal checker treated validated postimage payload hashes as sufficient
transaction evidence and did not close the independent retained-proof and
semantic-metadata trust boundary.

## Prevention

- During reconciliation, resolve the exact repository-relative proof owner,
  confine it to the fixture root when applicable, and require its current
  SHA-256 to equal the journal binding.
- Validate proof ticket, attempt, transition, phase, pass, current preimage,
  all eight counts and all four authorities.
- Require the newest proof record in both decoded postimages to match that same
  semantic tuple and require both histories to remain identical.
- Add missing/tampered proof-file and semantic journal-metadata negatives on
  both PowerShell hosts.

## Candidate consequence

C34L remains selection-only. The previous journal qualification is incomplete
until retained-proof integrity and semantic metadata are fail-closed.
