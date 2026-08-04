# Buy V2 R37 segment-aware Cart contract

Date: 31 July 2026

Founder direction: improve the native Flutter Cart using the current
founder-supplied Zepto screenshots as structural inspiration while making every
surface accurate for Shop, Wholesale and Medicine.

## Preserved authority and boundaries

- R36 remains preserved at local commits `3aa58d1` and `f1ac83d`.
- The protected R35.1 Buy tree remains unchanged until a later explicit
  founder acceptance.
- The protected Social tree, Screens 01–03 and approved HTML are read-only.
- Zepto brand, artwork, copy, prices, offers and implementation are not copied.
- No coupon, bank offer, tip amount, fee, price history, delivery promise,
  provider response or personalization claim may be invented.
- One aggregate Cart remains the owner of Shop, Wholesale and Medicine lines.
- Shop, Wholesale and Medicine recommendations, copy and instructions remain
  independently owned even when shown in the aggregate Cart.

## Founder-reference evidence

The eight newest screenshots were pulled read-only from the connected OPPO and
preserved under:

`artifacts/quality/buy-flutter-r37-cart-relevance-oppo-20260731-40/founder-reference-zepto-cart`

Seven screenshots show Cart structure, product images, coupons, payment
offers, related additions, bill/savings summaries and delivery instructions.
One screenshot shows an address map; it is retained as supplied evidence but
is outside R37 because no new map/provider contract is authorized.

## Segment vocabulary

| Intent | Shop | Wholesale | Medicine |
| --- | --- | --- | --- |
| Cart family | Shop basket | Trade order | Medicine order |
| Item label | Products | Trade packs | Medicines |
| Related additions | Complete your Shop basket | Complete this trade order | More from this care category |
| Special value | Shop offers | Trade offers | Medicine savings |
| Partner | Mool Retail Partner | Mool Trade Partner | Mool Pharmacy Partner |
| Delivery instruction owner | Shop delivery | Trade receiving | Medicine handover |

Mixed Cart headings may name all represented families, but must not apply Shop
language to Wholesale or Medicine.

## Acceptance criteria

### Cart products

1. Every Cart line uses the same approved product/category media resolver as
   catalogue and product detail; no text-only pseudo-image remains.
2. Title, pack, seller/partner, delivery commitment, line amount and accessible
   plus/minus quantity controls remain visible at compact Android/iOS widths.
3. Medicine prescription quantity limits and Wholesale minimum-order behavior
   remain unchanged.
4. The top Cart scope is the single Shop/Wholesale/Medicine family selector.
   Product lines use compact standalone cards and do not repeat large
   per-family order headers in the Cart body.

### Relevant additions and offers

1. Related products come only from the same vertical as their Cart family,
   exclude products already in the Cart and prefer matching Cart categories.
2. Medicine suggestions do not imply diagnosis, treatment or clinical
   personalization. Prescription products retain the existing prescription
   gate.
3. `Deals from` uses the actual minimum current catalogue price of the
   rendered products.
4. `Special offers` may use only existing approved badges or real
   `MRP > price` facts. It may not claim a discount amount when no MRP exists.
5. Shop, Wholesale and Medicine rows remain separately labelled in a mixed
   Cart.

### Coupons and payment offers

1. Coupons and payment offers are separate actions and separate states.
2. Each action opens a full native destination rather than a shallow popup.
   A mixed Cart exposes Shop, Wholesale and Medicine as separate contexts, and
   back navigation returns to the unchanged Cart.
3. A replaceable adapter may return validated, vertical-owned benefits later.
   A vertical eligibility request receives only that vertical's current
   subtotal, never an aggregate mixed-Cart amount.
4. In normal builds, until an approved provider/rule set exists, each vertical
   and benefit tab shows an honest no-eligible-offer state; no fake code, bank,
   percentage, threshold or `Unlocked` state is shown.
5. Unknown, malformed or cross-vertical benefits fail closed.
6. A validated provider-returned benefit may be selected, replaced or removed
   only within its owning vertical and benefit kind.
7. Selection is visible on the native offer screen, in Cart and at Checkout.
   A selected benefit that is no longer returned by its provider fails closed.
8. Selection alone is not redemption. Until an approved monetary quote and
   redemption contract exists, it does not change totals or claim a saving.
9. The offer list owns the viewport. Vertical context and basket facts use a
   dense control header; repeated introductory copy and a persistent bottom
   disclaimer must not displace offer cards.
10. At 320×700 and 140% text, the compact context summary is at most 36 logical
    pixels high, the empty state is at most 100 logical pixels high, and offer
    or empty content begins within 240 logical pixels of the screen top.

For founder-authorized frontend testing, a compile-time device-review adapter
may seed one coupon and one payment-offer card for each of Shop, Wholesale and
Medicine. This exception exists only when `MOOLSOCIAL_DEVICE_REVIEW=true`; it
must contain no monetary value, code, bank, threshold or entitlement claim and
must use the normal typed selection/removal/Checkout UI without changing any
total. The default production adapter remains disconnected and empty.

### Bill and savings

1. Bill summary derives exact family subtotals and Cart total from owned Cart
   lines.
2. Savings are shown only for lines with a positive approved `MRP - price`
   difference and include quantity.
3. No delivery, handling, payment or tip amount is added without an approved
   contract.
4. Delivery-charge qualification remains separate from payment selection.

### Delivery instructions

1. Shop, Wholesale and Medicine expose different relevant instruction sets.
2. Selection is owned per vertical, validated and included in the matching
   Checkout fulfilment group and resulting order.
3. Mixed Cart selection cannot leak one vertical's instruction into another.
4. Reorder does not silently restore a past delivery instruction.

### Tip decision gate

The founder established that a tip may apply only to a genuinely quick
consumer delivery and must never apply to Wholesale/trade fulfilment. That
eligibility boundary is locked.

A working monetary tip still cannot be activated safely until an owned
fulfilment source identifies an order as a quick delivery and the business
contract establishes:

- whether it belongs to each fulfilment group or one aggregate Cart;
- allowed preset/custom amounts and limits;
- allocation to multiple delivery partners;
- payment, cancellation, refund and failed-order behavior; and
- the backend/payout/audit owner.

The production default therefore returns no tip options. The replaceable
policy boundary fails closed, Wholesale always returns no options, and R37
does not simulate an amount, change totals or display a working tip control.

### Saved product decisions

1. Saved ownership is independent for Shop, Wholesale and Medicine even when
   products share a canonical catalogue identity.
2. R37 owns Saved choices for the active authenticated application session.
   It does not write them to an unapproved client store or backend.
3. Saved starts empty for a new session; no product is pre-saved as
   demonstration content.
4. A returning customer can add each eligible Saved choice through that
   product's visible `+`/quantity control, remove one choice, or confirm
   clearing the active vertical while the application session remains active.
5. Productwise add applies current catalogue price and availability facts at
   action time. It never creates an order or bypasses Wholesale verification,
   prescription limits, minimum quantities or Checkout.
6. Prescription medicines remain Saved when they cannot yet be added and the
   prescription owner remains directly reachable.
7. A replaceable store interface is contract-tested but has no production
   adapter. Cross-relaunch retention stays blocked until account ownership,
   data classification, consent, retention, deletion, sign-out and migration
   behavior are approved.
8. The existing Buy data-egress gate must continue to reject direct
   SharedPreferences, database, secure-store or backend persistence.
9. The Saved summary stays compact. Clearing is a secondary, confirmed
   "changed your mind?" action and never removes an existing Cart line.
10. Saved products use one horizontal decision lane. Product-level `Remove`,
    `+`, minus and quantity actions remain visible without requiring a second
    vertical lane, and each action owns only that product.

## Verification

- Focused analysis and Cart/session/widget tests after each logical change.
- Compact Android/iOS viewport and 140% text checks.
- Two complete same-source Buy regressions.
- Approved-lock, brand, founder-reference, customer-copy, interaction,
  backend-boundary, data-egress and protected-Social gates.
- Guarded clean APK with exact candidate marker and checksum-matched OPPO
  installation.
- Connected replay of Shop-only, Wholesale-only, Medicine-only and mixed Cart,
  related-addition, offer-empty-state, summary, instruction, Checkout,
  confirmation and tracking paths.
- No baseline promotion, push, deploy or production acceptance without a later
  explicit founder decision.
