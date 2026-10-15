# LF-10 — Selling-Store customer-order frontend

Founder accepted6f881a8f and approved Batch10. Reuse existing selling-Store order
list/detail, scoped commands/journal, packing and original invoice facts. No new
screen, business engine, actual order/action, backend, APK or operator workspace.

## Source-backed disposition

WorkOrderOperations/WorkOrderReply already bind accountScope/workspaceId/orderId,
revision and operationId; commands are accept/ready/reject/requestTime. Durable
pending-store recovery and read-only reconciliation already exist. WorkSession
projects only the correct Store controller and does not post Stock/money/invoices
from replies. Collection uses its own authenticated controller. Preserve these.

WorkspaceOrderRecord supplies customer display/billing details, summary and exact
quantities, original itemSnapshots (productId/name/pack/quantity/unit/line prices),
amount/paise/discount, source, fulfilment, payment label, recipient address,
stage/timestamps/deadlines and collection Store scope. Existing exact-order UI
prefers complete purchased snapshots; missing legacy prices are explicitly absent,
not reconstructed from today's Stock. Test that behavior; do not redesign it.

Concrete gap: WorkOrderOperations._belongs checks only amount>=0, not the existing
validBillAmounts predicate. A malformed paise component or discount can therefore
enter the Store projection or resolve an operation. Demonstrate before correction;
reuse that predicate, never clamp/reprice the provider reply or infer payment.

## Verification / acceptance plan

Malformed observe/command/reconcile replies preserve last accepted order and the
original pending command. Valid fractional and discounted totals remain exact.
Run existing wrong-account/Store, stale reply, separate orders, repeated action,
durable journal and packing tests. Confirm exact item/quantity/price facts survive
current catalogue changes, and missing snapshots stay honest. Exercise existing
order widgets at relevant text sizes. Hot-reload OPPO, verify current loaded source
and passively inspect available Store order surfaces; do not create or act on an
order or its payment. Preserve Cart164, Stock and saved identities. Review before11.

## Explicit mapping/service dependencies

No live public Buy→Store customer-order adapter/feed is established by these hooks.
The account/Store/suborder/SKU mapping, customer consent/allowed contact, exact
selected offer/terms, notes and immutable image facts must come from the accepted
order projection; fields not in the current Store contract are not invented here.
Issued invoice/document identity/readback and customer-visible updates require
their authoritative adapters. Existing Counter sale, Restock or review records
cannot stand in for actual customer orders or provide proof of those connections.

Owner: order/Store provider integration for authenticated ingestion, permitted
capabilities, business acknowledgement, document references and customer updates;
frontend owner for supported adapter mapping/callers and truthful unavailable
presentation once that contract is supplied. Completion requires exact same order/
Store/line/amount identity across Buy, Store and issued document plus acknowledged
actions/failure recovery. Missing contract/projection, not this local validation,
keeps that live journey unimplemented. Session-only Store settings and other
earlier provider dependencies remain open; acceptance does not close them.

## Verification — 15 October 2026

19 new isolated host cases:16 malformed update/journal cases failed against the
original application and3 valid fractional/discounted/large-total controls passed.
The single existing-predicate correction passes all19. Existing DASH04/05/06
order identity, late reply, independent Store/order, journal, time and delivery
projection regressions also passed:78 total in that selected run. No business
transition, payment result or actual order was generated for native testing.

Existing exact-order/purchased-snapshot tests passed4 cases at normal/200% text,
including current catalogue price changes and incomplete legacy snapshots.
Existing scoped/restored order-card recovery widget tests passed4 cases.

OPPO showed an additional empty-state meaning defect: zero saved orders was not
qualified by unknown online coverage. A test assertion failed at all3 existing
small/normal/200%-landscape viewport cases before changing the existing body copy.
The body now says only saved orders are shown and online coverage is unverified;
history uses the same qualification. No new component, route or fixed band.
Those3 cases and the quiet-Store/no-invented-order test now pass.90 distinct
selected host tests passed across the bounded checks; no full-project claim.

Changed-file analysis: no errors/warnings,9 informational pre-existing brace-style
notices. Every reported line was compared to HEAD and is unchanged (the test
line offset reflects2 added assertions). They are not suppressed or called clean.
Diff check passed. A whole-file formatter temporarily changed unrelated legacy
test spacing; all unrelated formatting was mechanically restored, preserving only
the intended helper fields and new cases. The first combined suite invocation
used a pipe regex through flutter.bat and was parsed by cmd before tests ran;
the bounded DASH0[456] pattern ran successfully instead. Neither is app evidence.

OPPO reloaded17 libraries for the validator, then1 for empty copy. Read-only VM
Script checks confirm both changed source fragments loaded. Native inspected the
correct saved evaluation Store and its0 customer orders; screenshot in task
workspace: outputs/lf10-store-orders-20261015.png. Native order rendering,
ingestion, operational actions and issued-document access cannot be accepted from
an empty Store. No fake feed/order, Cart/payment action, data reset, APK or other
tree change was used to fill that gap. Existing saved Stock/Cart were not edited.

Context-only architect review found no concrete bounded-correction stop concern;
it emphasized preserving pending state on invalid replies and limiting native
claims to the observed empty state. Host tests prove prior order/pending command
survive invalid responses, not a successful empty result. Founder review pending
before Batch11. Full field dispositions are appended to the existing task file
outputs/store-to-buy-provider-field-map-20261015.md, not a new scope tracker.
