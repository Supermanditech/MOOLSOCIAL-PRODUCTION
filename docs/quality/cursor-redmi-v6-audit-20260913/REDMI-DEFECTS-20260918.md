# Redmi r66.29 device audit â€” 18 September 2026

Status: IN PROGRESS, NOT DEVICE QUALIFIED. Founder requested real on-device testing and defect registration before implementation. No new app-source changes during this audit.

Build: UAW-CURSOR-SKU-OFFERS-20260918; 1.0.0-r66.29-cursorreview (2026091801); source HEAD eb0bb45c, approved app source 6f0632ad. Device: Redmi 23106RN0DA / TG8HCYTGGQT885OF. In-place upgrade succeeded, first install date preserved. Installed APK SHA256 matches 56208DD41D83685C4DCBF9D37A7BA153AF344E2F76CA53FC4E6B082718870665. Review fixture runtime; no live commerce qualification.

## SKU-DEVICE-01 â€” Oversized quantity box after Add

OPEN, founder confirmed. Reproduced on Offers, Shop and Wholesale in portrait, default font scale. Add replaces the compact button with two tall rows: quantity above minus/plus, pushing the next SKU down. Shared _QuantityStepper reserves 44 logical pixels for the editable number and another 44 for buttons because narrow cards fail the 132-pixel horizontal threshold. Audit Store/shared callers too. Fix must preserve independent column flow, correct hit targets, edit access, long quantities, text scaling and minimum-order rules. Evidence: founder-offers-add-to-cart-current.png, shop-facewash-added.png (actual visible product is Fresh set curd; capture filename predates settled screen), wholesale-added-minimum.png.

## SKU-DEVICE-02 â€” Save/badge header pushes the photo downward

OPEN, founder confirmed across Shop, Wholesale, Offers and Store. Save and green Best cost/Lowest/etc. badge reserve excessive header space before the product image. Keep the product photo at the top and reduce control/badge visual bulk, without obscuring the product or losing save/badge meaning. Review actual product images, category illustrations, missing-image fallback, scaled text and next-card packing. Evidence: offers-ready.png, wholesale-start.png, loaded.png; Store device verification pending.

## Passing functional observations (not a qualification claim)

- Offers promotional swipe changed 1/40 to 2/40, retained next-card preview.
- Offers independent columns start the next card immediately after its own preceding card, including differing seller/minimum-order content.
- Wholesale Add fresh tomatoes starts at minimum two packs: 2 Ã— 580 = 1160. Plus gives three; tapping quantity opens editor at three.
- Editing Wholesale quantity to one is rejected with Minimum order: 2 packs. Editing to four succeeds; cart shows four packs and Wholesale subtotal 2320. Existing Shop subtotal 145 remains separate; aggregate subtotal 2465.
- Some initial actions were concurrent with founder device use; those ambiguous transitions are not counted as passes. Later checks use a stable screen before each action.

Further checks pending: return navigation, Saved/search, whole-grid paging, rotation, Store, app log review. Floating cart overlap is an audit observation, not yet a separately confirmed defect; investigate existing drag/avoidance behavior before deduplication.

Root cause of SKU-DEVICE-02: compact aligned SKU calls _ProductVisual(minimumControlExtent: 48, squarePhoto: true). _compactProductVisualLayout reserves the full Save touch target above the square image. This is shared card behavior, not missing image padding in individual assets. Source diagnosis confirmed; app code unchanged during registration.

Log review through 20:51 IST: no Flutter overflow, unhandled Flutter exception or fatal app crash observed. One startup MIUI PerfDebugMonitor file-not-found warning is recorded; app startup completed. Further device scenarios remain pending, including a reliable Cart return capture (last sequence overlapped scrolling and is not claimed passed).
