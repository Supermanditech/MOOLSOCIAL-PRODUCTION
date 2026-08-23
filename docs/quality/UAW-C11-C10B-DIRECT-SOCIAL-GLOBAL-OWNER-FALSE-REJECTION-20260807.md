# C11 C10B direct Social global-owner false rejection

- Regression: `REG-20260807-249-C11-C10B-DIRECT-SOCIAL-GLOBAL-OWNER-FALSE-REJECTION`
- Ticket: `UAW-PERSONAL-MVP-CONTEXTUAL-SUBACTION-THUMB-SHELF-FIX1-C11`
- Date: 2026-08-07 IST

## Observation

The first broader static-gate run passed the C11 placement contract and the
global Mool contract, then C10B rejected Social because it still searched for
`MoolGlobalNavigationV2` directly in the Social screen. C11 intentionally
composes Social's existing local controls through
`MoolDestinationNavigationV2`, whose final child remains the unchanged global
rail. The first complete 26-file host cycle had already passed 236 tests.

## Permanent correction

The C10B checker now proves the complete ownership chain: Social supplies
`Screen04ContextTabs` through the shared local-navigation slot, the shared
destination owner exists, and that owner contains `MoolGlobalNavigationV2`.
The C10B and C11 behavioral tests stay compulsory so this source-level
acceptance cannot conceal changed rail geometry, ordering, meaning or tapping.
