# C30T authorization evidence root partial update — 2026-08-13

## Outcome

The first authorization-owner update advanced the accepted source manifest and
both cycle paths to the current qualification root but left the focused-test
manifest path on an older root. The mismatch was detected before any build gate
or build consumed the record.

## Root cause and prevention

The qualification evidence bundle was updated field-by-field without a single
atomic checklist. Future authorization changes verify the exact source
manifest, focused manifest, two cycle files, their hashes, both file counts,
and the machine state in one bounded post-patch assertion before authority is
activated.

Because this registry evidence is source-sealed, build authority is returned
to the continuous-audit hold and a fresh two-cycle no-AAB pair is required.
