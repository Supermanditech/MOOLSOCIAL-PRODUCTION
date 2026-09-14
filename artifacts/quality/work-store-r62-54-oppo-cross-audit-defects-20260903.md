# Work Store r62.54 — OPPO cross-audit defect register

## Reviewed candidate

- OPPO: `CPH2375`, serial `2b3e0f71`
- Package: `com.moolsocial.app.runtime`
- Version: `1.0.0-r62.54-runtime` (`2026090310`)
- APK SHA-256: `AEDFEB40EF2CE202955793A1F53B2FBC683CBECFA1E436A328DE529DCE469167`
- Branch HEAD before this evidence commit: `bae3c891efd9e62aed6de48e359909cf2223bc7f`

## Cross-tested journeys

- Dashboard, Store search, keyboard and search results.
- Global Mool drawer and Store return continuity.
- Global Workspace Chat and Back to the exact Store state.
- Incoming order, packing products, pickup completion and invoice creation.
- Invoice-to-Chat recipient/draft handoff.
- Store Settings and exact child-parent Back behavior.
- New Sale customer/product draft and discard recovery.
- Wholesale search with the keyboard and Store navigation ownership.
- Customer purchase statement, Repeat Basket and customer Chat.
- Money/settlement presentation after a completed sale.
- Grow and funded-work presentation.
- Storefront product, exact public Buy facts and return behavior.

The tested flows above passed except for the open defects below.

## Open defects

### Existing shared scanner defect

The camera still has no visible capture/tap action and no clear automatic-scanning state. Its exact shared Buy owner was not overwritten during this Work batch.

### Defect 56 — native editable accessibility name

OPPO UIAutomator reports Work editable controls as `android.widget.EditText` with an empty `content-desc` and `NAF=true`. Flutter semantic tests pass, but that does not prove the Android native accessibility tree. This requires a platform-accessibility child ticket and TalkBack replay.

Evidence: `artifacts/device/work-store-atomic-r62-53-oppo-review-20260903/oppo-audit/01-new-sale.xml`.

### Defect 57 — direct public Buy return requires two Back actions

Storefront opens the exact Mahadev Fresh Mart product correctly. The first Back moves from product details into the generic Shop catalogue; only the second Back returns to Storefront. Storefront preview entry should return directly to its originating Store context.

Evidence: `artifacts/device/work-store-atomic-r62-53-oppo-review-20260903/oppo-audit/07-exact-public-buy.xml`, `08-buy-return.xml`, and `09-buy-second-return.xml`.

### Defect 58 — finished Store search retains a misleading active term

After the retailer taps the search completion checkmark, results close but `oil` remains in the persistent Store header across dashboard and other Store destinations. Those destinations are not filtered, so the retained term incorrectly implies that a filter is still active. Completing search should clear the term, or the UI must visibly identify and provide a one-tap way to remove an active Store-wide filter.

Evidence: `artifacts/device/work-store-r62-54-cross-audit-20260903/01-store-search-keyboard.png`, `02-global-mool.xml`, and `04-chat-return.xml`.

## Confirmed OPPO passes retained

- `Search your store` is fully visible before search begins.
- Packing products and `Mark ready` do not overlap.
- Repeat Basket reconstructs available products.
- Invoice Chat preserves invoice, value, products and recipient.
- Wholesale exposes no Shop rail above the keyboard.
- Storefront product is available in the first viewport and opens exact Buy facts.
- Mool drawer remains contextual; it does not reopen the retired prototype.
- Global Chat Back restores the Store dashboard and its current state.
