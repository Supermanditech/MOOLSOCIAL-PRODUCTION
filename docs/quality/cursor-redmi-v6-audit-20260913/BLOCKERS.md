# V6 Redmi audit coverage blockers

These are unavailable qualification prerequisites, not closed tickets or automatic product defects. Independent reachable UI testing continues.

## B-001 — authoritative Shopping area search

Observed on matching V6 Redmi APK: numeric query in Shopping area returns “Area search is unavailable right now. Try again shortly.” Retry preserves that state. Evidence 004–006; AREA-002/003. Safe dismissal works. Successful locality/PIN lookup, provider-selected location identity, serviceability and recovery after actual provider restoration remain unverified. Do not substitute the static city list for authoritative nationwide lookup. Owner boundary: location provider and its Buy adapter; exact binding investigation pending.

## B-002 — populated supplier comparison

Turmeric powder 97 / 200 g pack opens Compare prices with the correct identity, but reports other supplier prices unavailable; Refresh comparison preserves this state. Evidence 016–017. `buy_v2_views.dart` `_ProductComparisonSheetState._reload` (line 1677 onward) returns this unavailable state when `session.comparisonSource` or the exact comparison query is missing. The session declares an optional comparison source; determine this artifact's concrete binding before treating it as a service outage.

Blocked descendants: supplier-result cards, price and delivery winner correctness, same-product/variant/pack/quantity eligibility, quantity changes, direct Add and cart retention from comparison, stale-offer refresh, scheduled-slot comparisons, procurement-specific comparison eligibility. The empty/unavailable UI is testable, but none of those positive-result branches is passed. No app code or runtime state will be injected to fabricate the missing authority under this audit goal.

## B-003 — eligible purchase for this product review

Turmeric powder 97 has no eligible delivered purchase in the current review state. Write review and Check again show the explicit eligibility message, evidence 013–014. Positive rating/comment/submission paths for this SKU remain unverified. Existing eligible fixture products may provide independent safe coverage; that search remains pending. Real purchases and public review submission are excluded.
