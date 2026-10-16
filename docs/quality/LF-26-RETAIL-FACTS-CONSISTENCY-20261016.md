# LF-26 — Disabled Retail is not available in retail product facts

LF03 supporting correction for the Retailer/Grocery Store owner. Preserve the
approved MVP: Retail plus one Standard wholesale OR Bulk offer on one SKU/Stock.
The current retail facts helper always uses retail price, yet omits retailEnabled
from availability. Its public-product sibling correctly removes Retail listing.
Reproduce their disagreement before changing source; no live consumer is claimed.

Minimum correction: require existing retailEnabled in toBuyPublicFacts orderable
and not-listed branches; document that this helper is retail-only. Retain all
other visibility, incomplete/reviewed-photo, Stock and accepting-orders checks.
Do not add a guessed wholesale facts API, eligibility, listing or publication
authority. Wholesale/Bulk product projection, pricing/MOQ/tiers and Counter sale
must remain available where their own explicit settings permit them.

Acceptance: with valid public media/facts and enabled trade offer, Retail off
means catalogueListing false and retail facts Not listed for customers; trade
classification/pricing and shared Stock/Counter behavior remain unchanged. Retail
on retains existing available/out-of-stock/closed/not-listed precedence. Exercise
both trade types, inventory round trip and existing selling/public handoff tests.
Host fixtures only; no native product setting/Stock/Cart/commerce changes.

Reuse existing model, fixtures and accepted snapshot fields; no new screen, route,
identity, provider contract, policy/registry or framework. Codex remains sole
application writer under the founder's resumed mapped frontend authority. Only
literal LF26 admission/evidence paths in the existing checks; safety unchanged.
Source reload/VM readback on OPPO, not a live public-feed or APK acceptance claim.
Morning founder review and all authoritative publication/quote/provider work stay
pending. This closes only the reproduced producer inconsistency, not full LF03.

## Implemented evidence — 16 October 2026

Three new regression cases failed before correction: both explicit trade types
retained valid listing/price/pack and Counter availability, while disabled Retail
facts incorrectly said Available to order; re-enable/status case reproduced the
same mismatch. All media/completeness prerequisites were checked before failure.

The model correction is two existing-flag conditions and a retail-only comment.
No other schema, status precedence, price, channel, Stock or Counter rule changed.
61 selling-channel/public-handoff/publication/product-content cases passed after
the correction, including the three regressions and inventory round trips.
Focused model/test analysis found no issues. Fixtures remain host-only, not
public records or proof of Catalogue/manual/CSV native saves in this checkpoint.

OPPO source hot reload:1 of3203 libraries,2835ms. Actual VM script readback of
toBuyPublicFacts confirms both retailEnabled availability/not-listed guards are
running. Current existing customer section and its1500 due/4676.90 spent figures
remain visible. No product setting, Apply, Stock, Cart or commercial/provider
operation was performed; no APK build/install. This helper has no current lib
caller other than its definition, so this is producer-contract correctness,
not a visible live public-feed fix or backend integration claim.

Architect context-only review agreed on the bounded correction and required
preservation of trade projection and Counter behavior; those checks pass.
Existing94-owner implementation checks passed; only literal child/evidence
admission added, actual safety predicates/policy/registry unchanged. Founder
acceptance remains pending and all mapped authoritative connections stay open.
