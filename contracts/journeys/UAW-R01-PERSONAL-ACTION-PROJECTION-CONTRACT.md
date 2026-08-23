# UAW-R01 Personal action projection contract

Version: 1
State: static MVP reference contract; not a live capability grant

## Outcome

One versioned projection defines the Personal user's visible Mool main actions,
sub-actions, global Chat entry and removed-action recovery. Connected HTML and
native Flutter consumers must use this contract after their independent
reference/dependency gates instead of maintaining another action list.

Canonical projection:
`config/mvp-personal-action-projection-v1.json`.

Structural schema:
`contracts/journeys/uaw-r01-personal-action-projection-v1.schema.json`.

Machine gate:
`scripts/check-mvp-personal-action-projection.ps1`.

Deterministic self-test:
`scripts/test-mvp-personal-action-projection.ps1`.

## Authority boundary

The projection names `launch_policy_owner` as its future authoritative source.
The checked-in JSON is a static reference fixture for UI/reference development;
it cannot grant capability, publish geography, activate a workspace or prove
that a live backend value exists.

Every enabled destination still passes through its existing exact route owner.
Every dependency-held destination carries a non-empty dependency list. Removed
Universal actions remain explicit recovery identities so saved links can fail
truthfully rather than falling through to legacy UI.

## Exact MVP projection

- Social: Shorts, Videos, Feed, Create; Shorts and Videos remain YouTube-held.
- Buy: Shop, Wholesale, Medicine, Orders.
- Eat: Order Food, Book Table.
- Ride: Bike, Auto, Cab.
- Book: Doctor, Salon.
- Work: Earn Today, Workspace.
- Chat: one global entry outside the six main actions.
- No standalone Pay, Tiffin, Get It Done, universal Delivery, Onboard or
  Verify.

## Fail-closed requirements

The machine gate rejects:

- missing, additional, reordered or duplicate action identity;
- a visible prohibited action;
- a held action without a dependency;
- a destination without its exact route owner;
- local capability-grant authority;
- incomplete removed-route recovery;
- invalid effective/expiry bounds; and
- parent-manifest path or SHA-256 drift.
