# C13 direct default sub-action landing preselection assessment

Date: 2026-08-07

Ticket:
`UAW-PERSONAL-MVP-DIRECT-DEFAULT-SUBACTION-LANDING-FIX1-C13`

Classification: `mvp_required`

## Customer outcome and necessity

A Personal account customer reaches the default sub-action and the approved
thin family rail on the first tap of every main action. Eat opens Order Food,
Ride opens Bike, Book opens Doctor and Work opens Earn Today. There is no
intermediate chooser, extra discovery tap or legacy navigation flash.

The checksum-matched r60.12 OPPO journey proved that Social and Buy reach
their destination owners directly, while Eat, Ride, Book and Work still open
legacy choice roots with no family rail. This is a confirmed regression in
four supported MVP launch journeys and makes the same global rail behave
differently by destination.

## Robustness, reuse and duplicate search

The direct default routes, local action rails, state sessions, global action
specification and JourneyRouter already exist. No new screen, route, backend,
provider, controller, service or persistent-state owner is necessary.

Implementation disposition:

- `reuse`: all existing destination screens, deep routes, state owners, the
  C12 family rail and global rail;
- `configuration`: point each global root action at the existing default
  sub-action route;
- `thin_policy_adapter`: make stale `/app/eat`, `/app/ride`, `/app/book` and
  `/app/work` links resolve to those same default routes in production;
- `test_only_acceptance`: first-frame owner, selected local action, absence of
  chooser copy, tap budget, Back and OPPO evidence; and
- `new_necessary_work`: none.

## Smallest complete implementation

1. Change only the four affected main-action route values to existing default
   sub-action routes.
2. Resolve the four retired production root links to those defaults before a
   chooser can render.
3. Preserve Social, Buy, the global rail, the C12 family rail, exact local
   route state and existing destination business owners.
4. Add permanent static and production-router coverage that taps every global
   main action and checks the first landed frame.

## Explicit exclusions and dependency impact

There is no new visual system, screen, route, backend, provider, business
logic, payment, credential, live message/call, Production write, commit, push,
deployment or promotion. The protected Screens 01–03 and accepted Social/Buy
boundaries remain unchanged. The correction stays inside the 60–75-day lock
with an estimated one-day impact and no new dependency.
