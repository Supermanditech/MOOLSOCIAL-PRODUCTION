# UAW-C33F postbuild gate prerelease count deadlock

Date: 2026-08-15

## Preserved failure

Read-only continuation of the postbuild-gate audit proved a second deadlock behind the machine-state failure. The universal authority/count assertion requires the aggregate candidate build count to remain zero for every phase. The wrapper correctly increments the aggregate candidate build count to one when it consumes the single AAB authority, so a corrected postbuild machine-state check would still fail on the prerelease count assertion.

The state-owned `buildResult.buildCount` and aggregate-owned `candidate.buildCount` are both one, while upload/install/device counts remain zero. The generic `actionCounts.build` field remains its preserved baseline value and is not the wrapper's candidate build counter.

## Root cause and prevention

Prerelease zero-count invariants were placed in a universal assertion instead of a phase-specific transition contract. Move candidate action-count expectations into exact phase branches and report the authoritative result counters. Postbuild and preupload must require exactly one build and zero uploads/installs; later phases must advance only their authorized counter exactly once.
