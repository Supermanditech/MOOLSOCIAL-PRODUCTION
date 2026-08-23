# UAW Personal MVP action wording, wiring and navigation FIX2 preselection assessment

Date: 6 August 2026
Ticket/candidate: `UAW-PERSONAL-MVP-ACTION-WORDING-WIRING-NAVIGATION-FIX2`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user can move from the stable Personal Mool hub into every
founder-approved main action, select every approved sub-action from both the
chooser and the persistent downstream orbit, and return by visible Back,
Android system/gesture Back, Mool or Chat without losing the exact permitted
origin. Navigation feedback is finite, directional and reduced-motion safe.

Founder review of installed FIX1 (`1.0.0-r60.4`) exposed a missed reachable
defect: the Eat, Ride, Book and Work chooser docks collapse to `Mool | section |
Chat`, where the section is an inert selected label rather than the approved
sub-actions. The source audit also found that downstream Ride replaces
`Bike | Auto | Cab` with `Book | Trip | Help`, while downstream Book replaces
`Doctor | Salon` with `Book | Activity | Help`. The functional controls exist,
but the stable sub-action navigation language disappears. This is a confirmed
regression in supported launch journeys and is therefore `mvp_required`.

FIX1 and its r60.4 evidence remain immutable and are reclassified as founder-
rejected for this navigation defect. FIX2 is a unique successor, not an
overwrite or retroactive repair of FIX1 evidence.

## Reuse inventory and smallest complete scope

- Reuse `PersonalMoolRootV2`, `MvpActionChoiceRootV2`,
  `personalMvpActionChoiceRoots`, `MoolOutcomeDock`, `MoolDockAction`, the
  existing production router and all existing destination/session owners.
- Keep the six Personal main actions in the Mool hub's one-tap grid. Do not
  compress eight controls into a non-readable phone-width bottom rail.
- Replace only the chooser's duplicated inert `_ActionChoiceDock` with the
  existing shared `MoolOutcomeDock`, projecting its exact sub-action specs.
- Align downstream Eat, Ride, Book and Work persistent rails with the approved
  sub-actions and selected context. Existing trip, appointment, workspace,
  lifecycle, safety and support controls stay in their existing screen/header
  owners.
- Preserve an active ride or booking lifecycle. A cross-sub-action tap may not
  silently reset or abandon a live lifecycle; it must retain the current state
  and provide truthful local feedback when switching is unsafe.
- Reuse the existing 160 ms tactile dock feedback, 240 ms chooser arrival, native route
  transition, reduced-motion resolution, semantics and minimum touch targets.
- Verify protected Social and Buy rails and Mool/Back continuity without
  changing their runtime trees, goldens or accepted references.

## Duplicate search and necessity proof

The source inventory found one production shared dock owner already used by
Eat, Ride, Book, Work and protected verticals. The chooser's private dock is
the duplicate and the direct root cause. No new screen, route, state, session,
service, store or backend owner is necessary. FIX2 is reuse, projection
configuration, narrow lifecycle-safe adaptation and acceptance coverage.

The existing six main actions, seventeen sub-actions, native destination
owners, Back fallbacks, contextual Mool routes and Chat return query are all
retained. No protected manifest or founder-approved customer outcome changes.

## Explicit exclusions

- No new Personal main action, sub-action, screen, route, session, service,
  store, backend, provider, payment or workspace owner.
- No Social provider activation, YouTube compliance claim, Social runtime tree,
  Social golden or accepted-baseline change.
- No Buy catalogue, Cart, checkout, transaction payment, order, tracking,
  recovery, runtime tree, golden or accepted-baseline change.
- No active ride, appointment, order or workspace lifecycle reset merely to
  satisfy a navigation tap.
- No legacy deep-link deletion, screenbook mutation, locked Screen 01-03
  change, protected manifest mutation or accepted-reference change.
- No OPPO uninstall, data clear, downgrade, signature workaround or deletion
  of FIX1/r60.4 and earlier evidence.
- No credentials, live provider message/call, funds, Production write, commit,
  push, deploy or promotion.

## Dependencies and verification

Dependencies: founder-reported r60.4 defect and exact FIX2 authorization;
locked Personal action projection; Whirlpool navigation/motion directive;
existing shared dock, router, native destination and lifecycle owners; preserved
FIX1/r60.4 and protected predecessors; remediation branch/HEAD and full dirty
state; MVP scope, delivery, APK and device gates.

Verification: exact dock projection on all four chooser roots and downstream
Eat/Ride/Book/Work owners; every sub-action tap; selected semantics; visible and
system Back; direct-open fallback; Mool origin return; Chat exact return;
active-lifecycle preservation; compact 320 px and scaled-text fit; finite and
reduced motion; protected Social/Buy non-activation; format, analysis, affected
and broad regressions twice. Only after all host gates pass may one new unique
profile APK be reserved, built and installed compatibly in place on the same
OPPO for Codex qualification and founder review parking.

Estimated impact: **1 day**, inside the founder-locked 60-75-day window.
