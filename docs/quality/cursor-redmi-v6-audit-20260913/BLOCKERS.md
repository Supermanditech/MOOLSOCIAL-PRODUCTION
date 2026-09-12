# V6 Redmi audit coverage blockers

These are unavailable qualification prerequisites, not closed tickets or automatic product defects. Independent reachable UI testing continues.

## B-001 — authoritative Shopping area search

Observed on matching V6 Redmi APK: numeric query in Shopping area returns “Area search is unavailable right now. Try again shortly.” Retry preserves that state. Evidence 004–006; AREA-002/003. Safe dismissal works. Successful locality/PIN lookup, provider-selected location identity, serviceability and recovery after actual provider restoration remain unverified. Do not substitute the static city list for authoritative nationwide lookup. Owner boundary: location provider and its Buy adapter; exact binding investigation pending.

## B-002 — populated supplier comparison

Turmeric powder 97 / 200 g pack opens Compare prices with the correct identity, but reports other supplier prices unavailable; Refresh comparison preserves this state. Evidence 016–017. `buy_v2_views.dart` `_ProductComparisonSheetState._reload` (line 1677 onward) returns this unavailable state when `session.comparisonSource` or the exact comparison query is missing. The session declares an optional comparison source; determine this artifact's concrete binding before treating it as a service outage.

Blocked descendants: supplier-result cards, price and delivery winner correctness, same-product/variant/pack/quantity eligibility, quantity changes, direct Add and cart retention from comparison, stale-offer refresh, scheduled-slot comparisons, procurement-specific comparison eligibility. The empty/unavailable UI is testable, but none of those positive-result branches is passed. No app code or runtime state will be injected to fabricate the missing authority under this audit goal.

## B-003 — eligible purchase for this product review

Turmeric powder 97 has no eligible delivered purchase in the current review state. Write review and Check again show the explicit eligibility message, evidence 013–014. Positive rating/comment/submission paths for this SKU remain unverified. Existing eligible fixture products may provide independent safe coverage; that search remains pending. Real purchases and public review submission are excluded.

## B-004 — Bulk checkout delivery estimate

Rice 4 / five 25 kg packs reaches Confirm order with retained Work address and ₹8150 after the ₹300 coupon. Delivery is unavailable; Check delivery returns explicit unavailable feedback (088–089). The button is wired to session.refreshCheckoutDeliveryEstimates in buy_v2_views.dart near 7252. Successful authoritative estimate, recovery after provider availability and subsequent eligible order placement are not qualified. Exact runtime provider binding remains to be traced; this is not proof of a service outage or a new customer-facing implementation defect. No order/payment was submitted. Other checkout controls and Back remain independently testable.

## B-005 — live order tracking refresh

MS-NEW-09 opens with last-known preparation status and no live delivery updates. Refresh shows Order updates are unavailable and labels the retained estimate update unavailable (111–112). Positive provider recovery, changing courier/location/ETA and terminal-state transitions are not qualified. Recorded-order UI and safe nested navigation remain testable. No order state was changed and no contact or message sent. Runtime source binding and safe fixture alternatives remain to be reconciled before final coverage disposition.
