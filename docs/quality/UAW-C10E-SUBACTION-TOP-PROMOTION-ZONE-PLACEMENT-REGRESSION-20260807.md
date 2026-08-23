# C10E sub-action top promotion-zone placement regression

Date: 2026-08-07

State: `OPEN_BLOCKING_GLOBAL_NAVIGATION`

Regression ID:
`REG-20260807-240-C10E-SUBACTIONS-MOVED-INTO-TOP-PROMOTION-ZONE`

## Founder observation

The founder accepted the stable global bottom rail, then identified a separate
escaped UX regression: destination sub-actions were shifted to the top of the
screen. That position is reserved for advertising and promotional video, is
outside comfortable one-handed thumb reach, makes users search for routine
actions and gives the sub-actions a weak, inconsistent visual hierarchy.

The C10E bottom-rail acceptance remains valid for the stable global
Mool/Social/Buy/Eat/Ride/Book/Work/Chat shell. It does not accept the current
destination-local sub-action placement.

## Source confirmation

- Buy renders `_BuyDestinationTabs` inside the top header row in
  `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`.
- Social renders `Screen04ContextTabs` immediately below its top header in
  `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`.
- Eat, Ride, Book and Work render `MoolLocalNavigationRail` as the first
  content control after their message banner in their production widget
  owners.

These controls are reachable and wired, but reachability alone is not the
founder-required production UX. The installed OPPO frame exposes the placement
failure that the prior host and device matrices did not reject.

## Root cause

C10 removed competing destination-owned bottom navigation while preserving the
stable global bottom rail, but Codex selected the top header/first-content row
as the replacement location without a founder-approved placement contract.
The regression suite proved route outcome, selected state, semantics and Back
continuity, but did not reserve the promotional-media zone, enforce one-handed
thumb reach or limit routine sub-action access to one direct tap.

## Permanent prevention

1. The top promotional-media zone is reserved for advertising, promotional
   video and destination content; routine destination sub-actions cannot occupy
   it.
2. Routine sub-actions must remain destination-local, visible or predictably
   revealable in the lower thumb-reachable content zone and reachable with one
   direct tap from the destination root.
3. The accepted global bottom rail keeps identical geometry and meaning; a
   local solution cannot replace, duplicate or vertically shift it.
4. A `More` menu, modal sheet, command palette or multi-tap drill-down cannot
   become the default path to primary sub-actions.
5. The successor placement requires an explicit founder UX decision, compact
   and large-text layouts, reduced-motion behavior, production-router tests and
   real one-handed OPPO tap evidence before another navigation candidate can be
   accepted.

## Gate disposition

The machine contract is
`config/mvp-personal-subaction-reachability-promotion-zone-regression.json`.
The enforcing gate is
`scripts/check-personal-subaction-placement-regression.ps1` and is chained from
the implemented global-navigation contract. It must reject implemented/build/
device acceptance while the founder placement decision is pending or any known
top-placement source pattern remains.

No Flutter runtime source, reference, APK or OPPO package was changed by this
registration.
