# Global Mool navigation C04 preselection assessment

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C04-BUY-RAIL-BACK`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome

Across Shop, Wholesale, Medicine, Orders and supported nested Buy depth, the
bottom rail remains Buy sub-actions. Tapping Mool pushes the existing stable
Personal hub without clearing search, cart, checkout, order, account, recovery
or session state. Header and Android system Back from the hub restore the exact
unchanged Buy owner. Buy never expands a local main-action palette or routes
through Social as a fallback.

## Reuse and duplicate search

The inventory covers `BuyV2Screen`, `_BuyDock`, `BuyV2Session`, the existing
Buy destination/view/back stack, the production Buy router callback,
`JourneySession.buyExitRoute`, the stable `PersonalMoolRootV2` hub and the
complete protected Buy regression owners. The parent audit proves no new
screen, route, session, service, store, backend, provider or persistent product
state is required. C04 removes `_showPrimaryActions`, keeps the existing four
Buy destinations, and pushes the existing hub through production route
history.

Implementation dispositions: `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance`.

New screens: none. New named routes: none. New backend/provider/payment owners:
none. Timeline impact: one day maximum, within the founder-locked 60–75-day
window.

## Robustness

Production-router tests cover every Buy destination, root and nested
product/cart/checkout/confirmation/tracking/order/account/recovery depth,
search/IME Back ordering, exact session identity and state retention, repeated
Mool/Back sequences, direct-route fallback, compact/scaled text, reduced
motion, semantics and minimum tap targets. Static gates reject
`_showPrimaryActions`, Buy-hosted main-action items and every
`/app/social?openMool=1` fallback. Transaction, cart, order, payment, provider,
accepted presentation and golden owners remain unchanged.

## Exclusions and dependencies

No Chat/shared runtime change; no new presentation owner; no Buy catalogue,
cart, checkout, payment, order, tracking, recovery, provider or backend
behavior; no golden or accepted-reference change; no build/install; no
credentials, payments/funds, live provider message/call, Production, commit,
push, deploy, promotion, screenbook mutation, OPPO uninstall/data clear/
downgrade, or rejected-evidence mutation. Dependencies are completed C01-C03,
founder authorization, the locked global 22-case contract and preserved r60.6
rejection.
