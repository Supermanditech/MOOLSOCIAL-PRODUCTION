# C12 translucent sub-action family rail preselection assessment

Date: 2026-08-07

Ticket:
`UAW-PERSONAL-MVP-TRANSLUCENT-SUBACTION-FAMILY-RAIL-FIX1-C12`

Classification: `mvp_required`

## Customer outcome and necessity

A Personal account customer reaches every primary Social, Buy, Eat, Ride,
Book and Work sub-action with one direct tap from a thin translucent family
rail. The founder-approved global rail stays unchanged, the top promotion zone
stays clear, and Buy product grids and other primary content remain visually
dominant.

The checksum-matched r60.11 OPPO journey proved that the opaque stacked shelf
is too visually heavy and consumes too much of the content viewport. This is a
failed device-qualification result inside the supported MVP navigation path,
so the smallest complete correction is MVP-required.

## Reuse and duplicate search

The existing shared destination-navigation owner, global rail, local action
controls, route callbacks and state owners already provide every required
outcome. No screen, route, backend, provider or persistent-state owner is
needed.

Implementation disposition:

- `reuse`: every existing action list, callback, state owner and global rail;
- `configuration`: exact family icon, accent and action membership;
- `test_only_acceptance`: 48px envelope, 44px targets, translucency,
  semantics, fitment, motion, continuity and OPPO screenshots; and
- `new_necessary_work`: none; restyle the one existing shared owner and make
  the three local control variants fit the common envelope.

## Smallest complete implementation

1. Replace the opaque high shelf surface with one translucent, low-shadow,
   maximum-48px family rail.
2. Keep every primary sub-action directly visible and one-tap reachable.
3. Add a non-interactive destination family marker and semantic relationship
   without reducing any action below 44-by-44.
4. Apply the identical owner and interaction rules to Social, Buy, Eat, Ride,
   Book and Work.
5. Preserve routes, Back results, scroll, drafts, focus, IME and the unchanged
   global-rail geometry, order and meaning.

## Explicit exclusions

- no new screen, route, menu, modal, palette or discovery tap;
- no top promotion-zone placement;
- no target smaller than 44-by-44;
- no provider, backend, business-state or commercial-logic change; and
- no credentials, live messages/calls, payments/funds, Production, commit,
  push, deployment or promotion.

The correction stays inside the 60–75-day robust-MVP lock with an estimated
one-day impact.
