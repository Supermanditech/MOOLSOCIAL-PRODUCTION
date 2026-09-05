# Fresh Redmi journey inventory

Candidate: UAW-CURSOR-BUY-R66-1-REDMI-REVIEW-20260905. Installed hash: `30A71FE8B6696BF51400FBED5A90C3179E25CE0A6153A998F5A041657C9D35C3`; code 2026090501. Fresh execution ledger below qualifies individual actions, not entire coverage groups.

Every row below started Not tested. It is a planned coverage group, not a defect count. Expand to exact screens, controls and repeatable steps during current Redmi observation. Group status may be In progress with explicit observed subsets; individual results are Not tested, Passed on Redmi, Failed on Redmi, Blocked (reason), Locally tested only, or Not applicable (reason). Keep numerator/denominator explicit; never claim every conceivable combination tested.

| ID | Journey and nested actions | Current result |
|---|---|---|
| U01 | Cold launch, Buy entry, Quick/Scheduled/Wholesale/Bulk, back to shell | In progress: launch/Quick observed; landscape failure; other modes pending |
| U02 | Search type/clear/no match/retry, category/filter/sort, close/back/reset | Not tested |
| U03 | Main grid ownership, title/pack/price/availability, product details, quantity, policies | In progress: tomato/wheat subsets; detail density and Add obstruction failed |
| U04 | Visit store, store identity/locality/status/fulfilment, expand details, all products | In progress: two retail stores and expanded status observed; all-products and other modes pending |
| U05 | Store SKU/detail/cart/back/related stores and exact browsing continuation | In progress: related store and explicit continuation pass; nested Cart Back fails |
| U06 | Save/unsave, saved search/empty/product/add/remove, return | Not tested |
| U07 | Scanner active/capture feedback/torch/switch/manual/permission/error/back | Not tested |
| U08 | Ask store/product/order Chat context and exact return, composer/keyboard | In progress: store/order Help returns pass; settled keyboard/typing pass; shared loading/context dependency |
| U09 | External share sheet and cancel/return | Not tested; WhatsApp specifically blocked by founder |
| U10 | Add feedback, compact floating cart, count/amount/drag/insets, store visibility | In progress: obstructed action, count semantics and drag findings; high amounts pending |
| U11 | Cart edit/remove/clear/recover, min/max quantity, high Wholesale amounts | Not tested |
| U12 | Split by store, line identity, Shop vs Wholesale/Bulk cart context | In progress: two-store split ₹353 correct at confirmation; retained purchase grouping fails |
| U13 | Address create/edit/validation/keyboard/back, eligibility and service area | In progress: empty/phone/PIN rejection and cancel pass; real serviceability/persistence pending |
| U14 | Delivery choices/scheduling/pickup and contextual purchase order | Not tested |
| U15 | Payment methods, eligible/ineligible COD, pending/failed/cancelled/unknown/retry | In progress: four methods select; eligible review COD visible; remaining outcomes pending; real charges prohibited |
| U16 | Payment success/confirmation, duplicate submit, cart/order continuity | In progress: local COD confirmation/split observed; identity failure; no backend payment proof |
| U17 | Supplier accept/decline/timeout/partial availability consumer projection | Not tested; live provider adapter availability to be audited |
| U18 | Packing/ready/assignment/pickup/delivery/exception and quick status controls | In progress: review packing and alerts toggle observed; live delivery unavailable; route-graphic finding |
| U19 | Orders/detail/splits/tracking/return/back, invoices/download/share cancel | In progress: invoice save/cancel/return pass; grouping failure; remaining orders/states pending |
| U20 | Reorder, cancellation, return/replacement/refund/support recovery | In progress: cancellation reasons/required gating observed; submit held until identity issue resolved |
| U21 | Provider/master/offer/payment/delivery fields and event-owner mapping | In progress: source boundary inventory below; not live device proof |
| U22 | Reconnect/stale/duplicate/out-of-order/cancelled event handling | Not tested; absent adapters recorded blocked |
| U23 | Font/display scale, safe areas, bottom controls, keyboard, compact/long text | In progress: normal portrait keyboard subsets; landscape/compact-target findings; scale matrix pending |
| U24 | Background/foreground, lock/unlock, process restart, network interruption | Not tested |
| U25 | Animation/reduced motion, focus/semantics, colours, card density and icon fit | In progress: static visuals/semantics findings; recorded motion/reduced-motion matrix pending |

Evidence is newly captured from Redmi serial TG8HCYTGGQT885OF after candidate identity verification. Source-test findings and old r65.11/historical screenshots do not constitute new UAT evidence. No OPPO, WhatsApp, production package or real supplier operation is permitted in this run.

## Source boundary inventory — not Redmi passes

Read-only inspection at review HEAD 49d6d413 confirms:

| Boundary | Existing source contract | Connected verification limitation |
|---|---|---|
| Review entry | `main.dart` starts `/app/buy` in UI-review mode, with a memory-backed guest JourneySession | No Firebase login or production identity proof |
| Published Workspace product | `journey_router.dart` accepts `workspaceProduct`, resolves a published item and maps store name, price, stock, delivery promise and public listing into an existing Buy session | This local host projection is not proof of cross-device supplier publication or event delivery |
| Product facts | `buy_v2_content_contracts.dart` contains productId, price, partner, orderability, sourceId, fulfilment, opening/cutoff/delivery promise/fee, observation time and stale flag | Default catalogue facts adapter is not a live provider connection |
| Commerce | `BuyV2CommerceAdapter.refresh/placeOrder/reconcileOrder` exists; review defaults to a device-review adapter | No real payment/order mutation is permitted or claimed |
| Delivery exceptions | Existing adapter supports load, reschedule and proof dispute; exception kinds include delayed dispatch, failed attempt, recipient unavailable and return to sender | `BuyV2Session` defaults its exception adapter to null; no production adapter is injected by the ordinary Buy route |
| Live delivery | Snapshot has order/source identity, coordinates, driver, vehicle, ETA, timestamp, progress and tracking reference | Default live adapter and screen map builder are null; no live GPS/driver movement is verified |
| Saved/customer/order support | Review customer-state, resolution and shopping-alert adapters are supplied by review defaults | Their on-device outcomes must remain labelled review-only evidence |

The listed fields and methods are existing implementation inventory, not proof that every required supplier accept/decline/packing event is represented. Actual customer-visible states and missing paths will be recorded during the fresh device audit; Workspace/backend implementation ownership stays with Codex.

## Fresh execution ledger — first collection, still incomplete

Captures are immutable PNG/XML/JSON triples under external `redmi-r66-1`; each JSON records capture time and both hashes. 001–041 currently contain 40 successful captures; 021 is an explicitly failed evidence attempt, not a product verdict. More captures do not mean more unique tests. No whole coverage group has been closed.

| Captures | Action and observed result |
|---|---|
| 001–003 | Verified review cold launch and portrait entry. Landscape viewport and preparation wording failed: R66-UAT-001/002. |
| 004–013 | Fresh tomatoes product/price/pack/policy/seller inspected. First Add works; dock blocks Add-one centre and mixes scoped semantics (004/005). Drag behaviour under investigation (006). Moving dock then Add-one yields quantity 2 / ₹74. Root Product → Cart → Android Back preserves root product (008). Repeated detail fields: 003. |
| 014–020 | Visit Shree Balaji Fresh and store SKU work. Store SKU → Cart → Android Back loses nested context (007); explicit Continue browsing returns to the correct store (019). Status expands (020). Store quantity targets undersized (008). |
| 021–027 | 021 failed hierarchy capture retained; stable 022 shows generic Chat loading, linked to Codex's later shared closure. Ask store → Android Back returns to the same store (023). Settled keyboard fits composer above Gboard (026); 025 was a transition, not a clipping defect. Local draft typing works (027), Send not tapped. Four appended characters `Test` are unsent review residue. |
| 028–031 | Related Sardarpura Supermart opens; adding one wheat atta gives Shop 3 items / two product lines / two stores / ₹353. Existing Wholesale line ₹3480 retained, total across scopes ₹3833. Cart → Address works; Home and Work remain available. No retail purchase-order field visible at this step. |
| 032–041 | New address form opens and scrolls. Empty submission blocked (034); recipient typing and keyboard reachable (035). Invalid phone `123` blocked (039); after 10-digit synthetic input, PIN `12` blocked (041). No address was saved. Immediate post-keyboard-close tap at 038 did not submit; settled repeat 039 did, so no false validation failure is asserted. Form error remains at bottom and is not cleared during edits; source/UX diagnosis pending. |

Only review products were added: Fresh tomatoes x2 (₹74), Stone-ground wheat atta x1 (₹279). Existing Wholesale cart and retained preparing order were not cleared. Shared Chat and operational backend states remain outside device-proof claims. Address/payment/split/order journey continues next.

### Checkout/order continuation, captures 042–069

- 042: cancel unsaved address returns to the existing checkout addresses. No synthetic address persisted.
- 043–047: no initial payment selected; CTA disabled. PhonePe, Paytm, Pine Labs and Cash on Delivery each select with one active method, and Review order enables. No payment app/site launched. Truncated initial CTA is R66-UAT-009.
- 048–050: selected Work address retained; two store shipments contain tomato x2 ₹74 and wheat x1 ₹279; total ₹353; COD says amount due on delivery. Current Quick promise still says `Delivered in 12 min`, extending R66-UAT-002 to confirmation/invoice wording. No retail purchase-order field appears.
- 051–057: GST toggle adds required-details gate; form opens. Empty legal name and short GSTIN rejected; focused field/action remain above keyboard. Cancel returns to confirmation; disabling GST restores Place order. No GST profile saved.
- 058: one local COD review order placed after source verification of the review-only confirmation path. Confirmation reports two deliveries / ₹353. Shop review lines consumed; retained Wholesale cart remains ₹3480. This is not a real order/payment or supplier acceptance test.
- 059–060: first-delivery invoice has correct store, product, quantity, ₹74, COD method and selected address. Download action is fully reachable by scrolling; do not classify its initially clipped scrolling edge as a hidden-action defect.
- 061–063: Android save picker opens. 061 package metadata correction is recorded as E02. Fresh 062 correctly identifies DocumentsUI. Cancel returns to the exact invoice and announces `Invoice save cancelled.`
- 064–066: saved under unique `MoolSocial-r66-1-review-MS-NEW-01.pdf` without overwriting existing files. Save returns to the same invoice; transient success wording was not captured, so it is not claimed. Generated file is 191,919 bytes with `%PDF-1.4` header; SHA `30E17F1F4DD30F9727575304A460D401AFC2B386E4E8CA954AB72D350CE37B78`. External preserved copy `r66-1-review-MS-NEW-01.pdf`. Rendered PDF-content qualification still pending.
- 067–069: Invoice Back returns to confirmation; settled scroll reveals View order details / Continue shopping. View order details exposes unrelated retained orders under the reused purchase identity: R66-UAT-010. No old order was deleted to make this pass.

The initial coverage table remains a planning inventory, not whole-group completion. Tracking, cancellation, resolutions, other sale modes, scanner, filters, screen-scale matrix and lifecycle cases remain in progress/not yet tested.

### Tracking/recovery continuation, captures 070–090

- 070–072: correct first-delivery tracking opens with COD, store, packing and unassigned driver. Live update absence is honestly shown; no actual GPS or supplier update is claimed. Route-progress graphic R66-UAT-011; incomplete recorded address R66-UAT-012.
- 073–077: tracking Items opens the correct tomato; product details open; both Android and on-screen Back return to item list, then order action returns to tracking. Wrong `Shop` Back label recorded as R66-UAT-013, not functional navigation failure.
- 078–080: tapping the label area alone did not toggle; visible switch turns alerts off with paused feedback and back on. Original on preference restored. Notification delivery/OS permissions not proven.
- 081–086: order Help reaches existing shared Chat loading dependency; no Send/call/attachment. After correcting synthetic key-selection mistakes (E03), original unsent auto-draft is exactly restored in 085. Back returns to the same tracking order.
- 087–090: Manage order exposes Cancel order; submission disabled until a reason is chosen; all four reason choices visible. Selecting Ordered by mistake enables Submit request. Not submitted: reused order/purchase identity is unresolved, so do not risk applying a review resolution to an unrelated retained order. Full cancellation/rejection/refund state UAT follows identity repair.

Current fresh register: 13 product/UI observations, separately distinguished from evidence-tool events E01–E03 and shared backend/Chat dependencies. Collection continues; no all-screen or all-ticket completion claim.

### Delivered-order continuation, captures 091–105

- 091–094: Orders returns and Delivered tab filters to two seed deliveries. MS-240741 delivered details open; Refresh produces `Order updates are unavailable right now.` and retains existing status, not a fake live update. Internal catalogue lane narration is R66-UAT-014.
- 095–100: Return/replacement/refund chooser opens. Return items reveals all eight product selectors and a reason menu. A tap on the empty right side did not select the checkbox; Submit was enabled after reason selection but actual submission correctly rejected the missing product (101). Capture labels 098/100/101 do not override that observed result.
- 102–104: visually identified checkbox selects one tomato; maximum is one for this recorded seed line, so Increase is disabled and Decrease remains reachable (48dp targets). Item selection is real; no missing-selector defect is asserted. Per-item policy/eligibility explanation is R66-UAT-015.
- 105: after verifying `BuyV2UiReviewOrderResolutionAdapter.submit` always returns accepted=false with no network/write, exercised one valid local attempt. It displays `This request could not be sent. Contact support for help.`; no order cancellation/return/refund was accepted. The earlier blanket hold on all submit testing is narrowed by this source proof; genuine accepted/subsequent states remain unavailable until an appropriate adapter exists.

## Operational field/event gaps for Codex coordination — not implemented Workspaces

| Boundary | Required consumer/provider contract | Current observed/source limitation |
|---|---|---|
| Order identity | Stable purchaseId, shipment/orderId, source storeId, lineId/SKU, ordered quantity, immutable recipient/address, payment reference and per-store totals | Reused local review purchase identity groups old/new deliveries (R66-UAT-010); never infer production-safe identity from seeded success |
| Customer COD eligibility | Authoritative eligible/ineligible/unavailable result and consumer reason, applicable supplier/fulfilment/amount constraints | Current Buy eligibility is Shop-only plus ₹5000 amount check; no customer eligibility result is consumed |
| Supplier workflow | Authoritative awaiting acceptance, accepted/declined, partial/unavailable, packing/ready, dispatch/assignment/pickup, delivery/failure/reschedule, cancellation/refund decisions, timestamps/version/order/actor IDs | Current device review begins at packing; default live and exception adapters are null. Status images are not cross-device Workspace proof |
| Tracking/address | Immutable full order address/recipient, driver assignment, source/time/freshness, truthful ETA, permissioned live coordinates and exception controls | Address sheet omits full recorded address (012); route graphic conflates preparation with travel (011); no actual live GPS verified |
| Per-item resolution | Typed order-line/SKU quantities and reasons, policy snapshot/eligible-until/disabled reason, idempotent request/reference, accepted/rejected/pending and refund/replacement progress | UI has selectors/quantities; `BuyV2OrderResolutionRequest` only has orderId/kind/reason and session appends `Items id×qty` into free text. Snapshot has no item eligibility/window fields. Review submit always unavailable; no real acceptance proof |

This table is a minimum handoff contract inventory, not authorization to copy supplier Workspace code into Buy or invent policy. Codex remains the Workspace/shared/backend implementation owner; Cursor will fix Buy-side presentation and qualified typed boundaries after collection with exact file claims. Current fresh register: 15 observations; collection continues.
