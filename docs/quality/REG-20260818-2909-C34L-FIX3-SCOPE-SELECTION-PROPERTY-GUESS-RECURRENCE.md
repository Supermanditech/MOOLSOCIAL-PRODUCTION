# REG2909 — C34L FIX3 scope-selection property guess recurrence

## Incident

On 2026-08-18, while reconstructing the C34L FIX3 pre-ticket selection state,
the agent first enumerated the literal properties of `ticket`, `authorization`
and `execution`, then still projected `ticket.state`,
`ticket.registeredForExecution`, `ticket.selectionState`, `execution.state`,
`execution.authorized` and `authorization.sourceMutationAuthorized`. Those
properties do not exist at those locations, so the resulting nulls are not
accepted as evidence.

## Impact

- The top-level and nested property-name inventories were read successfully.
- The six null projections are inadmissible and will not be reinterpreted as
  false, inactive or unauthorized.
- No ticket, scope state, runtime, build, browser, Play, OPPO, device, journey,
  private/account, secret or external state changed.

## Root cause

The agent included familiar selection/authorization names in a convenience
projection after the immediately preceding live schema inventory proved those
names were absent at the queried levels.

## Prevention

- Build projections only from literal property names returned by the same live
  object inventory.
- Treat every absent property as a schema question, never as a false value.
- Read exact current scalars one discovered path at a time without adding
  conventional names.
- Replay the implementation regression-memory gate before any further
  selection or mutation.

## Disposition

Registered immediately after the read-only recurrence and before further
inspection, selection or implementation.
