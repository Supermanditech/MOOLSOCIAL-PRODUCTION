# REG2649 — C33X post-seal manifest-binding patch mismatch

Date: 2026-08-16 IST

C33X successfully sealed a 1,273-file source manifest with SHA-256
`70E4B7141E71B10BC060A8A37789903FB168B2DEF503521930305D9911891EEE`.
The immediately following compound `apply_patch` attempted to bind that hash
and file count into both candidate state and aggregate, but the aggregate did
not contain the assumed `fileCount` field and patch verification failed.

The patch operation was atomic and changed neither state file. This is still a
post-seal tooling mistake under the no-retry rule. Reject C33X before cycle 1
and build at `0/0/0/0`; preserve its source manifest as non-promotable evidence.

For the exact successor, read and normalize the state and aggregate manifest
binding schemas before sealing, include a file-count field in both, then apply
and verify each exact post-generation binding separately before any cycle.
