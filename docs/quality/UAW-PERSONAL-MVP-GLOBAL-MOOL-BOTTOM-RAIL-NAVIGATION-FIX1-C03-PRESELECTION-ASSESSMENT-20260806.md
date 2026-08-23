# Global Mool navigation C03 preselection assessment

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C03-SOCIAL-RAIL-BACK`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome

On every production Social tab and content depth, the bottom rail remains a
Social sub-action rail. Tapping Mool pushes the existing stable Personal Mool
hub; Back returns to the exact Social tab, feed position and content state.
Back closes an active video/content depth first, then follows normal route
history. Mool never toggles a Social-hosted main-action ribbon.

## Reuse and duplicate search

The inventory covers `SocialUniversalV2`, `Screen04CapabilityRail`, the
existing Social tab/card/video state, `MoolOutcomeDock` navigation language,
the production `/app/social` and `/app/mool` router owners, and protected
Social provider/runtime tests. The parent audit found no need for a new screen,
route, session, service, store, backend or provider. C03 removes the duplicated
`_moolOpen` presentation state and wires the existing Mool callback to the
existing hub using route-stack history.

Implementation dispositions: `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance`.

New screens: none. New named routes: none. New state/backend/provider owners:
none. Timeline impact: one day maximum, within the founder-locked 60–75-day
window.

## Robustness

Production-router tests must cover all Social tabs, active card/action sheets,
active video depth, exact Back ordering, root route history, repeated Mool
taps, compact/scaled text, reduced motion, semantics, and provider-state
retention. Static and widget gates must reject `_moolOpen`, `initialMoolOpen`,
and Social rail `moolOpen`/main-action projection. Protected YouTube/provider
behavior, accepted presentation references and goldens remain unchanged.

## Exclusions and dependencies

No Buy, Chat/shared runtime change; no new presentation owner; no Social
provider activation or live provider call/message; no content/compliance claim,
golden or accepted-reference change; no build/install; no credentials,
payments/funds, Production, commit, push, deploy, promotion, screenbook
mutation, OPPO uninstall/data clear/downgrade, or rejected-evidence mutation.
Dependencies are completed C01-C02, founder authorization, the locked global
22-case contract and preserved r60.6 rejection.
