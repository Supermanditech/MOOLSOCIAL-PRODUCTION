# Redmi r66.29 device audit â€” 18 September 2026

Status: BOUNDED DEVICE AUDIT RECORDED; NOT DEVICE QUALIFIED. Founder requested real on-device testing and defect registration before implementation. No new app-source changes during this audit.

Build: UAW-CURSOR-SKU-OFFERS-20260918; 1.0.0-r66.29-cursorreview (2026091801); source HEAD eb0bb45c, approved app source 6f0632ad. Device: Redmi 23106RN0DA / TG8HCYTGGQT885OF. In-place upgrade succeeded, first install date preserved. Installed APK SHA256 matches 56208DD41D83685C4DCBF9D37A7BA153AF344E2F76CA53FC4E6B082718870665. Review fixture runtime; no live commerce qualification.

## SKU-DEVICE-01 â€” Oversized quantity box after Add

OPEN, founder confirmed. Reproduced on Offers, Shop and Wholesale in portrait, default font scale. Add replaces the compact button with two tall rows: quantity above minus/plus, pushing the next SKU down. Shared _QuantityStepper reserves 44 logical pixels for the editable number and another 44 for buttons because narrow cards fail the 132-pixel horizontal threshold. Store also reproduced on device (store-top.png); apply the shared fix across all four surfaces. Fix must preserve independent column flow, correct hit targets, edit access, long quantities, text scaling and minimum-order rules. Evidence: founder-offers-add-to-cart-current.png, shop-facewash-added.png (actual visible product is Fresh set curd; capture filename predates settled screen), wholesale-added-minimum.png.

## SKU-DEVICE-02 â€” Save/badge header pushes the photo downward

OPEN, founder confirmed across Shop, Wholesale, Offers and Store. Save and green Best cost/Lowest/etc. badge reserve excessive header space before the product image. Keep the product photo at the top and reduce control/badge visual bulk, without obscuring the product or losing save/badge meaning. Review actual product images, category illustrations, missing-image fallback, scaled text and next-card packing. Evidence: offers-ready.png, wholesale-start.png, loaded.png; Store confirmed in store-top.png.

## Passing functional observations (not a qualification claim)

- Offers promotional swipe changed 1/40 to 2/40, retained next-card preview.
- Offers independent columns start the next card immediately after its own preceding card, including differing seller/minimum-order content.
- Wholesale Add fresh tomatoes starts at minimum two packs: 2 Ã— 580 = 1160. Plus gives three; tapping quantity opens editor at three.
- Editing Wholesale quantity to one is rejected with Minimum order: 2 packs. Editing to four succeeds; cart shows four packs and Wholesale subtotal 2320. Existing Shop subtotal 145 remains separate; aggregate subtotal 2465.
- Some initial actions were concurrent with founder device use; those ambiguous transitions are not counted as passes. Later checks use a stable screen before each action.

Further checks pending: return navigation, Saved/search, whole-grid paging, rotation, Store, app log review. Floating cart overlap is an audit observation, not yet a separately confirmed defect; investigate existing drag/avoidance behavior before deduplication.

Root cause of SKU-DEVICE-02: compact aligned SKU calls _ProductVisual(minimumControlExtent: 48, squarePhoto: true). _compactProductVisualLayout reserves the full Save touch target above the square image. This is shared card behavior, not missing image padding in individual assets. Source diagnosis confirmed; app code unchanged during registration.

Log review through 20:51 IST: no Flutter overflow, unhandled Flutter exception or fatal app crash observed. One startup MIUI PerfDebugMonitor file-not-found warning is recorded; app startup completed. Further device scenarios remain pending, including a reliable Cart return capture (last sequence overlapped scrolling and is not claimed passed).

## OFFERS-DEVICE-03 - Large-text publisher/title word breaks

OPEN, newly observed on device; accessibility follow-up to OFFERS-01/03, not a new feature. At Android font_scale 2.0, publisher controls split Suppliers and MoolSocial inside words; promotional title splits tomatoes and the card grows excessively tall. Evidence: offers-large-text.png. Keep readable whole words and usable media/action proportions at large text. Preserve the approved default-scale promo as the baseline. No Flutter overflow emitted: visual/usability failure, not a crash.

## Completed bounded device scenarios and limits

- Offers rail advances with following-card preview. Supplier/MoolSocial selection changes results. MoolSocial fixture has no published items: truthful empty state verified; populated live publication not qualified.
- Offers Fruits & vegetables category changes visible items; publisher filter opens; Saved opens the existing shared saved-product sheet. Evidence: offers-category-fruit.png, offers-filter.png, offers-saved-sheet.png.
- Wholesale Save changes badge 0 to 1; Saved displays the product with retained quantity4; Remove returns count0. Original Shop saved item remains. Evidence: wholesale-save-toggle.png, wholesale-saved-confirmed.png, wholesale-saved-removed.png.
- Search tomato returns matching tomato/ketchup entries; keyboard dismissal settles to full viewport. Early transitional blank capture is not a persistent defect. C06 delayed-network indicator timing retains prior local test coverage but was not conclusively observed in this fast device fixture.
- Android Back from Wholesale Cart returns to catalogue with quantity4 intact: cart-back.png. Product detail opens; Visit store opens Store products; Store scrolls with independent columns. No checkout/order submitted.
- Shop horizontal whole-grid swipe advances to barcode labels/copier paper: shop-grid-swipe.png. Prior local tests cover mid-drag preview and cancellation; device confirms completed paging.
- Portrait/landscape/back remains Shop without opening Mool: shop-landscape.png. Normal rotation checked, not every held-finger timing.
- Store confirms both shared defects: tall quantity1 box and header gap above image. store-top.png and store-column-flow.png.
- Log through20:58 IST: no observed Flutter overflow, unhandled Flutter exception or fatal app crash. Existing MIUI startup warning documented above.
- Restored font_scale1.0, user_rotation0, accelerometer_rotation1, verified via ADB. Fixture cart retains founder Shop3/145 plus audit Wholesale4/2320 (aggregate2465) for reproduction; no purchase. Original Shop Saved1 retained; temporary Wholesale save removed.

Disposition: THREE distinct visual defects registered. No new app code during this audit phase. r66.29 NOT qualified because defects remain open. Floating mini-cart overlaps photos while avoiding registered text/actions; existing movable/avoidance design is not counted as a fourth confirmed ticket. This is a bounded requested-screen UI audit, not exhaustive app/backend/live-data/release-performance qualification. Implementation and successor retest remain pending.
