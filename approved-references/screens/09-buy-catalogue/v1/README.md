# Screen 09 Buy catalogue — founder-approved HTML slice v1

This immutable reference freezes the founder-approved Retail and Wholesale
catalogue slice on 27 July 2026. Its authority is intentionally limited to the
category rail, product grid, inline quantity controls and bottom navigation.

Retail and Wholesale share one canonical 84-product catalogue while applying
separate context taxonomies, packs, prices, quantities and fulfilment
information. Each context exposes 34 definitive product categories. The
compact left rail shows `All`, five context-priority or selected categories and
`More`. `More` reveals all 34 context categories plus Medicine inside a fixed
420 px scroll viewport. Products remain visible and purchasable beside the
rail; no category modal, dimmed backdrop or detached category page is allowed.

Selecting a category updates the exact product result on the same screen,
collapses the rail and keeps the selected category visible. Categories have at
least two exact products. A short exact result may add two complementary
products only under a separate customer-facing heading and without changing
the category count.

`ADD` changes in place to a 44 px minimum minus, quantity and plus control.
Retail begins at one pack. Wholesale begins at the selected pack MOQ. Changes
are reflected immediately in the Retail basket or Wholesale bulk-order pill.
The fixed bottom navigation is Mool, Buy, Orders and Chat.

The reference images capture the accepted compact and expanded Retail and
Wholesale states at 390 × 844. Product detail, pack and seller decisions,
basket/bulk-order review, checkout, payment, confirmation, tracking, Medicine,
native Flutter and deployment are outside this approval. Native Buy
implementation remains blocked until the complete connected Buy HTML journey
has passed its founder gate.
