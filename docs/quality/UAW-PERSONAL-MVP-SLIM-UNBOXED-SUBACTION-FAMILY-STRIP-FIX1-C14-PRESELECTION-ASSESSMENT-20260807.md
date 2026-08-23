# C14 slim unboxed sub-action family strip preselection assessment

Date: 2026-08-07

Ticket:
`UAW-PERSONAL-MVP-SLIM-UNBOXED-SUBACTION-FAMILY-STRIP-FIX1-C14`

Classification: `mvp_required`

## Customer outcome and necessity

A Personal customer recognizes every destination sub-action as part of the
selected main-action family and changes it with one tap, while the destination
content remains visually dominant. The strip is category-like, transparent,
unboxed and no taller than its required 44px tap targets.

The founder inspected r60.12 and reported that the 48px layer and its separate
family tile plus boxed action cells still felt too large. The founder supplied
an OPPO Myntra screenshot to illustrate the useful category-strip principle:
lightweight labels, a compact selected identity and no card stack competing
with content. The third-party design is reference evidence only; no brand
asset, taxonomy, promotion or exact layout is copied.

## Reuse and duplicate search

The shared family wrapper, shared Eat/Ride/Book/Work cells, Social ribbon and
Buy tabs already own every action, route, semantic and motion outcome. C13
already fixes all default route landings. No screen, route, backend, service,
controller or state owner is needed.

Disposition:

- `reuse`: all action inventories, routes, callbacks, state owners and the
  unchanged global rail;
- `configuration`: exact 44px envelope, neutral tint and family accents;
- `new_necessary_work`: restyle the existing shared wrapper and three local
  cell variants to remove large boxes, fills and the separate family tile; and
- `test_only_acceptance`: actual 44px targets, content dominance, one tap,
  reduced motion, C13 continuity and OPPO screenshots.

## Smallest complete scope and exclusions

Use an unboxed transparent icon-and-label strip with a two-pixel selected line
and a thin family connector. Keep the selected main action directly below,
preserve all C13 routes and exact state, and use finite 160–200ms tint/line
acknowledgement only. There is no copied third-party UI, new screen, route,
backend, provider, business logic, payment, credential, live message/call,
Production write, commit, push, deployment or promotion.

The correction remains inside the 60–75-day robust-MVP lock with an estimated
one-day impact.
