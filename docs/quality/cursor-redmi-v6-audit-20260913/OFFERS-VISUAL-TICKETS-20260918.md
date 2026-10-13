# Offers visual correction tickets — 18 September 2026

Approved prior scope: C04, C06 and C07 at 73b2cf75. Founder approved all three local visuals. Device upgrade is held while these new Offers findings are addressed, per the founder's request. Connected review device is Redmi 23106RN0DA, existing Cursor Review r66.28.

## OFFERS-01 — Cinematic published-offer cards
Replace the text-only single panel and arrow stepping with horizontally swipable, image-led cards and a visible neighbouring card. Separate supplier and MoolSocial publications using the existing publisher identity. Retain exact product, publisher, price, pack, minimum quantity, expiry and product-return selection. Use existing admitted product imagery. Real promotional video ingestion/playback is not supported by the current publication model and is not claimed by this UI correction. Pending founder choice: swipe only or automatic advancement.

## OFFERS-02 — Aligned SKU media
Occurrence linked to existing SKU-M01 media/control separation, rather than reopening its already qualified Shop/Saved scope. Redmi screenshot shows inconsistent photo/title positions across a mixed Shop/Wholesale Offers row. Source cause: the compact card expands media to consume remaining equal-row height, which varies with the metadata below it. Offers must use a consistent, bounded photo area; preserve full photo fit, aspect ratio, illustration disclosure, Save clearance and accessible text. Verify mixed metadata, portrait/landscape images, absent/broken media, normal/enlarged text and quantity changes.

## OFFERS-03 — Shop-aligned toolbar
Replace the large Offers heading and right-aligned category button with Shop's compact chrome: category at left, current selection in the centre, Saved and filter actions at right. Category and publisher filters must affect the real Offers source and retain state on product return. Preserve search, address/profile, cart and navigation.

Acceptance: local Flutter interactions, real rendered captures and founder review before the combined Redmi review upgrade. Device tests and integration remain pending. No publishing backend or admin authoring interface is added by these presentation tickets.

Local implementation and validation are recorded in offers-local-review-20260918/offers-review.md. Scope approved; new visual approval and Redmi qualification pending. Swipe-only is the current motion choice. No fourth ticket was added.

Founder requested shorter cards; OFFERS-01 refined to content-measured compact height. Current visual revision is offers-review-compact-v1; approval remains pending.

Current founder approval: OFFERS-01 promotional card only. OFFERS-02 revised square SKU media and OFFERS-03 toolbar await local visual approval. Redmi work remains on hold. Current visuals: offers-sku-fit-v8-final.
