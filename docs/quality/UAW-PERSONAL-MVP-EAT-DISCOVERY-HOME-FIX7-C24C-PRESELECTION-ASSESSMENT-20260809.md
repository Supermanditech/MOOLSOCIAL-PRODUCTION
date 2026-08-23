# C24C Eat discovery home preselection assessment — 2026-08-09

## Customer outcome and MVP classification

The personal customer can open Order Food or Book Table into a professional,
location-and-search-led Eat discovery experience and choose a truthful
restaurant using cuisine, price, rating, time, distance and availability
information before the existing order or table flow. This is `mvp_required`:
Eat is an approved launch family and its two active actions must lead directly
to usable product/service outcomes.

## Smallest complete implementation

- Reuse `EatHomeScreen`, `EatTableScreen`, `EatSession`, `EatRestaurant`, the
  existing Eat routes and the C24B shared service-home primitives.
- Recompose the two existing entry screens with one restrained Eat accent,
  location and search first, compact categories/filters, truthful restaurant
  cards and direct Order or Table actions.
- Preserve all current order, basket, table, confirmation, Back, Chat, error
  and recovery owners.
- Keep only Order Food and Book Table exposed; Tiffin remains postponed.

## Reuse and duplicate search

The production inventory contains one `EatHomeScreen`, one `EatTableScreen`,
one `EatSession`, one restaurant model catalogue and the existing
`/app/eat/home`, `/app/eat/order` and `/app/eat/table` route chain. C24B already
provides the necessary responsive search, choice, metadata, card and primary
button primitives. No new screen, route, backend, state owner, gateway,
subaction or build is necessary. The implementation disposition is `reuse`
plus `configuration` of existing presentation owners.

## Explicit exclusions

- no ads, copied reference assets/trade dress, brand copy or promo clutter;
- no Tiffin exposure or speculative Eat feature;
- no fabricated restaurant, availability, payment, order or table state;
- no Social, Buy, Ride, Book or Work business-content change;
- no backend/provider/external-service write, APK build/install, commit, push,
  deploy, promotion or Production action.

## Dependencies, robustness and tests

C24A, C24B and C24B3 are complete; the reference contract, existing Eat
session/routes and protected OPPO r60.22 identity remain authoritative. Focused
tests will prove 320/390/430 widths, 1.4 text scale, 44 px tap semantics,
search/filter behavior, truthful card metadata, direct Order/Table routing,
Back/Chat/connected-MoolSocial continuity and no postponed Tiffin exposure.
The affected Eat vertical slice, analyzer, regression memory, MVP scope,
delivery discipline and protected UI locks must pass. The estimated delivery
impact is one day and remains within the 60–75-day lock.
