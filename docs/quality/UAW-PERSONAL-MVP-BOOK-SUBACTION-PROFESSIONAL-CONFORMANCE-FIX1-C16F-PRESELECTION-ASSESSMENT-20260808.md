# C16F Book sub-action conformance preselection assessment

## Selected ticket

- Ticket: `UAW-PERSONAL-MVP-BOOK-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16F`.
- Classification: `mvp_required`.
- Parent authority:
  `config/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json`.
- Predecessor evidence: Doctor and Salon selected states are captured in the
  completed r60.15 OPPO audit.

## Customer outcome and reuse decision

Book customers keep direct Doctor and Salon destinations in a compact centered
two-action family instead of two overstretched half-screen cells.

- Reuse `BookPageScaffold`, `BookSession`, `/app/book/doctor`,
  `/app/book/salon` and all existing care, salon and booking content/callbacks.
- Reuse the qualified C16A owner already connected with `familyId: 'book'`.
- No duplicate renderer or new implementation owner is required; C16F is
  family-specific conformance, route/Back and content-reachability proof.
- Duplicate search is complete. No new action, route, screen, backend, service
  or state owner is necessary.

## Minimum complete scope

1. Prove the two-action cluster remains compact and centered at 320px/140%
   text, with both targets at least 44x44.
2. Prove Doctor and Salon remain one direct tap, selected semantics are inert
   and Back restores the exact previous Book destination.
3. Prove Doctor and Salon primary controls remain reachable above the
   transparent navigation stack.
4. Prove finite family motion and immediate reduced motion.

## Explicit exclusions

- No care, doctor, clinic, salon, service, booking, price, payment, support,
  copy, route, session, backend or commercial-logic change.
- No filler action, menu, modal, palette or extra tap.
- No screenbook write, build, install, credentials, communication, payments,
  funds, Production, commit, push, deploy or promotion authority.

## Gate plan

- C16F static two-action/shared-owner and route-preservation gate.
- Book focused compact/140%-text/semantics/Back/reduced-motion test.
- Existing Book vertical slice, C16A and C11 placement/motion regressions.
- Regression memory, MVP scope and delivery-discipline gates.
