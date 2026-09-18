# Shared SKU device defects - local fixes

Status: implementation and local tests complete; revised founder visual approval and successor Redmi retest pending. r66.29 on Redmi still has the recorded defects and is not qualified. No integration or production release.

SKU-DEVICE-01: normal quantities now use a single 44-high row in narrow SKU cards. Minus/count/plus remain separate; minus/plus width adapts from44 to28, editable count keeps at least24 width. Long values retain the two-row fallback when they cannot fit. Edge taps, minimum quantity, editor, cart isolation and add/remove transitions remain covered. This deliberate compact hit-area change requires physical Redmi usability retest.

SKU-DEVICE-02: square product photo begins4 pixels below card top, with no loss of photo extent. Badge and Save move into a thin footer; standard control strip reduced from roughly50 to30 logical pixels following founder feedback. Save uses28x28 target and15 icon, with its tooltip and saved-state semantics; no decorative circle. Large/long badges may grow as necessary, never covering the photo or Save. Shared grids: Shop, Wholesale, Offers, Store, Saved, Search and Medicine. Existing independent column packing preserved.

OFFERS-DEVICE-03: above1.3 text scale, publisher controls stack as full words and promo facts use full width, with a separate media/action row. Default-scale side-by-side promo and80-percent page width remain. Founder addition: warm cream/rose gradient and faint edge separate the light promo half from the app background; subtle foreground tint also separates the packshot white.

Validation: v2 had173 passes covering responsive grids, exact quantity edge taps/long values, shared surfaces and Offers. v3 had112 passes for Offers and supplier-media/product-variant journeys before final thin-footer adjustment. Final v5 had134 passes and2 obsolete strict-gap failures; both required a positive gap where the thin footer now meets Save without overlap. Changed that expectation to allow a shared boundary while preserving all no-overlap/readability checks; final38 SKU media cases pass. Final shared surface tests assert photo-at-top, unchanged square frame, thin Save footer and successful Save toggling without product navigation. Offers tests explicitly assert ordinary quantity height44, real add/increase/remove and default/large-text captures. Four-file static analysis passed; final changed test-file analysis recorded separately if added. No pixel-only approval is treated as device qualification.

Evidence includes actual local Flutter full Offers previews and shared-component Shop/Wholesale/Store previews. Local fixture products differ from the isolated Redmi review fixture; images are not represented as device captures. Earlier failing test receipts retained for traceability.

## Founder top-edge revision (18 September 2026)
Supersedes the footer placement above: the rounded badge sits left and Save sits right at the card top edge, above the photo. The normal strip is 30 logical pixels, with a 28x28 Save target and 22-pixel white circle. Square photo extent is unchanged. Long badges or enlarged text retain a non-overlapping fallback. Only up to 2 pixels follow the controls before the photo.

Validation: 30 shared-grid/Offers tests and 38 SKU media regression cases pass; static analysis of both changed Dart files reports no issues. Local Flutter preview attached in top-edge evidence. Revised founder approval and subsequent Redmi build/retest remain pending; the installed r66.29 APK is unchanged.
