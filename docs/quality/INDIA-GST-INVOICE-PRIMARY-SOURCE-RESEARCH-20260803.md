# India GST and invoice primary-source research

Date checked: 3 August 2026 (IST)

State: **research and architecture input; not production tax configuration or
legal advice**

## Scope

This note verifies the minimum Indian GST/invoice boundaries needed before
MoolSocial connects live Buy, retailer, wholesaler, manufacturer, pharmacy,
order, payment, Purchase Book or Sales Book data. It uses Government of India,
CBIC, India Code and GSTN-authorized Invoice Registration Portal sources. A
qualified Indian GST professional must approve the issuer model, registrations,
classifications and configured policies before live transactions.

## Confirmed statutory and operational boundaries

1. A registered supplier of taxable goods issues a tax invoice before or at
   removal when the supply involves movement, or before or at delivery/making
   available in other cases. A registered supplier of taxable services issues
   within the prescribed period. The client must not decide issuance time from
   an animation, payment-success screen or locally inferred delivery state.
2. Rule 46 invoice particulars include supplier identity and GSTIN, an invoice
   serial unique for the financial year, issue date, applicable recipient
   identity, HSN/SAC, description, quantity/UQC for goods, total and taxable
   values, tax rate and tax amount, interstate place of supply, delivery
   address where different, reverse-charge indication and the applicable
   signature/digital-signature treatment. The serial is limited to sixteen
   characters and may use the permitted alphabetic, numeric, hyphen/dash and
   slash characters.
3. A registered recipient's GSTIN/UIN and address belong to the tax document.
   Rule 46 also specifies recipient/delivery details for an unregistered
   recipient where taxable value is at least Rs 50,000 and, below that value,
   when the recipient requests those details. Product UI must not silently
   promote a delivery contact into a business tax identity.
4. A composition taxpayer or registered supplier of exempt supplies issues a
   bill of supply instead of collecting tax through a tax invoice. A person who
   is not registered must not collect an amount as GST. `Tax invoice`, `bill of
   supply`, `commercial receipt` and `payment receipt` therefore cannot be one
   interchangeable client label.
5. Returns, deficient supply and value/tax corrections use linked credit or
   debit notes under section 34 and the prescribed document particulars. An
   issued invoice is not edited in place. MoolSocial needs append-only
   adjustment records linked to the original document and order lines.
6. Registered persons must retain applicable accounts and records for at least
   seventy-two months from the due date of the annual return for that year;
   proceedings or investigations can require longer retention. Electronic
   records require recoverable backups, edit/delete logs, audit trails,
   inter-linkages, record layouts and data dictionaries that can be produced on
   demand.
7. The current e-invoice mandate applies, subject to the notified entity and
   transaction exclusions, where aggregate turnover exceeded Rs 5 crore in an
   applicable preceding financial year from 2017-18; the Rs 5 crore threshold
   took effect on 1 August 2023. Eligibility is PAN/AATO and notification based,
   not a boolean guessed from one GSTIN text field.
8. E-invoicing reports an already created standard invoice to a notified IRP
   and returns an IRN plus digitally signed QR data. An e-commerce operator may
   submit on behalf of a supplier, but the supplier remains the invoice owner.
   The product must preserve the IRP request, acknowledgement, signed payload,
   IRN/QR and cancellation/error history.
9. The GSTN-authorized IRP operational advisory says that from 1 April 2025 an
   AATO of Rs 10 crore or more is subject to a 30-day reporting restriction for
   invoices, credit notes and debit notes. This is time-sensitive operational
   policy and must be refreshed from primary sources before activation.
10. Section 52 can require an e-commerce operator that collects consideration
    for taxable supplies made through it by other suppliers to collect tax at
    source on the net value specified by law. Exceptions, section 9(5) supplies,
    registration changes and multi-operator arrangements require a separately
    approved tax operating model and reconciliation ledger.

## Current source reconciliation

- `WorkWorkspace` contains only `gstReminder`; `WorkSession` contains a GSTIN
  string, attachment flag and a deterministic review gateway. This is useful
  review UI, not a production registration, status, place-of-business, AATO,
  e-invoice or authorization owner.
- `BuyV2Product` currently combines canonical product, pack and seeded seller
  presentation. It has no versioned HSN/SAC, seller GST registration, taxable
  value, place-of-supply or tax-policy snapshot.
- `BuyV2Order` has display totals and fulfilment facts but no seller-order
  aggregate, invoice ledger reference, adjustment links or tax-document state.
- Retailer/wholesale/manufacturer journeys already establish deterministic
  invoice, Purchase Book, Sales Book and GST-export interaction contracts.
  Their quality records explicitly hold live activation until invoice
  numbering, tax records, payment/order/inventory services and exports become
  server authoritative.
- The backend currently has no production Buy order/invoice domain. Adding
  invoice truth to Flutter would therefore create a second, non-authoritative
  ledger and is prohibited.

## Required production boundary

The safe architecture is:

`workspace tax identity -> seller order -> tax determination snapshot ->`
`number allocation -> immutable document -> optional IRP authentication ->`
`signed customer/business retrieval -> credit/debit-note adjustments ->`
`returns/TCS/books reconciliation`

Each seller order and applicable GST registration owns its documents. A single
customer Cart may produce multiple seller orders and multiple documents. A
platform fee, paid AI subscription or advertising charge is a separate supply
and separate invoice owner from a participant's sale of goods.

## Primary authorities

- India Code, Central Goods and Services Tax Act, 2017 (sections 31-36 and
  52): <https://www.indiacode.nic.in/handle/123456789/12697>
- CBIC tax invoice, credit and debit note rules (including invoice particulars
  and issuance): <https://cbic-gst.gov.in/gst-invoice-rules.html>
- CBIC accounts and records rules (including edit logs, backups and audit
  trails): <https://cbic-gst.gov.in/accnt-record-rules.html>
- CBIC consolidated CGST Rules PDF, Rule 46:
  <https://cbic-gst.gov.in/pdf/cgst-rules-30122017.pdf>
- GSTN-authorized IRP e-invoice mandate and threshold history:
  <https://einvoice6.gst.gov.in/content/einvoice-mandate/>
- GSTN-authorized IRP 30-day reporting restriction advisory:
  <https://einvoice6.gst.gov.in/content/revised-time-limit-for-e-invoice-reporting-for-businesses-with-aato-of-%E2%82%B910-crores-above/>
- CBIC clarification on e-invoice entity exemptions:
  <https://cbic-gst.gov.in/pdf/circular-186.pdf>

## Verification required immediately before production activation

- Current consolidated Act, Rules, notifications, circulars and GST portal/IRP
  advisories.
- MoolSocial's exact e-commerce-operator, agent, payment-collection, TCS and
  section 9(5) position per supply family.
- Supplier registration eligibility, composition/exempt status, GSTIN status,
  places of business and e-invoice applicability.
- HSN/SAC, tax rate, cess, place-of-supply, discount, freight, reverse-charge,
  invoice-copy/signature and dynamic-QR policies for each launched category.
- Required privacy notice, access control, retention, legal hold, export and
  deletion-exception wording for personal and business invoice data.

