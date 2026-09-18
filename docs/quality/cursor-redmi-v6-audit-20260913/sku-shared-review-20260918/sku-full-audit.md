# Offers SKU grid audit

Promotional card approved; SKU grid and toolbar unapproved. Redmi work is on hold.

## SKU-SIZE-01 — Card bounds exceed actual content
The grid assigns every card the tallest measured height in its row. A retailer card inherits the wholesaler minimum-order and delivery-line height, leaving a large empty rectangle beneath Add. The manual measurement also budgets more spacing than the actual compact card. Fix Offers cards to take their natural content height, keeping equal column widths and row reading order. Do not truncate provider facts.

## SKU-SIZE-02 — Quantity changes can reserve unrelated space
Row height also uses the largest quantity control in the row. A single stacked quantity can add space to adjacent cards; sizing must instead follow each card's rendered Add/quantity state and shrink after removal. Verify Add, increment and removal at narrow widths and enlarged text.

## Existing ticket verification (no duplicate tickets)
OFFERS-02 owns media fit: retain square contained photos, illustration/fallback disclosure and Save/badge clearance. Verify portrait, landscape and square photos plus unavailable media. OFFERS-03 owns toolbar; keep category left, source selection centre and Saved/filter right. Its approval remains pending.

Acceptance: no excess blank card area beneath action, no clipping/overlap, full metadata and minimum-order facts, normal/enlarged text, local captures for founder review before Redmi.

## Implementation and local validation
Both sizing tickets implemented in finite and paged Offers. Cards shrink-wrap their own content; row top alignment and reading order remain intact. Short cards end within 4px of their own action. Natural height accounts for quantity growth and shrinks after removal without changing neighbour height. 112 media and interaction tests passed, followed by six strengthened visual/control cases at 320/390/844 widths and 1x/2x text. Analysis passed. Current captures: offers-sku-audit-v9-final. Status: implemented, local tests passed, founder visual approval pending. Redmi work remains on hold.

## Expanded shared-SKU audit
Founder requests the same inspection and fixes across all applicable SKU surfaces. SKU-SIZE-03: the row Wrap still aligns subsequent products below the tallest neighbour, leaving inter-row gaps; replace vertical discovery grids with independent columns at a consistent 10px gap. Apply shared content sizing and square media to paged Shop/Wholesale/Medicine/Offers, finite Store/catalogue, Saved and reused SKU discovery grids/search. Preserve horizontal discovery rails as horizontal rails, with compact content-sized cards and enough media space. Verify all affected surfaces, full metadata, scroll/paging, Add/quantity/Save, narrow and enlarged text. No Redmi work before visual approval.

## Shared implementation complete — approval pending
SKU-SIZE-03 now stacks each vertical column independently with a 10px gap; the next product follows the preceding card in its own column. Applied to paged Shop/Wholesale/Medicine/Offers and shared finite Store, Saved, catalogue and search-result grids. Ordinal semantics preserve product ordering. Horizontal discovery rails remain horizontal; their cards fit content and reserve the enlarged media area.

The existing media ticket also covers featured cards: their previous expanded photo region now has a measured area, with Save/badge and Add/quantity controls kept separate from the photo. Badge rendering uses the same measurements as its reserved space. Square contained photos, disclosure/fallback states, full product identity, provider/minimum-order facts and touch targets are preserved.

Validation: the combined 267-case media, Offers, responsive and founder regression run had 261 passing cases and six assertions for the obsolete equal-row traversal. These six were updated to check visual row positions and independent-column spacing; all 18 featured-layout cases then passed, including added photo/Save/badge clearance checks. A 56-case targeted media/featured run passed. The 24-case shared Shop/Wholesale/Medicine/Store/Saved/search-layout matrix passed at 320/390 widths and 1x/2x text. All 12 paged Offers/Shop/Wholesale journeys passed after test expectations were aligned with existing adjacent-page prefetch and nested-carousel scrolling. Four scoped Cart-return tests passed. Counts across runs overlap and are not additional tickets. Analysis passed.

Current full Offers captures: sku-shared-review-20260918/sku-full-audit-v12. Other surfaces are actual shared Flutter grid component previews in sku-shared-surfaces-v12-final; they are not full app-page screenshots. Search preview exercises the reused result grid; actual search/rotation/swipe restoration is covered by the founder regression tests.

Only the promotional offer card has founder approval. Shared SKU sizing/media changes and Offers toolbar remain pending visual approval. No APK was built or installed; Redmi work remains on hold.
