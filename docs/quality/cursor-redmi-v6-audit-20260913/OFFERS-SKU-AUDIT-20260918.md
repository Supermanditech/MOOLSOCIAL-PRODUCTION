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
