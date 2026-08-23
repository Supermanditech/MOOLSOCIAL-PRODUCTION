# UAW-R12 Personal legacy-route containment preselection assessment

Date: 6 August 2026
Ticket: `UAW-R12-PERSONAL-LEGACY-ROUTE-CONTAINMENT`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user who opens an old Tiffin, Get It Done, standalone Pay,
Delivery, Onboard or Verify route/link receives a truthful finished recovery
state. The old link cannot bypass the current Personal action policy and the
person's intent is not silently changed.

## Complete route/caller inventory

- Tiffin: `/app/eat/tiffin`, descendants and `sub=tiffin` aliases.
- Get It Done: `/app/book/home`, `/app/book/task` descendants and
  `sub=get-done`/`sub=home` aliases.
- Standalone Pay: `/app/pay`, `/app/pay/home`, `/recharge`, `/bills`, `/scan`,
  `/requests`, `/receipts` and corresponding legacy sub-action aliases.
- Delivery: the obsolete generic
  `/app/work/opportunity/delivery` and `sub=delivery` alias.
- Onboard/Verify: `/app/work/choose`, `/app/work/proof` and their sub-action
  aliases.
- Historical callers exist in the read-only legacy Universal presentation,
  old Eat/Book/Pay docks, Chat/Buy/Captain shortcuts and tests.

Exact transaction-owned Pay routes remain preserved:
`/app/pay/request/:requestId/confirm` and
`/app/pay/payment/:paymentId/{receipt,status,outcome}`. Exact funded Work
opportunity IDs also remain preserved; only the obsolete generic `delivery`
ID is contained.

## Reuse and smallest complete scope

- Add one pure central route-policy function and one reusable truthful recovery
  screen/route; no per-action recovery screen.
- Reuse the existing router authentication/ready gate and current Personal
  Mool/Eat/Book/Work roots.
- Rename the two valid internal Work setup routes to canonical
  `/app/work/workspace/choose` and `/app/work/workspace/proof`, updating only
  active Work callers. Old aliases resolve to recovery.
- Update active Doctor/Book fallback navigation to `/app/book`.
- Keep legacy vertical component behavior testable only through the existing
  `legacyPresentationForTestsOnly` harness; product builds keep it false.

Necessity proof: a redirect straight to another action would silently change
intent, while individual recovery screens would duplicate presentation. One
shared recovery owner is the minimum safe screen/route topology required by
the founder's explicit containment outcome.

## Explicit exclusions

- No deletion of historical screens, sessions, models, services or tests.
- No change to transaction-owned payment/receipt records or exact funded Work
  opportunities.
- No new payment, booking, Tiffin, work, capability, provider or backend fact.
- No edits to legacy Universal presentation or approved HTML references.
- No build, install, OPPO mutation, external-service action, credentials,
  commit, push, deploy, promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01/R03/R06-R11,
complete route/deep-link inventory, existing router and parent vertical owners,
native Flutter directive and 60–75 day reuse lock.

Verification: execution gate; pure positive/negative route-policy tests;
production-router recovery tests for every named family; preserved
transaction-owned Pay and exact Work route tests; full analyze; affected
Eat/Book/Pay/Work/Chat/shared-root regressions; protected-state diff checks;
no build/device action.

Estimated batch impact: **2 days**, within the locked delivery window.
