# C16G Work sub-action conformance preselection assessment

## Selected ticket

- Ticket: `UAW-PERSONAL-MVP-WORK-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16G`.
- Classification: `mvp_required`.
- Parent authority:
  `config/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json`.
- Predecessor evidence: Earn Today and Workspace selected states are captured
  in the completed r60.15 OPPO audit.

## Customer outcome and reuse decision

Work customers keep direct Earn Today and Workspace destinations in a compact
centered two-action family instead of two overstretched half-screen cells.

- Reuse `WorkPageScaffold`, `WorkSession`, `/app/work/earn`,
  `/app/work/my-work` and all existing opportunity/workspace content/callbacks.
- Reuse the qualified C16A owner already connected with `familyId: 'work'`.
- No duplicate renderer or new implementation owner is required; C16G is
  family-specific conformance, route/Back and content-reachability proof.
- Duplicate search is complete. No new action, route, screen, backend, service
  or state owner is necessary.

## Minimum complete scope

1. Prove the two-action cluster remains compact and centered at 320px/140%
   text, with both targets at least 44x44.
2. Prove Earn Today and Workspace remain one direct tap, selected semantics are
   inert and Back restores the exact previous Work destination.
3. Prove opportunity and workspace primary controls remain reachable above the
   transparent navigation stack.
4. Prove finite family motion and immediate reduced motion.

## Explicit exclusions

- No opportunity, payout, work profile, workspace, verification, retailer,
  copy, route, session, backend or commercial-logic change.
- No filler action, menu, modal, palette or extra tap.
- No screenbook write, build, install, credentials, communication, payments,
  funds, Production, commit, push, deploy or promotion authority.

## Gate plan

- C16G static two-action/shared-owner and route-preservation gate.
- Work focused compact/140%-text/semantics/Back/reduced-motion test.
- Existing Work vertical slice, C16A and C11 placement/motion regressions.
- Regression memory, MVP scope and delivery-discipline gates.
