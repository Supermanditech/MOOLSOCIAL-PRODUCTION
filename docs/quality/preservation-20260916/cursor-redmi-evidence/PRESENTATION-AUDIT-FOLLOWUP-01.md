# Remaining presentation corrections within SKU-M02 / SKU-M05

Source review after first combined pass found remaining occurrences; no new top-level ticket is required and none is device-closed.

- `_CartLine` in buy_v2_views.dart still renders pack/variant and delivery/seller at8px. Raise essential details to11px with natural wrapping; preserve Cart quantities, checkout ownership and product-depth navigation.
- Four media accessibility labels in buy_v2_design.dart still interpolate raw product.title. Use the existing customerTitle adapter in those UI labels, keeping IDs and honest supplier-photo disclosure unchanged.
- `_ProductFeedbackIdentity` still limits title and pack/seller to2 lines and uses raw seller display. Reuse customerSeller, allow full wrapping and readable metadata. Its review eligibility and report owners already scroll; qualify actual report identity without submitting anything.
- Remaining consumer Wholesale labels Flexible MOQ, MOQ reward and the bulk-load delivery description should use clear minimum-order wording; keep internal enum/filter keys unchanged.

Qualification plan: extend the existing four SKU long-metadata scenarios in buy_v2_partner_catalogue_test.dart through Cart and the product report sheet, asserting complete paragraphs, readable metadata, preserved quantity and closing the sheet without submission. Add exact customer-display assertions for media semantics in the existing generated-product glance cases. Retain all existing identity/price/order/interaction checks. No runtime/backend ownership expansion is needed; changes stay within the three current native owners and already admitted test owner.

Current combined process54592 is still running its second cycle on the previous frozen source. Let it finish with its support restoration and3044-owner preservation receipt before source edits. Preserve both results as source-bound history; later edits require fresh focused visual checks, analysis and the required two combined cycles before the successor build. No build is ready or performed. Existing r66.24 remains the last installed artifact. Candidate r66.25 is planned only.
