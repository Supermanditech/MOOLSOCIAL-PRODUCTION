# C30T YouTube catalogue stale-response-order finding — 2026-08-13

## Finding

The paired public Videos/Shorts loader accepted every asynchronous completion.
If a viewer retried while an older request remained pending, the older request
could finish last and overwrite the newer result, both on screen and in the
fresh snapshot store.

## Correction

The Social owner now assigns one monotonically increasing generation to each
paired catalogue load and rejects stale completions before cache or widget
mutation. Videos and Shorts still retain independent success/error truth within
the winning request.

## Verification

A deterministic widget test starts two paired requests, completes the newer
request successfully, then completes the older request with different content.
The newer item remains visible and the older item is absent. The complete
continuity file passed `4` tests. Evidence SHA-256:
`D7A73A4EC24A58A8D50BA4E4A664E2B6DFC22AE69FDF618AEBF31345F31E097E`.

No AAB, provider deployment, Play action, OPPO mutation, Hosting deployment or
external communication occurred.
