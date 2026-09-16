# OPPO counter-sale audit — 16 September 2026

## Decision

**The tested Cash and manual UPI journeys reach paid receipt and native PDF sharing, but the counter flow is not ready for visual/production approval.** Twelve findings are registered: eleven observed technical/usability/design defects and one known review-runtime recovery limitation. No fixes or new APK were made.

This was **agent-operated testing on the physical OPPO**, using real taps, scrolling, keyboards, app switching and restart. It was not a study with recruited human participants. The benchmark is a pattern-level comparison with published GrabMerchant and PhonePe Business material, not a hands-on competitor test or a pixel-for-pixel comparison.

## Device and scope

- OPPO CPH2375, serial 2b3e0f71, 720 × 1612 px, 320 dpi (360 dp portrait width).
- APK 1.0.0-r66.31-runtime / 2026091601, package com.moolsocial.app.runtime.
- APK SHA-256: 44859AAF8BA278135DA5C94C2E0B220C04B34004B8275A833BAE9625B5BCD54C.
- Existing TEST Store · 1000 orders; default font 1.0×, OPPO Very large 1.6×, portrait and landscape, numeric/alphabetic keyboards, three-button navigation.
- Original font and rotation settings restored. Store dashboard left open.
- Existing private data backed up before testing. No uninstall, reseeding, source edits, deployment or external message.

## End-to-end results

**Cash:** customer phone + name + business → products/search → 3 units/₹220 → reduce to 2 units/₹164 → review/edit return → invoice → reject blank/overpayment → ₹64 partial + ₹100 remaining collection → Paid in cash → PDF save/readback → Android share sheet/cancel → Next sale → cold-restart invoice recovery.

Cash invoice: **INV-ORD-1789520192731083**, QA Counter Audit September / QA September Grocery. The saved PDF contains 1 atta × ₹108 and 1 salt × ₹56, total ₹164. Filename uses seller + business + invoice. Saved file: audit-paid-invoice.pdf, 8,335 bytes. This is a marked local preview, not a backend-issued invoice.

**UPI recording:** second synthetic customer → 1 salt/₹56 → select UPI → invoice → collection unexpectedly defaults to Cash (CF-01) → explicitly select UPI → missing-reference rejection → enter synthetic QAUPI202609160001 → paid receipt → PDF → native share sheet/cancel. Invoice: **INV-ORD-1789521604947040**. No bank/UPI transfer occurred; this verifies manual recording only.

Two synthetic invoices and three collection records were deliberately created through the UI (Cash ₹64 + ₹100, manual UPI ₹56). They remain for inspection. The additional uncompleted ₹264 draft used for recovery testing was explicitly discarded. The pre-existing ₹428 invoice was only viewed; its payment was not changed.

**Recovery:** both the completed cash invoice and unfinished draft survived process restart. Restart begins at Shop and requires reselecting the synthetic workspace; Counter sale then recovered the same customer and 1-unit/₹264 draft in a compact view. This is a route/session recovery problem, not confirmed invoice or draft loss. New recent-customer identity did not recover with it.

No matching Flutter exception/crash/app-ANR signature was found in the captured log window. This is bounded log evidence, not a performance certification. Financial totals were checked through visible records; this audit does not claim a server-ledger or database-integrity audit.

## Fix order

1. CF-01 payment-method continuity; CF-03 keyboard/error reachability.
2. CF-02 landscape fit; CF-04 invoice item readability.
3. CF-05 repeat-customer continuity; CF-06/07/08 focused layout, primary action and payment feedback.
4. CF-09/10/11 copy, scaling and payment auditability.
5. Qualify CF-12 in the production-like runtime before release acceptance.

P1 = high-impact workflow/release concern; P2 = meaningful usability or correctness risk with a workaround; P3 = lower-impact clarity/polish issue. Priorities are audit recommendations, not user-approved implementation tickets.

## Defect register

### CF-01 · P1 · UPI invoice opens collection with Cash selected

**Type:** Technical / payment UX · **Status:** Open — not fixed

**Reproduce:** Create a counter invoice with UPI selected → Record payment received.

**Observed:** The ₹56 UPI invoice opened Record collection with Cash selected. UPI had to be selected again. No incorrect cash entry was submitted in this audit.

**Expected:** Carry the selected method forward, or require an explicit collection-method choice. Do not silently substitute Cash.

**Evidence:** [136-upi-create](136-upi-create.png) · [139-upi-collection](139-upi-collection.png) · [140-collection-upi](140-collection-upi.png)

**Retest:** Create Cash and UPI invoices; open, cancel and reopen collection. Verify method continuity and the method saved with each collection, including partial payments.

### CF-02 · P1 · Landscape leaves only 136 px for the customer form

**Type:** Device fitment · **Status:** Open — not fixed

**Reproduce:** Open optional customer details → rotate OPPO to landscape at default text size.

**Observed:** The fixed header, financial panels and bottom navigation leave y=410–546 for the form. One field fragment and a clipped optional-details control are visible; normal form completion requires excessive scrolling.

**Expected:** Give the active sale a usable viewport in landscape; collapse unrelated dashboard chrome and keep required fields/actions reachable.

**Evidence:** [93-rotation](93-rotation.png) · [94-landscape-scroll](94-landscape-scroll.png)

**Retest:** Complete customer entry, products, review, payment and handover in landscape with keyboard open/closed; check system navigation insets.

### CF-03 · P2 · UPI validation pushes Confirm collection below the keyboard

**Type:** Keyboard / validation · **Status:** Open — not fixed

**Reproduce:** Record UPI collection → enter amount → submit without reference → focus reference and type it.

**Observed:** The error expands the form. Confirm collection has only 2 px of visible semantics at the numeric keyboard boundary, then disappears while the alphabetic keyboard is open. Dismissing the keyboard allowed submission.

**Expected:** Keep the active field, relevant error and confirmation action reachable above the keyboard; scroll deliberately to the error/action.

**Evidence:** [142-upi-keyboard](142-upi-keyboard.png) · [144-upi-ref-error](144-upi-ref-error.png) · [146-upi-ref-keyboard](146-upi-ref-keyboard.png)

**Retest:** Repeat missing/invalid reference and amount errors with both keyboards at 1.0× and 1.6×. Confirm without relying on hidden controls.

### CF-04 · P2 · Unpaid invoice hides quantity and price columns horizontally

**Type:** Visual / invoice usability · **Status:** Open — not fixed

**Reproduce:** Create/open an unpaid multi-item invoice → scroll to the item table → swipe horizontally.

**Observed:** Initially only Item / pack is visible. A horizontal swipe reveals Qty, Unit price and Amount while hiding product names. There is no clear affordance explaining this. Values exist; this is not missing financial data.

**Expected:** Use mobile invoice rows that show name, pack, quantity, unit price and line total together, or make overflow unmistakable.

**Evidence:** [36-invoice-scroll](36-invoice-scroll.png) · [121-unpaid-table](121-unpaid-table.png) · [122-table-horizontal](122-table-horizontal.png)

**Retest:** Verify all line values together on a 360 dp viewport, long product names, multiple items and enlarged text; totals must remain unchanged.

### CF-05 · P2 · Recent customer does not reuse saved name and disappears after restart

**Type:** Technical / customer continuity · **Status:** Open — not fixed

**Reproduce:** Complete a sale with customer name/business → Next sale → choose that recent phone → expand details → restart and reopen customer entry.

**Observed:** The recent entry showed only the phone. The next draft Name field was empty, despite the completed invoice retaining QA Counter Audit September. After restart the recent list returned to seeded customers; the completed named invoice still existed in Sales.

**Expected:** Retain useful recent-customer identity and reuse previously supplied billing details with an edit option.

**Evidence:** [31-details-reopen](31-details-reopen.png) · [52-paid](52-paid.png) · [79-recent](79-recent.png) · [92-restored-form](92-restored-form.png) · [93-rotation](93-rotation.png) · [128-upi-recent](128-upi-recent.png) · [118-paid-after-restart](118-paid-after-restart.png)

**Retest:** Repeat two sales for one named customer before/after restart. Verify recent identity and field reuse; old invoice snapshots must remain immutable. Business-field reuse needs an explicit retest.

### CF-06 · P2 · Active sale changes between a narrow dashboard pane and full width

**Type:** Visual / layout consistency · **Status:** Open — not fixed

**Reproduce:** Open Customer, focus/dismiss keyboard, enter products, create invoice, record payment.

**Observed:** Default portrait customer inputs are only 456 px wide on a 720 px screen. Dashboard finance and side actions remain prominent. Focusing the keyboard expands the form; invoice/collection returns to the narrow pane. Unpaid handover heading wraps over three lines.

**Expected:** Keep a stable, focused sale layout across customer, review, collection and handover with clear hierarchy.

**Evidence:** [04-customer](04-customer.png) · [06-short-phone](06-short-phone.png) · [35-created](35-created.png) · [38-payment](38-payment.png) · [42-payment-keyboard](42-payment-keyboard.png) · [52-paid](52-paid.png)

**Retest:** Compare every phase at default/enlarged text with keyboard transitions. Check reading width, button wrapping and scroll position continuity.

### CF-07 · P2 · Customer continuation sits below recent-customer suggestions

**Type:** Navigation / discoverability · **Status:** Open — not fixed

**Reproduce:** Start Counter sale → enter a valid phone → optionally expand details.

**Observed:** Add items to bill is not initially visible. It sits after explanatory copy and recent customers; optional details and enlarged text add more scrolling.

**Expected:** Make the primary continuation obvious once required input is valid; keep suggestions secondary.

**Evidence:** [04-customer](04-customer.png) · [08-expanded](08-expanded.png) · [13-form-bottom](13-form-bottom.png) · [75-large-form-lower](75-large-form-lower.png) · [76-short-submit](76-short-submit.png)

**Retest:** New and returning users must locate continuation without exploring the whole form; test keyboard open/closed and four recent customers.

### CF-08 · P2 · Partial collection returns to the invoice top and hides the new balance

**Type:** Payment feedback · **Status:** Open — not fixed

**Reproduce:** Record ₹64 against a ₹164 invoice.

**Observed:** The app returns to the tall invoice header. Received ₹64 / Due ₹100 is below the initial viewport and requires another scroll. The data is correct.

**Expected:** Make the collection outcome and remaining balance immediately visible, preserving a useful reading position.

**Evidence:** [47-part-paid](47-part-paid.png) · [48-part-paid-status](48-part-paid-status.png)

**Retest:** Submit partial Cash/UPI records and immediately verify received/due amounts without scrolling or inferring changes from global totals.

### CF-09 · P3 · Cash overpayment error unnecessarily mentions a UPI reference

**Type:** Validation copy · **Status:** Open — not fixed

**Reproduce:** Choose Cash → enter ₹165 against ₹164 due → Confirm collection.

**Observed:** The combined message asks for an amount within the balance and a UPI reference when applicable. It is not specific to the Cash error.

**Expected:** Show a precise amount error beside the amount field; show reference errors only for UPI.

**Evidence:** [44-overpay-result](44-overpay-result.png) · [144-upi-ref-error](144-upi-ref-error.png)

**Retest:** Check blank, zero, excess amount, decimal format and missing-reference messages independently.

### CF-10 · P3 · Largest text truncates task title and product search hint

**Type:** Typography / accessibility · **Status:** Open — not fixed

**Reproduce:** Set OPPO Font to Very large (system scale 1.6) → open counter products.

**Observed:** Counter sale becomes Counter s… and Search your products is truncated. Customer labels and optional actions wrap heavily. Product/review controls were still operable in the tested cases.

**Expected:** Preserve meaningful labels through responsive typography and concise copy; keep accessibility scaling supported.

**Evidence:** [74-large-ime](74-large-ime.png) · [80-recent-selected](80-recent-selected.png) · [83-large-review](83-large-review.png)

**Retest:** Check all sale stages at the supported maximum text scale, including long labels and keyboard errors. Do not simply disable font scaling.

### CF-11 · P2 · UPI completion does not show the recorded method/reference in the inspected receipt details

**Type:** Receipt / auditability · **Status:** Open — not fixed

**Reproduce:** Record the synthetic UPI payment with QAUPI202609160001 → inspect paid receipt and expanded Invoice details.

**Observed:** The receipt says Paid to store. The inspected expanded details show invoice identity/store/date but not the entered UPI reference or explicit UPI method. This audit does not claim the reference is absent from storage.

**Expected:** Allow the cashier to verify recorded tender and reference from the receipt or a clear linked collection record.

**Evidence:** [148-upi-paid](148-upi-paid.png) · [150-upi-details](150-upi-details.png) · [152-upi-pdf](152-upi-pdf.png)

**Retest:** Verify displayed and persisted method/reference, including split collections, and distinguish a manual record from provider-confirmed settlement.

### CF-12 · P1 · Restart requires workspace recovery and changes the active sale presentation

**Type:** Known review-runtime limitation · **Status:** Open — not fixed

**Reproduce:** Leave an unfinished 1-unit / ₹264 draft → force-stop and reopen the app → reselect the existing review workspace → reopen Counter sale.

**Observed:** Launch starts at Shop and the synthetic workspace setup must be traversed again. The draft survives and reopens in the compact dashboard pane rather than the previous full-screen view. The completed paid invoice also survives. This is a review-runtime limitation, not evidence of lost invoices/drafts.

**Expected:** Before production acceptance, restore the authorized workspace/session and provide a clear resume path to the retained sale.

**Evidence:** [98-draft-before-background](98-draft-before-background.png) · [99-draft-after-background](99-draft-after-background.png) · [104-cold-ready](104-cold-ready.png) · [106-draft-reset](106-draft-reset.png) · [118-paid-after-restart](118-paid-after-restart.png)

**Retest:** Qualify authenticated production-like cold launch, OS process death and explicit draft resume. Preserve all saved records and distinguish route recovery from data recovery.

## Premium-app comparison and design direction

“Premium” is treated here as clear task hierarchy, trustworthy payment feedback, coherent responsive layout and low effort—not a particular colour or extra animation.

| Reference | Relevant published pattern | OPPO gap / recommended direction |
|---|---|---|
| GrabMerchant | In-store payments and delivery sales share a coherent reporting view. | Keep sale identity, amount, payment state and next action consistent across the journey; avoid switching between a full-width task and a cramped dashboard pane. |
| PhonePe Business | Published merchant workflow emphasizes transaction history and payment/settlement tracking. | Make payment method, receipt status and collection reference easy to inspect; a generic Paid to store result is insufficient for verifying the entered reference. |
| Android accessibility | Aim for at least 48 × 48 dp interactive targets. | Keep controls comfortably reachable when text grows; do not infer target size from clipped UI-automation bounds alone. The report does not claim a full TalkBack/touch-target audit. |
| Android window insets | System bars and keyboard must be accounted for in layout. | Fix the UPI error/keyboard action obstruction and the landscape content shortage. |

The layout recommendations above are the auditor's design judgment applied to direct OPPO evidence. They are not claims that every competitor screen is superior. Public image/browser inspection was limited; no competitor checkout was executed.

Additional polish candidates (not counted as confirmed technical failures): add an obvious clear-search affordance; show saved customer/business identity in the pre-invoice review and Sales row; show unit prices/line amounts in review; make selected Cash/UPI icons more legible against the dark fill; reduce repeated instructions once the required action is clear.

Sources inspected:

- [Grab Product Team: unified merchant payments](https://www.grab.com/inside-grab/stories/grabx-tap-to-pay-merchant-smartphones-for-all-in-one-cashless-payments/)
- [PhonePe Business official app listing](https://play.google.com/store/apps/details?id=com.phonepe.app.business)
- [PhonePe merchant solutions](https://www.phonepe.com/business-solutions/offline-merchant/)
- [Android touch-target guidance](https://support.google.com/accessibility/android/answer/7101858?hl=en)
- [Android edge-to-edge and insets](https://developer.android.com/develop/ui/views/layout/edge-to-edge)

## Coverage limits / still required

- Physical USB/OTG scanner and camera recognition of real barcodes; the unknown-barcode test used simulated keyboard input only.
- Actual recipient delivery/opening in WhatsApp, Chat or email. Both native share sheets were opened and cancelled; no message was sent. Native save/readback was exercised on the Cash PDF.
- Live UPI authorization, provider confirmation, retries, refunds and bank settlement; backend-issued PDF/storage and persistent Chat attachments remain held.
- TalkBack navigation, multi-touch PDF pinch/zoom, multipage/500-item PDFs, multilingual fonts, RTL, every display-density setting, gesture navigation and other Android/OEM devices.
- Rapid double-submission/race conditions, offline/network interruption, low-memory stress, thermal/performance/accessibility instrumentation and production backend/ledger reconciliation.
- A human usability session with real store operators and the user's screen approval. The 18 previously documented backend/security blockers remain outside this audit.

The matrix describes what actually ran. This is a broad physical-device pass with explicit gaps, not a claim of exhaustive production qualification.
