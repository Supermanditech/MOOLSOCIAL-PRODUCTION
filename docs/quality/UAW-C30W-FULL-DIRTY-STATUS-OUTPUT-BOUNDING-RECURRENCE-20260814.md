# C30W full dirty-status output bounding recurrence

## Rejected attempt

The resumed C30W reconciliation rendered the established huge dirty tree and
the tool output was truncated. It is not accepted as complete dirty-ownership
evidence. Every tracked and untracked file remains preserved in place.

## Root cause and permanent control

The literal status invocation did not apply the active repository memories for
this known large tree. Future reconciliation must emit branch and HEAD as
scalars, capture tracked status with untracked traversal disabled and separate
stderr, and report only deterministic count and SHA-256. Current-ticket paths
are inspected separately and exactly.

No branch change, commit, cleanup, deletion, overwrite, build, upload, install,
provider action, or secret access occurred.
