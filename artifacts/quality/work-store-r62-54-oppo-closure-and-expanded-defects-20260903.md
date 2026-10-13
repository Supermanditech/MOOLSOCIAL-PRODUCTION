# Work Store r62.54 — OPPO closure for defects 42–55

## Exact candidate

- Source branch: `work/codex-ui/work-core-controls-v1-20260902`
- Final source commit: `21f34ba5beccfbf95baddf6ee1f7d24b828cc52c`
- OPPO: `CPH2375`, serial `2b3e0f71`
- Package: `com.moolsocial.app.runtime`
- Version: `1.0.0-r62.54-runtime` (`2026090310`)
- APK SHA-256: `AEDFEB40EF2CE202955793A1F53B2FBC683CBECFA1E436A328DE529DCE469167`

## Defects 42–55 OPPO result

- **42 passed:** the debug-review launch shows the Mool app mark while Flutter starts; the locked production Splash resources remain unchanged.
- **43 passed:** `Search your store` is fully visible on dashboard and Store destinations.
- **44 passed:** both packing products remain visible and actionable above `Mark ready`.
- **45 passed:** Delivery settings returns to Store Settings; Offers/paid work return to Grow; every internal Store destination has a visible Back action.
- **46 passed on r62.54:** invoice handoff opens Workspace Chat with the invoice ID, ₹1468 total, exact products, Rakesh recipient and `Find customer` action.
- **47 passed:** Customer Chat preserves Rakesh and its pending customer-support draft.
- **48 passed:** the completed purchase reconstructs two available Fortune Oil products instead of reporting no previous basket.
- **49 passed:** Wholesale search shows no Shop/Wholesale rail above the keyboard; the Store owner remains intact.
- **50 passed:** drafted New Sale shows `Keep editing` and `Discard sale`; no restart is required.
- **51 passed:** Today, Customers, Money, Grow and Storefront labels remain complete.
- **52 passed:** the public product is actionable in the first Storefront viewport.
- **53 passed:** public Buy displays Mahadev Fresh Mart's Fortune Sunflower Oil, 1 L pouch, ₹264, stock/delivery and return facts; `This product could not be found` is absent.
- **54 passed visually:** `Experience or qualification` is complete at the OPPO text size.
- **55 passed:** compact-width operational headings use balanced stacked presentation.

## Expanded defects recorded after 42–55

56. **Native editable accessibility owner remains incomplete.** OPPO UIAutomator still reports an empty `content-desc` and `NAF=true` for Work `EditText` nodes, even though Flutter semantic-label tests pass. This requires a platform-accessibility-specific child ticket and TalkBack verification; it is not falsely marked fixed.
57. **Direct Storefront Buy return takes two Back actions.** The first Back changes product details to the generic Shop catalogue; the second returns to Storefront. A Storefront product preview should return directly to its Store context. This overlaps the shared Buy navigation owner.

The previously recorded shared scanner defect also remains open: the camera has no visible capture/tap control or clear automatic-scan state. It was outside defects 42–55 and its exact Buy owner was not overwritten.

## Verification

- Local affected matrix before APK: 119 active tests passed; 48 evidence-only tests skipped.
- Final Work-layout plus Chat regression: 56 active tests passed; 48 evidence-only tests skipped.
- Focused invoice-to-Chat regression: passed.
- Local 412×915, 1.4× text capture set: 25 screens under `artifacts/quality/work-store-atomic-r62-50-local-review-20260903`.
- OPPO evidence: `artifacts/device/work-store-atomic-r62-54-oppo-review-20260903/oppo-audit`.
- Redmi, Cursor worktree, backend, Firebase and production package were untouched.
