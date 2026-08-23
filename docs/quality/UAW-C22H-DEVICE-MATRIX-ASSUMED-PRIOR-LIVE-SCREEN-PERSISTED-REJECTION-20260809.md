# C22H device-matrix stale-live-state rejection

- Date: 2026-08-09
- Candidate: installed checksum-proven r60.21
- Build/install retries: none

## Rejection

The first matrix transition expected one tappable `Open YouTube Videos` node,
but a fresh hierarchy inside the helper found zero. The helper stopped before
the tap and accepted no screenshot/XML evidence for that state.

## Prevention

Each device transition must reacquire and validate its current live hierarchy.
When the state differs from the expected predecessor, reopen the app/family
deterministically and revalidate before tapping; never infer current state from
an earlier screenshot.
