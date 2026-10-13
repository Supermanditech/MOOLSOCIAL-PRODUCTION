# Founder invoice-format references - 22 September 2026

## Decision and approval boundary

Founder: invoice format must match these three supplied PDF references; keep the
requirement in durable memory. Existing invoice SCREEN remains visually approved.
This is a format requirement, not approval of the current simple review PDF as the
final invoice format. Do not reopen the approved screen, create three new app
screens, or treat the invoice-format ticket as complete from seller-name/address
wiring alone. The reference-format frontend increment below supersedes the
earlier requirements-only status. Founder approved all three v5 PDF formats after
they were presented in the Codex right panel. Preserve this approved structure;
approval does not establish backend issuance, tax compliance or device acceptance.

Use these references within the existing invoice/document work, not duplicate
invoice systems or duplicate defect tickets. Distinguish each document's issuer
and purpose. Do not automatically issue all three for every Counter Sale: generate
only documents supported by the actual sale, applicable fees and issuance rules.

## Inspected sources

All three originals were read visually in full using the PDF skill. Each is one
US Letter page (612 x 792 pt). Original files remain unchanged and local; do NOT
check customer data, supplier identity, tax IDs or signatures from them into Git.
These paths contain literal underscores (the chat escaped them as backslash-underscore).

| Local source | Purpose | SHA-256 |
| --- | --- | --- |
| C:/Users/jisal/Downloads/User_Charge_Invoice8482434621.pdf | Platform/service fee tax invoice | 97C084EC2967050EE62C152C3B1756C7AE338B7B9D7457805B5329D030368BEE |
| C:/Users/jisal/Downloads/Order_Invoice8482434621.pdf | Seller/order tax invoice | 890B14D6B52FB8E5DABF3AC9318666F6554B060D9540A9AA2FF25CEDAEEFE46E |
| C:/Users/jisal/Downloads/Order_ID_8482434621.pdf | Order summary and receipt | 4900958F0CB46BF9E403CE69724C38C4826846DECBD59B2060D7BC4E8C482DBD |

If originals become unavailable, use the requirements below for continuity, but
request the original files again before claiming pixel/layout parity.

## Format requirements by document

### Platform/service fee invoice

- Brand at top, document title and recipient-copy designation.
- Banded legal-issuer heading; compact two-column identity section: address,
  state, contact email, invoice number/date, applicable PAN/CIN/GSTIN.
- Customer band: name, delivery/billing address as applicable, GST registration
  state and place of supply. Never invent a registration or assume unregistered.
- Service details band with applicable HSN/SAC and supply description.
- Bordered table: serial, particulars, taxable amount, tax components and total;
  clear total row. Keep platform fees distinct from seller goods charges.
- Linked order/date, truthful payment statement, applicable reverse-charge note,
  issuer/signatory block, communication address and terms footer.

### Seller/order invoice

- Brand, tax/document title and recipient-copy designation; correct seller legal
  entity, trading Store name/address, applicable GST/FSSAI, invoice number/date.
- Customer/address and state/place-of-supply block; classification and description.
- Dense ruled table: item/quantity particulars, gross value, discount, net taxable
  value, tax rate and tax amount columns, total; item subtotal and grand total.
- Amount in words, order/payment reference, appropriate tax/issuance notes,
  applicable issuing-entity details and authorised signatory/footer.
- The reference's 'on behalf of' arrangement and restaurant-specific legal text
  are examples, NOT authority for MoolSocial to issue for every retailer. Do not
  copy another company's signature, tax registration, advertising banner or URLs.

### Order summary / receipt

- Clear summary/receipt heading, order ID/time, customer/address, Store/name/address
  and delivery partner only when applicable.
- Table with item, quantity, unit price and line total; shaded header, clean rules.
- Right-aligned breakdown for applicable round-off, taxes, delivery charges,
  platform fees, delivery discounts, coupon discounts and final total.
- Relevant terms, support/safety information and applicable registration footer.
- Summary is not a substitute for the seller/platform tax documents. 'Receipt'
  and payment-received wording must reflect actual confirmed payment state.

## Shared implementation constraints

- Match information hierarchy, compact alignment, table structure and document
  distinctions; use MoolSocial branding, white/navy and restrained neutral bands.
  Do not reproduce excess blank space, clipped content or inconsistent alignment.
- Numeric amounts use existing integer minor-unit arithmetic and consistent
  formatting. The reference fee table visibly leaks a floating-point tail; do
  NOT reproduce that defect. Totals, amount-in-words and payment breakdown must
  reconcile with authoritative invoice/order records, including discounts/rounding.
- Paid, part-paid, unpaid and due remain separate facts from invoice creation or
  successful delivery. Never copy the reference's 'settled digitally' text into
  unpaid, Cash, failed or pending transactions.
- Seller identity/address comes from immutable issue-time Store snapshots, not
  later settings. Buyer details remain separate. Platform identity is separately
  owned, not copied from the retailer or another invoice.
- Applicable tax component columns (including IGST where supplied) are driven by
  authoritative data, not hard-coded sample rates or restaurant classifications.
- Keep existing invoice history/PDF entry; no customer-preview page or forced
  per-SKU downloads. Reuse common document layout/formatting and shared models.
- New fixtures must be fictional and explicitly review-only. Keep the existing
  PREVIEW/NOT ISSUED boundary until real issuance is implemented.

## Responsibility and acceptance

Frontend next implementation: reusable document layouts, source-field mapping,
conditional sections, accessible PDF viewing, normal/enlarged app text, long
names/addresses, many rows/repeated table headers/page numbers, font coverage,
two-decimal currency/rounding and visible absence/error behavior. Render actual
generated PDFs and visually compare each relevant template before founder review.

Backend deferred: issuer authority, validated registrations/tax applicability,
invoice numbering, immutable verified snapshots, calculation/rounding authority,
payment/settlement confirmation, fee ownership, document storage/retrieval and
automatic WhatsApp/MoolSocial delivery. Reference files alone do not establish
legal compliance, audit suitability or entitlement to sign/issue a tax invoice.

## Implemented reference-format increment - founder approved

Shared owners: apps/mobile/lib/shared/commerce/commerce_invoice_document.dart and
commerce_invoice_pdf.dart. The existing Work invoice PDF adapter now uses them;
approved app screens remain unchanged. Seller/order, platform-fee and summary
formats share validation, integer minor-unit totals, scoped document identity,
conditional tax columns, amount-in-words and multipage table rendering. Supplied
issuer/recipient roles support retailer-to-customer, supplier-to-retailer and
platform fees to customer/retailer/supplier without cloning invoice screens.
Existing review-only source selection is preserved; release issuance is unavailable.

Local evidence: task outputs/commerce-invoice-formats-v3-tests.log (376 passed,
four inherited skips), commerce-invoice-journey-tests.log (nine passed), and final
commerce-invoice-formats-v5-tests.log (22 passed). Actual sample PDFs are under
task output/pdf/commerce-invoice-formats-v5. Include large-value, long-identity,
50-line wholesale and platform-to-retailer samples in visual QA. These are
fictional PREVIEW/NOT ISSUED samples, not legally issued or production documents.

## Founder extension: all applicable parties and Download Centre

The same applicable document types/formats must be used across Buy, Wholesale,
MoolSocial and Store: customer, retailer and wholesale supplier downloads. The
invoice's actual issuing entity and recipient determine the data, not the module
name. A sale's goods invoice, MoolSocial fee invoice and summary are distinct;
do not automatically create all three when no fee or issuance record exists.
Platform-to-retailer/supplier service invoices must never inherit a customer's
name/address from the goods order. A platform marketplace role alone does not
make MoolSocial the seller. Settlements, statements and credit notes are distinct
document types, not renamed copies of these invoices.

Update: the shared Downloads frontend is now implemented locally and visually
approved. See `COMMERCE-DOWNLOADS-FRONTEND-20260922.md` for current integration
coverage, final tests, and explicitly pending public/customer document sources.
This supersedes the hub-not-implemented status below, not the pending adapters.

Original next FRONTEND batch: reuse the existing document/history
entry points and Reports & Downloads work for a role-scoped Download Centre.
Keep contextual download beside the relevant invoice/order as well as the central
destination. Expose only applicable documents for the current account/workspace;
customer documents must not expose retailer commission or private settlement data.
Provide type/date/order filtering and loading, empty, unavailable, error, retry
and cancelled-download states. Preserve existing single-tap saving behavior.
Do not create three independent renderers or count this as a new duplicate defect.

Public Buy/Wholesale consumer adapters and Download Centre wiring are pending
frontend work, not merely a backend dependency. Before wiring, compare Cursor's
then-current integrated contracts read-only, verify every money field's unit and
convert exactly once into integer minor units. In particular, do not blindly map
BuyV2TaxInvoiceLine whole-rupee fields into these minor-unit values. The shared
contract is not authorization: backend retrieval must enforce issuer/recipient
access and supply immutable, verified issuance/payment records. Backend issuance,
history/persistence, access enforcement and automatic delivery remain deferred.

No backend, APK/device test, commit/push or Cursor checkout change in this increment.
