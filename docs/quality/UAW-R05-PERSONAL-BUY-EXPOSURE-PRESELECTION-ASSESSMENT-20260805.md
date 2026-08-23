# UAW-R05 preselection robustness/reuse assessment and disclosure

Date: 5 August 2026
Ticket: `UAW-R05-PERSONAL-BUY-EXPOSURE`
State: `ASSESSED_AND_SELECTED_FOR_TEST_ONLY_ACCEPTANCE`

## Customer outcome and classification

A Personal user reaches the accepted native Buy V2 owner from Mool, sees
exactly Shop, Wholesale, Medicine and Orders as the persistent Buy choices,
never falls into the legacy Buy shell, and can return safely to Mool.

Classification: `mvp_required`. Buy is a primary revenue and fulfilment action;
truthful entry into the founder-approved FIX7 owner is required for launch.

## Reuse and duplicate inventory

Existing owners already implement the outcome:

- `BuyV2Destination` contains exactly `shop`, `wholesale`, `medicine` and
  `orders`;
- `BuyV2Screen` and its persistent dock expose all four in one native owner;
- the production router maps `/app/buy` and historical Buy links to V2 rather
  than the legacy shell;
- R03's Mool root points Buy to `/app/buy?return=/app/mool`; and
- `JourneySession.buyExitRoute` allowlists only the exact Mool return while
  rejecting arbitrary requested returns.

Existing `buy_v2_router_test.dart`, `buy_v2_screen_test.dart`,
`buy_route_continuity_test.dart` and the R03 focused route test already cover
the required entry, exact dock, deep-link containment and return behavior.
Adding another screen, route, destination enum, session or test file would be
duplicate work.

Implementation disposition: `test_only_acceptance` plus `reuse`. No production
runtime or protected Buy presentation write is necessary for R05.

## Smallest complete scope

1. Re-run the existing production-router tests proving native V2 entry and
   legacy-shell absence.
2. Re-run the existing exact persistent-dock test for Shop, Wholesale,
   Medicine and Orders.
3. Re-run R03 Mool-to-Buy-to-Mool continuity and the full Buy route regression.
4. Preserve FIX7 source/APK identities and the known protected-baseline
   fail-closed state without rebaselining.

## Explicit exclusions

- No Buy presentation, catalogue, cart, order, fulfilment or backend change.
- No new screen, route, enum, controller, test duplicate or reference.
- No provider/payment/funds/Production action, build, install, OPPO mutation,
  commit, push, deployment or promotion.

## Dependencies and evidence

- Founder-approved FIX7 runtime and accepted Buy V2 owner.
- Completed R03 Mool root and exact safe-return adapter.
- Parent manifest SHA-256
  `45D765390EA6B2D94F334CB4F5B2AB67162657A447B220A10650EB7621DB34A8`.

Test/evidence plan: production router suite, exact persistent-dock test, R03
focused route suite, Buy route-continuity regression, focused analysis and
protected identity disposition. Timeline impact: one engineering day or less;
the ticket remains inside the 60-75-day lock.
