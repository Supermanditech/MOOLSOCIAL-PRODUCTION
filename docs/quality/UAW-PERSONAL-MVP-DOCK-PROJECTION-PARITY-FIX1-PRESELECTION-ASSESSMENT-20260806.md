# UAW Personal MVP dock projection parity FIX1 preselection assessment

Date: 6 August 2026
Ticket/candidate: `UAW-PERSONAL-MVP-DOCK-PROJECTION-PARITY-FIX1`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user opening Mool from the real Social/Universal shell sees exactly
Social, Buy, Eat, Ride, Book and Work plus global Chat. Each world reaches the
already-owned native Personal destination, and the visible choices match the
locked MVP projection. Standalone Pay, Tiffin, Get It Done, Delivery, Onboard
and Verify are not exposed by the shared dock.

Saved OPPO XML from the cumulative r60.1 qualification proved that the real
shared dock still showed the superseded broad projection even though the direct
Personal roots already implement the locked projection. Correcting this launch
path is therefore `mvp_required`.

## Reuse inventory and smallest complete scope

- Reuse `screen04Worlds`, `Screen04CapabilityRail` and `SocialUniversalV2`,
  which own the shared live dock.
- Reuse the existing `/app/buy`, `/app/eat`, `/app/ride`, `/app/book` and
  `/app/work` roots and their existing route/session owners.
- Make the shared dock configuration match
  `config/mvp-personal-action-projection-v1.json` exactly.
- Add only a thin world-ID-to-existing-root routing adapter for non-Social
  worlds. Social remains in its protected V2 owner.
- Add deterministic tests against the real shared dock, direct roots and
  removed-action containment; run affected Personal, protected Social and Buy
  regressions before any build.

## Duplicate search and necessity proof

No new screen, route, state owner, service or backend owner is needed. The
canonical Personal roots already exist and pass their ticket contracts. The
defect exists because `SocialUniversalV2._selectWorld` routed only Buy to its
canonical root and otherwise mutated the old in-shell world state. Updating the
one shared projection plus that adapter is smaller and safer than duplicating
the destination screens or navigation family.

## Explicit exclusions

- No Social Shorts/Videos provider activation, YouTube compliance claim or
  protected Social content/presentation redesign.
- No new Buy, Eat, Ride, Book, Work, payment or workspace journey owner.
- No screenbook, locked Screens 01-03, accepted Buy baseline or manifest edit.
- No OPPO uninstall, data clear, downgrade or protected FIX7 evidence change.
- No credentials, live provider message/call, payment, funds, Production write,
  commit, push, deployment or promotion.

## Dependencies and verification

Dependencies: founder direction that this defect be fixed to the new MVP plan;
locked projection manifest; existing R03/R05-R10 Personal roots; protected
Social and Buy owners; current remediation branch/HEAD; MVP scope, delivery,
APK and device gates.

Verification: exact source projection; real-dock root/action assertions;
canonical one-tap navigation; removed-action absence; legacy/deep-link safe
containment; Social non-activation; accessibility/text-scale/reduced-motion
fitment; two affected Personal runs; two protected Buy regressions; full
analysis and qualified broad regressions; one newly authorized candidate build;
signature/badging/version/hash; in-place OPPO install only after all host gates;
founder-review parking on the corrected dock.

Estimated impact: **1 day**, inside the founder-locked 60-75-day window.
