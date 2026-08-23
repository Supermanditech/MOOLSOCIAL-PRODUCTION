# REG-20260820-3021 Firestore TTL wait interrupted after request

## Incident

Cloud Shell issued the Firestore TTL update requests for the X and Instagram
OAuth attempt collection groups. The founder pressed `Ctrl+C` while each
`gcloud` command was synchronously waiting, causing local nonzero exits after
the server requests had already been accepted.

## Impact

- The local wait processes stopped; the server operations were not cancelled.
- Sanitized authoritative readback showed X TTL `ACTIVE` and Instagram TTL
  `CREATING`.
- No authentication, SMS, email, build, deployment, Play or OPPO action
  occurred.
- Operation resource identifiers are not retained in evidence.

## Root cause

Long-running TTL field updates were started in synchronous wait mode instead of
using `--async` followed by bounded read-only state polling.

## Prevention

Do not rerun either TTL update. For long-running Firestore administration use
`--async`, never interrupt an accepted write, and poll only sanitized
`ttlConfig.state` values until both exact collection groups are `ACTIVE`.
