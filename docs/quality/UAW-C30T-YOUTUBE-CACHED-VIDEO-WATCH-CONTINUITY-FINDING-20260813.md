# C30T YouTube cached video-watch continuity finding — 2026-08-13

## Finding

The Social owner mapped a fresh provider snapshot before first render but set
the active video to null. A `video-watch` route was resolved only after the
network refresh completed and against that request's response. With a slow or
failed refresh, a valid cached watch target opened as YouTube Home.

## Correction

Initial watch resolution now uses the fresh snapshot synchronously. Refresh
completion resolves from the retained authoritative catalogue, so a failed
background refresh cannot discard the cached watch surface.

## Verification

A widget test mounts an exact cached `video-watch` target, proves the watch
surface before network completion, then fails both background catalogue reads
and proves the same watch surface remains. The complete continuity file passed
`4` tests. Evidence SHA-256:
`D7A73A4EC24A58A8D50BA4E4A664E2B6DFC22AE69FDF618AEBF31345F31E097E`.

No stale/expired cache is accepted, and no AAB, provider deployment, Play
action, OPPO mutation, Hosting deployment or external communication occurred.
