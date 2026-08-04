# ADR-0010: GST invoice snapshot and seller tax identity

Status: **FOUNDER DUAL OPERATING MODEL SELECTED — Indian GST counsel and finance validation still required**

Prepared: 3 August 2026

Founder amendment, 4 August 2026: platform/agent is the default assigned model;
SuperMandi purchase/resale is the alternate assigned model across Shop,
Wholesale and Medicine. Assignment is effective-dated and frozen into the
offer/order. Exact decision and unresolved legal gates are preserved in
`artifacts/quality/production-foundation-founder-decisions-20260804-153`.

## Context

The approved Buy model uses one canonical catalogue, many participant offers
and supplier-specific fulfilment. Existing deterministic retailer,
wholesale and manufacturer screens demonstrate invoices and books, but no
production backend owns seller tax identity, tax determination, numbering,
e-invoice authentication, adjustments, retention or TCS reconciliation.

The mobile `WorkSession.gstin` string and seeded `BuyV2Order` cannot lawfully
or operationally become that owner. GST rules are time-sensitive and differ by
supplier, registration, supply, document kind and transaction.

Research authority:
`docs/quality/INDIA-GST-INVOICE-PRIMARY-SOURCE-RESEARCH-20260803.md`.

## Proposed decision

### 1. Supplier workspace is the invoice owner

The verified participant workspace and exact GST registration/place of
business that makes the supply owns the participant tax document. MoolSocial
acts as platform/technology operator and may submit to an IRP on the supplier's
authorized behalf. MoolSocial becomes merchant of record or principal only
through a separate founder/legal/finance decision naming the exact supply.

A platform subscription, paid AI service, promotion fee or other MoolSocial
service has its own MoolSocial seller record and invoice. It never shares a
participant's goods invoice number or tax snapshot.

### 2. One Cart may yield multiple legal documents

Checkout creates seller-specific order aggregates. Shop, Medicine and
Wholesale remain separately inspectable, and seller/GST-registration splits
remain explicit. Each seller order receives its own applicable tax invoice,
bill of supply or commercial/payment receipt. The client may group downloads
for convenience but must not fabricate one merged invoice.

### 3. Versioned workspace tax identity

The server owns a versioned `WorkspaceTaxIdentity` with at least:

- workspace and legal-entity identifiers;
- GSTIN, legal/trade name, registration/status and effective dates;
- principal/additional place-of-business and state codes;
- composition/exempt/regular and category capability facts;
- PAN-scoped AATO/e-invoice eligibility decision with authority/effective date;
- authorized invoice series, IRP credentials/provider reference and roles;
- verification case, evidence hashes, reviewer and audit history; and
- suspension/revocation behavior that fails closed for new taxable supply.

The Flutter review model may display a projection but cannot verify or mutate
these facts directly.

### 4. Immutable tax determination snapshot

Before issuance the backend derives and freezes a policy-versioned snapshot
for every seller order and line: supplier/recipient/delivery identities,
place of supply, HSN/SAC/UQC, description, quantity, gross and taxable values,
discount/freight allocation, CGST/SGST/UTGST/IGST/cess rates and amounts,
reverse-charge flag, rounding and source offer/order/payment references.

Rates, classification and eligibility are configuration records with
effective dates and legal source references. Widgets never hard-code them as
production truth.

### 5. Append-only document ledger

The server allocates an idempotent, concurrency-safe serial per supplier GST
registration, financial year and approved series. The document aggregate
stores its immutable snapshot, render version, content hash, issued timestamp,
issuer identity and source event. An issued document is never overwritten.

Returns and corrections create linked credit/debit notes with their own
serials, snapshots and reconciliation states. Duplicate commands return the
original document.

### 6. E-invoice adapter fails closed

Where the current eligibility policy requires e-invoicing, issuance enters an
explicit `awaiting_irp`, `authenticated`, `rejected`, `cancelled` or
`manual_review` state. Only the authenticated record may be presented as the
final e-invoice. The adapter retains request/response hashes, IRN, signed QR,
acknowledgement/cancellation facts and deadline alerts without putting IRP
credentials on the device.

### 7. Retrieval, retention and audit

Customers and authorized workspace roles receive a server-authorized,
short-lived download/share capability for the exact immutable render. Personal
and business invoice access are distinct. The ledger keeps backups, edit logs,
data dictionary, inter-linkages, legal holds and the configured statutory
retention period. Deletion workflows must preserve records under a valid tax
or legal-retention exception while minimizing unrelated personal data.

### 8. ECO/TCS and books are projections from the same events

TCS applicability, collection, returns, settlement and seller cash-ledger
reconciliation use the same seller-order, return and consideration events.
Sales Book, Purchase Book, Business Book and GST exports are read models; none
is a second invoice or payment ledger.

## Rejected alternatives

- Generate invoice numbers in Flutter or from order-display IDs.
- Treat the delivery address as the buyer tax identity.
- Merge multiple sellers into one participant invoice.
- Edit an issued PDF after a return, GSTIN change or price correction.
- Hard-code e-invoice turnover thresholds or reporting windows in the app.
- Show a seeded `GST invoice` download before a server document exists.
- Let Sales Book, Purchase Book and checkout maintain separate tax totals.

## Approval and implementation gate

No runtime implementation is authorized by this proposal. Founder approval
must select the marketplace/agent/merchant-of-record model. Indian GST counsel
and finance must approve the issuer, registration, TCS, classification,
place-of-supply, e-invoice and retention policies. Only then may the backend
contracts in the production-foundation ticket register begin, followed by
deterministic contract tests, Dev sandbox proof, founder-reviewed UI and the
normal Staging/Production release gates.
