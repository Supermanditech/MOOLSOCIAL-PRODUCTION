# REG2832 — C34L transition-attestation huge status truncation

Date: 17 August 2026
State: registered read-only reconstruction recurrence; zero mutation

## Mistake

The transition-attestation agent ran full `git status --short --branch` against
the huge dirty tree. Its approximately 143,491-token output truncated before the
agent switched to scoped status, so it is inadmissible as complete inventory.
Independent scalar branch and HEAD outputs were exact; no mutation or test followed.

## Prevention

Treat the full status body as boundary-only in this workspace. Verify branch and
HEAD independently, then use explicit scoped status for the three assigned
owners; never request or rely on the complete dirty-tree rendering.
