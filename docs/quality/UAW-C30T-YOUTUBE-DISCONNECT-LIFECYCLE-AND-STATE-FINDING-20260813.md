# C30T YouTube disconnect lifecycle and state finding

Date: 2026-08-13

## Finding

The read-only connection screen exposed a real disconnect action and confirmation dialog, but the continuation called `setState` after `showDialog` without rechecking that the screen was still mounted. Focused tests also did not prove the cancel and confirm branches of this critical user-control journey.

## Bounded correction

- Added the explicit mounted guard immediately after confirmed dialog completion.
- Added a cancel-path test proving no gateway write and retained connected state.
- Added a confirm-path test proving exactly one gateway disconnect and a refresh to the truthful disconnected state.
- Added a source lock for the lifecycle guard ordering.

No provider, OAuth scope, build, deployment, upload, install or external communication is changed.
