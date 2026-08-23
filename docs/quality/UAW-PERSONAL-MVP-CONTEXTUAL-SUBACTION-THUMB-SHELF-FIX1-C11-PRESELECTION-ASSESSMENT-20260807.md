# C11 contextual sub-action thumb shelf preselection assessment

Date: 2026-08-07

Ticket:
`UAW-PERSONAL-MVP-CONTEXTUAL-SUBACTION-THUMB-SHELF-FIX1-C11`

Classification: `mvp_required`

## Customer outcome and necessity

A Personal account customer reaches every primary Social, Buy, Eat, Ride,
Book and Work sub-action with one direct, one-handed tap from a stable lower
contextual shelf. The top destination zone stays available for advertising,
promotional video and primary content.

The founder observed on OPPO that the technically reachable C10 sub-actions
were shifted to the top, outside comfortable thumb reach and into a reserved
content zone. This is a confirmed supported-MVP navigation regression, so the
smallest complete correction is MVP-required rather than optional redesign.

## Reuse and duplicate search

The production inventory found the existing shared global rail, local action
model, Social context-tab owner, Buy session owner and Eat/Ride/Book/Work route
and state owners. All route outcomes already work. No duplicate screen, route,
backend, provider, business-state owner or build family is necessary.

Implementation disposition:

- `reuse`: all existing action lists, callbacks, state owners and global rail;
- `configuration`: exact approved action membership per destination;
- `test_only_acceptance`: geometry, semantics, text-scale, reduced-motion,
  route continuity and permanent top-zone rejection;
- `new_necessary_work`: one shared composition owner that places destination
  controls immediately above the unchanged global rail.

## Smallest complete implementation

1. Add one shared contextual thumb-shelf composition around the existing local
   action control and existing global rail.
2. Move Social, Buy, Eat, Ride, Book and Work local controls into that owner.
3. Keep Shop, Wholesale, Medicine and Orders as Buy primary destinations;
   keep Help attached to exact order/recovery/Assist context.
4. Preserve every current route, state callback, Back result, scroll, draft,
   focus and IME owner.
5. Add static and widget regression coverage, run two affected cycles and only
   then produce one machine-gated OPPO candidate.

## Explicit exclusions

- no change to the approved global rail geometry, order or meaning;
- no new advertisement, promotional video or provider content;
- no new business flow, screen, route, backend, provider or persistent state;
- no Screens 01–03 change;
- no Social provider contract or Buy commercial-logic change;
- no More menu, modal, palette or multi-tap default path; and
- no credentials, live messages/calls, payments/funds, Production, commit,
  push, deployment or promotion.

## Robustness and delivery

The ticket reuses one shared owner and adds zero routes/screens/backend owners,
so it remains inside the 60–75-day robust-MVP lock with an estimated one-day
impact. Qualification retains compact and large text, minimum 44-by-44 tap
targets, selected semantics, reduced motion, route/lifecycle continuity, two
full affected regressions and checksum-matched one-handed OPPO evidence.
