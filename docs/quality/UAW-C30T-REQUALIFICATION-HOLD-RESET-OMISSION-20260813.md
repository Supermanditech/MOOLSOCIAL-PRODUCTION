# C30T requalification hold reset omission — 2026-08-13

## Outcome

After a new source-sealed regression entry invalidated the prior cycle pair,
the next pair began without resetting the non-source-sealed machine owners from
the previous pre-AAB-passed state. Cycle 2 rejected the stale state before any
authority, build, upload, install, or device mutation occurred.

## Root cause and prevention

The immutable evidence root was advanced without applying the associated
machine-state invalidation transaction. Future requalification invalidation
atomically advances the evidence root, restores the AAB owner to the continuous
audit build hold, and resets aggregate prebuild qualification and fingerprint
before cycle 1 starts.

The rejected evidence root remains preserved. A fresh two-cycle no-AAB pair is
required before build authority can be activated.
