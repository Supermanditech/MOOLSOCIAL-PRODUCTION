# Work Store r62.49 — OPPO audit and next atomic defect set

## Candidate identity

- Source branch: `work/codex-ui/work-core-controls-v1-20260902`
- Source commit and verified remote: `0ac4ca5222692def888511ed4784ebc079724834`
- OPPO: `CPH2375`, serial `2b3e0f71`
- Package: `com.moolsocial.app.runtime`
- Version: `1.0.0-r62.49-runtime` (`2026090305`)
- APK SHA-256: `28627917D17859B4851CB0B7A4D2981496C2AF0CA7E1EE55F8BC9FF9DE510075`
- Redmi, production package, backend and Cursor source were not changed.

The earlier phrase “57 defects” referred to the larger collection of review states. The post-r62.48 register contains 41 numbered corrections. This audit keeps those numbers intact and adds only defects actually reproduced on OPPO.

## Confirmed OPPO passes from the 1–41 correction set

- Native inline Store search and result filtering work; the keyboard removes the Store rail.
- Reject Order is compact, coloured and requires a selected reason.
- Choose your Workspace fits above Android navigation and keeps content creation in Social while another business/professional Workspace is an approval request.
- Delivery settings, Staff and counters, and the approved Business record now open Store-owned destinations.
- Add Product is blank, comprehensive, scrollable and keeps Cancel/Save above the keyboard.
- Group Bulk active-deal facts, confirmed Store identity, savings, fees and delivery facts are visible.
- Wholesale has a Store-owned loader, returns to Store, and its recommendation cards no longer overlap in the normal state.
- Complete this order fits above Android navigation.
- Customer statement, custom date picker, Money ledger and settlement review are operationally visible.
- Offers and paid-work creation remain in Store context rather than legacy Retailer pages.
- Pickup correctly becomes Ready for customer pickup and produces an invoice without delivery assignment.
- Promote carries the active Store identity and uses the premium MoolSocial presentation.
- Business filter and compact person-plus action fit in global Workspace Chat.
- Storefront clearly says Customer storefront preview, separates visibility control, uses Make private, and opens a complete product-facts sheet.
- The live Business record shows approved Store facts rather than pre-approval `0 of 4`/Decision Pending state.

## Earlier correction numbers still open or reopened on OPPO

1. **Defect 9 — scanner capture/status remains open.** The live camera has no visible capture/tap control and no clear automatic-scan status or motion. This is still blocked on the exact shared Buy scanner owner; Codex did not overwrite that file.
2. **Defect 16 — in-Store Wholesale keyboard rail fails Store ownership.** With the keyboard open, the embedded Buy rail appears with `Shop`, `Wholesale`, `Orders` and `Offers` instead of a Store-owned compact state. Evidence: `oppo-audit/36-buy-stock-keyboard-loaded.png`.
3. **Defect 25 — child destination return context is incomplete.** Android Back from Store Offers returns to the dashboard rather than restoring Store Grow.
4. **Defect 28 — customer retention is only partial.** The completed purchase is recorded, but Customer Chat opens the generic inbox and Repeat basket reports that no previous basket exists.
5. **Defect 40 — native input names remain empty.** OPPO hierarchy shows empty `content-desc`/hint for New Sale customer contact, Add Product inputs and funded-work inputs despite visible field text. Evidence: `43-product-editor-keyboard.xml`, `55-new-sale.xml`, and `49-funded-work.xml`.

## New OPPO defects — continue numbering at 42

42. **Cold launch is a blank solid-blue surface for several seconds.** The first usable Store frame was not available during the initial four-second capture and startup skipped hundreds of frames. Evidence: `01-dashboard.png` and device log.
43. **The persistent Store search hint still clips.** The normal dashboard shows `Search your s...` at the OPPO effective text size. Evidence: `02-dashboard-ready.png` and `59-storefront.png`.
44. **Packing content is clipped by its sticky action.** The second product row is partly hidden behind `Mark ready`; it can be checked only through the small exposed region. Evidence: `12-dashboard-packing.png`.
45. **Settings child navigation skips its parent.** Android Back from Delivery settings, Staff and counters or Business record returns directly to the dashboard instead of Store settings; the child surfaces also have no visible Back action.
46. **Invoice-to-Chat handoff did not open Chat.** Tapping `Send in MoolSocial Chat` dismissed the invoice sheet and restored the Store dashboard instead of opening a draft/conversation. Evidence: `15-invoice-share.png` followed by `16-chat-invoice.png`.
47. **Customer Chat is not customer-specific.** Tapping Chat for Rakesh opens the generic Workspace Chat inbox with no selected customer, direct thread or visible draft. Evidence: `28-customer-chat.png`.
48. **Repeat basket contradicts the purchase statement.** The screen shows Rakesh's completed ₹1468 purchase but says `No previous basket is available for this customer yet.` Evidence: `29-repeat-basket.png`.
49. **Wholesale search repeatedly reinitializes the embedded module.** Entering/finishing search can show the full `Preparing Wholesale and Bulk` loader for several seconds, reducing continuity. Evidence: `35-buy-stock-keyboard.png`, `38-scanner.png`, and `39-scanner-permission.png`.
50. **A drafted New Sale becomes a navigation trap.** After adding a product, Store rail taps and Android Back do not leave Sell; no discard/continue decision appears. A review-runtime restart was required. Evidence: `55-new-sale.png` and the subsequent native hierarchy.
51. **Storefront contextual tabs clip at OPPO text size.** `Customers` and `Storefront` truncate in the five-tab contextual strip. Evidence: `59-storefront.png`.
52. **The first Storefront product is initially obscured by the Store rail.** The product card is only partly visible and must be scrolled before it can be safely tapped. Evidence: `59-storefront.png` and `60-storefront-product.png`.
53. **Public Buy product wiring fails.** `Open customer Buy view` reports `This product could not be found` and lands on the generic Shop catalogue rather than the Store product. Evidence: `61-storefront-product-detail.png` and `62-customer-buy-view.png`.
54. **Funded-work qualification copy truncates.** `Required qualification or experience` displays as `Required qualification or experie...` at the OPPO text size. Evidence: `49-funded-work.png` and `50-funded-work-bottom.png`.
55. **Store settings child headers waste space at OPPO text size.** `Customer delivery coverage` and `Staff and counters` break into oversized multi-line left columns while the right subtitle leaves an unbalanced operational header. Evidence: `22-delivery-settings.png` and `64-staff-counters.png`.

## Next atomic batch boundary

- Codex-owned corrections: 16, 25, 28, 40 and 42–55, excluding the shared scanner source.
- Shared Buy scanner correction: defect 9 must be supplied by its exact current owner or after owner release.
- No backend success is claimed for review-only gateways. Production adapters remain a separate integration concern.
- r62.49 is retained as the git-safe review baseline; the next source change must be a new atomic commit and review version.
