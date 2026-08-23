# Global Mool navigation C02 preselection assessment

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C02-PERSONAL-HUB-EAT-RIDE-BOOK-WORK`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome

From the existing Personal chooser and every Eat, Ride, Book and Work
sub-action/deep screen, Mool opens the existing stable Mool hub above the exact
current state. Back restores that state. Retapping selected Mool on the hub
does not open a menu or reset navigation.

## Reuse and duplicate search

The inventory covers `PersonalMoolRootV2`, `MvpActionChoiceRootV2`,
`MoolOutcomeDock`, Eat/Ride/Book/Work sessions and docks, the production
`GoRouter`, and the existing Personal router tests. The source inventory in the
parent audit found no need for a new screen, named route, session, service,
store, backend or provider. C02 removes the unnecessary modal owner and reuses
the existing `/app/mool` route and stack.

Implementation dispositions: `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance`.

New screens: none. New named routes: none. New state/backend/provider owners:
none. Timeline impact: one day maximum, within the founder-locked 60–75-day
window.

## Robustness

Production-router tests must cover each chooser and deep screen, selected-tab
retap, exact stack return, active Ride type/trip, Eat basket, Book booking,
Work opportunity/workspace, error/notice retention, direct-route fallback,
system Back, compact text and reduced motion. The global gate must stop naming
the modal blocker while continuing to reject untouched Social, Buy and shared
child patterns.

## Exclusions and dependencies

No Social, Buy, Chat/shared runtime change; no new presentation owner; no
postponed Pay/Tiffin/Get It Done/Delivery-Onboard-Verify activation; no legacy
presentation mutation; no build/install; no credentials/provider/payment/
funds/Production/commit/push/deploy/promotion. Dependencies are the completed
C01 contract, founder authorization, preserved r60.6 rejection and the locked
Personal/Whirlpool contracts.
