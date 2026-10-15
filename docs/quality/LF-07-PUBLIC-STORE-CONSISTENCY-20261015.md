# LF-07 — Public and Visit Store consistency

Founder accepted b0759ff6 safe-setting checkpoint and approved Batch07. Settings
restart persistence/sync/live eligibility remain unfinished, not waived.

## Bounded MVP outcome

One Store's public catalogue remains isolated by exact identity; descriptive
location never becomes verification from product origin or generic trust readiness.
Existing Cart scope/totals/navigation are preserved and visibly identified. Reuse
current screens/contracts, explicit Other stores and comparison. No redesign,
backend, APK, fabricated runtime data or local verification authority.

## Demonstrated source risks and correction plan

- Public truth panel falls back to product.origin and infers Address confirmed
  from trust.ready. The trust contract has no address-verification fact. Remove
  that inference, keep valid scoped descriptive location, show missing honestly.
- Compact Cart control uses aggregate or destination totals, not selected Store
  subtotal. Label actual all-Store/channel scope; never remove other Store lines.
- Recheck existing Store-scoped search/pagination/refresh regressions and actual
  caller route. Failed/empty pages must not broaden to marketplace. Deliberate
  comparison/Other stores remain available.

## Acceptance

Focused failing-before tests for false address confirmation/origin fallback and
ambiguous Cart scope; normal/200% compact UI; existing affected browse/Cart return,
Store membership and unavailable/retry checks. Hot-reload OPPO, inspect actual
public screens without altering saved Cart or submitting commerce; founder review
before Batch08. Host fixtures are not real publication/provider acceptance.

## Dependencies

Test-authoring incident: first LF07 run did not compile because a new assertion
guessed cartQuantityFor rather than the existing quantityFor API. Correct the
fixture API only, inspect the existing signature before retry, and retain the
same quantity/Cart-preservation assertion. This is not an application failure.
The first matching-location fixture also assumed legacy s-eggs had a Store ID;
it does not. An explicit isolated host-fixture Store ID fixes that setup, without
changing runtime IDs. Before correction, valid tests reproduced the false address
claim and missing Cart-scope labels. No failed setup is counted as application proof.

Live public publication/readback, address verification, source revisions,
serviceability, campaign/quote/benefit providers and public event tracking remain
unimplemented where absent. Session settings durability remains held under LF06.

## Implemented checkpoint / verification

The public truth panel now accepts the existing public Store record, checks exact
Store ID and uses area/address descriptively. Missing/foreign Store records show
Store location unavailable. Generic trust readiness and product origin never
become confirmed location; removed the geography-specific origin/destination
parser. The alternate full-catalogue header also no longer substitutes origin for
an absent Store address. Existing product-origin facts remain elsewhere as facts.

The Cart control visibly/semantically labels All Cart items or the actual commerce
mode/all sellers; existing aggregate/destination totals, quantities, callbacks and
saved state are unchanged. Label dimensions join existing width/height measurement.
No new contract/verification flag, Cart scoping engine, Store form, route or backend.

74 distinct selected host cases passed: LF07 new14, R5 catalogue session/recovery14,
published catalogue22, Store-first UI8, Offers UI4, money layout8 (through100Cr,
normal/200%), existing Add/Cart return1, compact public truth1, compact touch1 and
Storefront1. Final LF07 rerun14 passed after alternate-header fallback correction.
Analysis of changed app/test files: no issues. Narrow exact LF07 admission only;
existing safety/secret/history checks retained, no policy/registry changes.

OPPO hot reload3664ms then final header correction5965ms, no APK. Through actual
UI: existing soap detail → Visit Store → Store details expand/close → Cart → Back;
reviewed exact Store name/address and existing explicit Other stores. Cart retained
one soap₹164; existing payment-review lock was preserved and not operated. Native
only normal portrait/single Store/current review-source data; host tests cover
missing/foreign records,200%, mixed/mode totals and paging/provider failure shapes.
No injected runtime data, Stock/orders/invoices/payments or publication writes.
Task outputs/lf07-visit-store.png and lf07-store-details-expanded.png retain the
native views. Failed fresh accessibility captures were not reused for taps; fresh
screenshots/unique available labels were used instead. No live verification claim.

Context-only architect review found no concrete stop concern for this bounded
truthfulness checkpoint; it is not independent code/native or provider acceptance.
Founder review pending before Batch08. The larger two-way goal remains active.
