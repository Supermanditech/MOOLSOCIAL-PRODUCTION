# Counter sale OPPO handoff — r66.32

The new review APK is installed in place on OPPO CPH2375. The populated **TEST Store · 1000 orders** is open for your review. Existing app data was backed up and preserved. Your approval is pending.

## Completed physical journeys

- Cash: customer/business → two products → ₹164 invoice → reject ₹165 and zero → keyboard Done without submission → explicit ₹64 and ₹100 collections → paid receipt → PDF preview → native Save → native Share cancellation → Next sale.
- UPI: recalled customer → Tata Salt → ₹56 invoice with UPI selected → collection retains UPI → missing-reference error with Confirm above keyboard at font scale 1.6 → ₹20 and ₹36 synthetic collections → paid receipt displaying both UPI references.
- Navigation: products Back restores customer details; Profile → Documents/Files → Back preserves those details; Close prompts Keep editing/Discard sale; only the final unsaved test draft was discarded.
- Landscape customer entry, products and review were exercised. Enlarged text customer, product, review, collection and receipt screens were exercised. Original font scale 1.0, portrait rotation 0 and auto-rotate 1 were restored.
- Sales retains older invoices and the two new review invoices. Test sales increased the store total by exactly ₹220; unpaid total returned to its starting ₹88,586.50.

## Review records retained

| Invoice | Total | Recorded collections |
|---|---:|---|
| INV-ORD-1789540229577407 | ₹164 | Cash ₹64 + ₹100 |
| INV-ORD-1789540771068598 | ₹56 | UPI ₹20 + ₹36 |

UPI references: QAUPI202609163101 and QAUPI202609163102. These are synthetic review records, not actual transfers.

The saved PDF uses the approved seller + customer/business + invoice filename: `TEST-Store-·-1000-orders_QA-Repair-Grocery_INV-ORD-1789540229577407.pdf`. A copy is included as `cash-invoice.pdf`.

## Validation and baseline

- Application implementation: `04d09a0db90df67cb3e6c66c31d10601990d8802`.
- Installed integration: `21977bff27cf22bfadb50f592a635355bb80574e`; source branch and integration were preserved and pushed. Integration checkout was clean after device testing.
- Static analysis, targeted ledger/PDF checks and one full regression cycle passed: 2,637 passed, 83 existing skips, zero failures.
- The second repeated cycle was stopped and remaining governance-only gates were skipped on your instruction. They are not claimed passed.
- APK version 1.0.0-r66.32-runtime / 2026091602. Signature and installed APK hash matched. No uninstall or data clear.

## Remaining limits

- CF-12 remains partially open: a cold review launch still requires workspace recovery. Production authentication/session restoration and OS process-death resume are not qualified here.
- Landscape payment completion, physical external scanner hardware, real UPI settlement, backend-issued PDFs and external recipient delivery were not qualified by this replay.
- Existing backend/security blockers remain outside this counter UI handoff. This is a review APK, not a production release approval.
- The enlarged keyboard screen keeps the action reachable; supporting copy can require scrolling. See actual screenshots for design approval.

See `defect-retest.csv` for each audited defect and `review-gallery.html` for screenshots. No new approval is inferred from these tests.
