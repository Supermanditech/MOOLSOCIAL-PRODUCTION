# C13 route stack has settled and active motion owners

Date: 2026-08-07

Regression:
`REG-20260807-278-C13-ROUTE-STACK-HAS-SETTLED-AND-ACTIVE-MOTION-OWNERS`

## Failure

After the exact default routes gained the shared page transition, the C10E
motion case found two widgets with `moolsocial-main-destination-motion`: the
settled outgoing Eat route at opacity 1.0 and the active incoming Work route at
an intermediate opacity. The test still required exactly one keyed widget.

## Prevention

A push transition may keep both route pages mounted. Motion acceptance selects
the exactly one keyed `FadeTransition` whose opacity is strictly between the
contract start and end values, then measures its paired slide. It does not
assume the Navigator contains only one page or weaken the finite-motion check.
