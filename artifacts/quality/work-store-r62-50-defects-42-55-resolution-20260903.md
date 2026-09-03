# Work Store r62.50 — defects 42–55 atomic resolution

Source baseline: `38b584758ecff66c7a82293242d1748f88975e31`

## Equivalent fixes

- **42 — review launch:** the r62.50 OPPO entry point renders an immediate branded preparation frame before the review session finishes starting. This is review-build composition; locked production Splash source is unchanged.
- **43 — Store search:** the native inline Store search scales its complete label instead of ellipsizing it at the OPPO text size.
- **44 — packing:** every product uses a compact 42-pixel packing row and remains visible above `Mark ready`.
- **45 — Settings/Store child Back:** Store operations carry their exact parent. Delivery, Staff and Business record return to Store Settings; Offers and paid work return to Grow. A visible compact Back action is present in the persistent Store header.
- **46 — invoice Chat:** the invoice sheet closes first, then routes on the following frame into Business Chat with invoice, recipient and exact Store return state.
- **47 — customer Chat:** the selected customer is retained in a visible pending-message card. `Find customer` opens People search with the recipient query; selecting an existing thread carries the draft.
- **48 — Repeat basket:** typed order quantities are reused; legacy completed-order summaries are reconstructed only from products still available in the Store catalogue. Unavailable products are not fabricated.
- **49 — Wholesale continuity:** the Store owns one short first-open loader. Its ready state persists, full reinitialization is removed, the Store rail hides for the keyboard, and the embedded Buy rail remains behind the system keyboard.
- **50 — New Sale recovery:** a customer/product draft cannot become a trap. Store Back and destination changes offer `Keep editing` or the destructive `Discard sale` decision before clearing the draft.
- **51 — Storefront tabs:** all five customer-facing contextual labels scale down without clipping.
- **52 — first product visibility:** available products follow the Store preview immediately and remain first-viewport actionable; visibility and trust controls follow the product list.
- **53 — exact public Buy product:** the Work catalogue product is converted through `WorkspaceCatalogueItem.toBuyPublicProduct`, loaded into a bounded public Buy session and opened in the existing Buy product-details UI. Unsupported checkout/backend actions fail closed.
- **54 — funded-work field:** `Experience or qualification` replaces the clipped label while preserving the complete validation requirement.
- **55 — operational headers:** section headings stack at large text/compact width rather than breaking into unbalanced left/right columns.

## Accessibility and copy reinforcement

- Product, customer-order, offer, funded-work, money and quantity fields use a named merged semantic owner while preserving native text editing.
- `Customer saving and terms` replaces the long clipped offer label.
- `Fund and publish to Earn Today` scales to one line at the OPPO text size.

## Local verification

- Focused analyzer: clean across changed Work, Chat and router owners.
- Combined affected suites: **119 active tests passed**, **48 evidence-only tests skipped**.
- Focused r62.50 visual capture run: **24/24 passed**.
- Exact Workspace-product Buy capture: passed separately.
- Capture viewport: `412×915`, text scale `1.4`, Android bottom inset `34`.
- Capture directory: `artifacts/quality/work-store-atomic-r62-50-local-review-20260903`.

## Boundary retained

- The shared Buy scanner defect remains outside defects 42–55 and was not modified.
- No Cursor worktree, Redmi, backend, Firebase, production package or locked production Splash owner was changed.
