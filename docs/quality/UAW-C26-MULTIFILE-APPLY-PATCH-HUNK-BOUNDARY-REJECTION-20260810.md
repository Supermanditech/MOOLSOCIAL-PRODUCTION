# C26 multifile apply-patch hunk-boundary rejection

## Observation

The attempted C26A completion and C26B selection patch was rejected before any
file changed because a subsequent update-file header appeared inside an
unfinished update hunk.

## Cause

Parent state, two child manifests and two new evidence documents were combined
without validating each file boundary independently.

## Permanent prevention

- Patch the parent state, each child manifest and evidence files separately.
- Keep every update hunk bounded by exact surrounding context.
- Do not retry an oversized multifile transition patch after a parser failure.

## Resolution evidence

The transition is retried only as small independently verifiable patches after
the regression-memory gate passes.
