# Cursor Buy MVP close — Ticket 14

Date: 2 September 2026  
Ticket: `UAW-CURSOR-BUY-MVP-CLOSE-T14-20260902`  
Founder state: approved in chat before execution  
Lane: Cursor UI  
Source baseline: `958e767e6f910e40b8f475d99173011f0f07ea78`

## Customer outcome

The customer can place an order without a false immediate supplier confirmation, continue browsing products inside one store without repeated route rebuilding, always understand what entered the Cart, and browse a clearly organized Shop or Wholesale catalogue without duplicate screens or carts.

## MVP classification

The parent is `mvp_required`. Child 14A prevents a false fulfilment promise; child 14B fixes a confirmed supported-journey navigation and Cart-feedback defect. Child 14C is a founder-directed `mvp_supporting` organization change implemented inside the same existing catalogue owners.

## Minimum complete scope

### 14A — supplier assignment and recovery

- Reuse Confirmation, Orders and Tracking.
- Present customer-safe awaiting supplier, reassignment, accepted, no-supplier and payment-status recovery states.
- Preserve the last authoritative state through refresh, relaunch and offline recovery.
- Never fabricate acceptance, refund completion, live coordinates or supplier identity.

### 14B — store browse and Cart continuity

- Keep the store catalogue available while customers inspect several products.
- Return from a store product to the same store and prior browsing position.
- Show immediate add confirmation and a visible Cart summary/action on store product and store catalogue states.
- Reuse the existing product grid, product page, session and Cart.

### 14C — existing-surface catalogue organization

- Shop selector: `Quick delivery` and `Courier`.
- Wholesale selector: `Wholesale` and `Bulk`.
- Filter existing products using current fulfilment and pack/MOQ facts.
- Preserve one Cart, one search/catalogue owner, existing filters and exact back navigation.

## Explicit exclusions

- No new top-level screen, route, catalogue owner or Cart.
- No Medicine/Care presentation or data change.
- No supplier-selection, timer, inventory, payment, refund, courier or Chat backend implementation.
- No live GPS/map, Admin workspace, provider workspace or store-release action.
- No broad marketplace redesign, speculative personalization or duplicate retail/wholesale applications.

## Dependencies and backend boundary

Cursor owns the native presentation, state contract, tap wiring, navigation and focused tests. Codex backend later supplies authoritative supplier-attempt, payment, inventory and recovery events only after founder UI acceptance. Existing product fulfilment, pack, MOQ and delivery-promise fields are reused for the selectors.

## Test and evidence plan

- Focused session and widget coverage for every assignment and recovery state.
- Add-to-Cart acknowledgement and persistent Cart action from a store product.
- Multi-product store browsing with exact store/scroll return.
- Shop and Wholesale selector filtering, Cart preservation and back navigation.
- Compact Android, larger Android/iOS, large text, keyboard/inset and professional-copy checks.
- Two complete Buy regressions before any later founder-authorized APK.
- Redmi review only after a separate machine-gated build authorization; OPPO remains untouched.

## Robustness and reuse assessment

Existing `BuyV2Session`, product/store catalogue, product page, Cart, Confirmation, Orders and Tracking owners are sufficient. The only new implementation is bounded state and filtering behavior within those owners. No new route, screen or backend owner is necessary. Estimated implementation impact is two days and remains within the locked 60–75-day delivery window.
