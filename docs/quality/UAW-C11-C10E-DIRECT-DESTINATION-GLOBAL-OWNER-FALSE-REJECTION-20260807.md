# C11 C10E direct destination global-owner false rejection

- Regression: `REG-20260807-251-C11-C10E-DIRECT-DESTINATION-GLOBAL-OWNER-FALSE-REJECTION`
- Ticket: `UAW-PERSONAL-MVP-CONTEXTUAL-SUBACTION-THUMB-SHELF-FIX1-C11`
- Date: 2026-08-07 IST

## Observation

After C10B and C10C passed, C10E rejected Eat, Ride, Book and Work because its
source assertion still required every destination owner to instantiate the
global rail directly. C11 deliberately inserts the common contextual shelf
between each destination's existing local rail and the unchanged global rail.

## Permanent correction

C10E now proves that every destination provides its existing
`MoolLocalNavigationRail` through `MoolDestinationNavigationV2`, then proves
that this shared owner terminates in `MoolGlobalNavigationV2`. Its independent
route-transition, reduced-motion, first-level top-Back and retired-dock checks
remain intact, along with the behavioral C10E and C11 journeys.
