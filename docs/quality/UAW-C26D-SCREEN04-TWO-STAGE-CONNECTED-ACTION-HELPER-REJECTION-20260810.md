# C26D Screen04 two-stage connected-action helper rejection

## Observation

One Screen04 conformance test attempted family selection followed by a menu-owned subaction selection.

## Cause

The helper encoded the superseded two-stage Mool chooser instead of C26's family-only switcher and destination-owned direct actions.

## Permanent prevention

- A Mool family tap routes directly to that family's root.
- Subaction taps are resolved only from the destination bottom rail.
- Keep the static C26C gate forbidding subaction/menu duplication.

## Resolution evidence

The affected helper/call site is migrated before suite retry.
