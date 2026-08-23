# C16D Eat sub-action conformance preselection assessment

## Selected ticket

- Ticket: `UAW-PERSONAL-MVP-EAT-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16D`.
- Classification: `mvp_required`.
- Parent authority:
  `config/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json`.
- Predecessor evidence: Order Food and Book Table are both captured in the
  completed r60.15 OPPO audit.

## Customer outcome and reuse decision

Eat customers keep direct Order Food and Book Table destinations in a compact
two-action family instead of two overstretched half-screen cells.

- Reuse `EatDestinationShell`, `EatSession`, `/app/eat/home`, `/app/eat/table`
  and all existing food/table content and callbacks.
- Reuse the qualified C16A owner already connected with `familyId: 'eat'`.
- No duplicate renderer or new implementation owner is required; C16D is
  family-specific conformance, route and content-reachability proof.
- Duplicate search is complete. No new action, route, screen, backend, service
  or state owner is necessary.

## Minimum complete scope

1. Prove the two-action cluster remains compact and centered at 320px / 140%
   text, with both targets at least 44x44.
2. Prove Order Food and Book Table remain one direct tap, selected semantics are
   inert, and Back restores the exact previous Eat state.
3. Prove food/table primary content and hit targets remain above and reachable
   around the transparent navigation stack.
4. Prove finite family motion and immediate reduced motion.

## Explicit exclusions

- No restaurant, food, table, search, cart/order, booking, price, availability,
  copy, route, session, backend or commercial-logic change.
- No filler action, menu, modal, palette or extra tap.
- No screenbook write, build, install, credentials, communication, payments,
  funds, Production, commit, push, deploy or promotion authority.

## Gate plan

- C16D static two-action/shared-owner and route-preservation gate.
- Eat focused compact/140%-text/semantics/reduced-motion test.
- Existing Eat vertical slice, C16A and C11 placement/motion regressions.
- Regression memory, MVP scope and delivery-discipline gates.
