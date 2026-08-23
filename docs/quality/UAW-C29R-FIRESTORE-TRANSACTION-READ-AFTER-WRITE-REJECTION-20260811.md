# C29R Firestore transaction read-after-write rejection

Date: 2026-08-11

Manual prequalification review found that the first quota-measurement version
queued the quota usage write and then read the per-operation measurement
document within the same transaction. Firestore requires all transaction reads
to occur before writes, so the source would fail in the real Dev runtime even
though the permissive in-memory seam passed.

The transaction now reads quota usage and measurement first, then queues both
writes. The C29R test database permanently rejects any `get` after `create`,
`set` or `delete`, and the accepted/rejected search plus upload/general test
replays this ordering. No external Firestore, deployment, device or credential
action occurred.
