# Scan & Pick — shared collection contract v1

Parent: RETAIL-QUICK-PICKUP-001. Behaviour: approved Revision 5 with the founder's
7 September lifetime/SKU/safety clarifications below. Wording: Copy V1, except
the explicitly updated two-sided safety notices below.
Definition owner: Codex. Consumer implementation: Cursor child 022-R5-A.
Store implementation: Codex. This version defines a common frontend boundary;
it does not implement or qualify either UI, a server endpoint or authentication.

Import `package:moolsocial/features/work/scan_and_pick_contract.dart` from both
lanes. This file is pure Dart and imports neither Work UI nor Buy code. Reuse it;
do not copy its DTOs into a second consumer contract. Codex alone edits this
shared definition and its focused cases in `test/work_production_gateway_test.dart`.
Cursor owns its scanner/order/public UI and consumer-specific tests.

## One order, two distinct actions

Paid app order with explicit `purpose: customerCollection` -> retailer packs and
brings goods to the counter -> retailer's server-issued QR -> purchasing customer
checks goods and scans from their authenticated exact order -> server authorises
-> retailer's own refreshed card shows **Matched** -> retailer physically hands
over and taps **Hand Over** -> both sides show **Collected**.

Customer authorisation is not completion. No second customer confirmation after
handover, product sticker, printed label, verbal code or merchant-only approval.
Do not infer this purpose from `paid`, `needsDelivery == false`, a generic Pickup
label or an order source string. Biker delivery and counter billing remain separate.

### Collect later; refresh the security code, not the order

The paid order and its Scan & Pick entry have **no scanner-driven collection
deadline**. The customer may return later when the store is available; the
10-minute biker delivery target does not apply. A QR or approval expiring does
not cancel the order, forfeit payment, mark it Collected or require repurchase.
An independently cancelled/refunded order must still follow its actual status.

Only the counter's security challenge/approval is short-lived, starting when the
server issues it, not when the customer buys. A ready, paid order can obtain a
fresh code later. Show code-expiry recovery on the same card/camera, not an
order-expiry countdown or another collection screen. Never extend an expired
authorisation locally. Server TTL remains a backend security decision.

## Operations and ownership

`ScanPickGateway.execute(ScanPickRequest)` is an injectable boundary, not a URL.
The authenticated transport will supply credentials out of band. No endpoint,
default fixture success, token signing, server TTL or production enablement is
defined by this file. The server must reject attempts outside these capabilities:

| Operation | Caller | Required request fields beyond common identity | Meaning |
| --- | --- | --- | --- |
| `read` | Purchasing customer or authorised store member | None | Read the exact current order's collection status. |
| `issueChallenge` | Authorised store member | `operationId`, `expectedRevision` | Issue/refresh the QR only for a paid, ready, non-terminal collection order. |
| `authorise` | Authenticated purchasing customer only | `operationId`, `expectedRevision`, `qrPayload` | Validate the scanned challenge for this purchaser/order/store; record approval, not completion. |
| `handOver` | Authorised store member only | `operationId`, `expectedRevision`, `approvalId` | Revalidate authority and atomically complete this order once. |
| `reconcile` | The authorised original operation caller | `operationId` | Resolve the outcome of that exact operation and current order; never submit a replacement completion. |

Every request includes `protocolVersion: 1`, `purpose: customerCollection`,
`requestId`, `orderId` and `storeId`. Identity is an expected target, never a grant.
The server derives the signed-in account and store permission from credentials.
Do not accept client `approved`, `matched`, `paid`, `ready`, OTP, account-role or
merchant credential fields as collection authority. Old endpoints must enforce
the same guard for these orders; frontend button disabling is insufficient.

## Request examples

These IDs are synthetic examples, not endpoints or test credentials. A new
transport attempt has a fresh `requestId`; retries of the same mutation retain
the same `operationId` and immutable original request body apart from requestId.

```json
[
  {"protocolVersion":1,"purpose":"customerCollection","operation":"read","requestId":"read-1","orderId":"order-1","storeId":"store-1"},
  {"protocolVersion":1,"purpose":"customerCollection","operation":"issueChallenge","requestId":"issue-1","operationId":"op-issue","orderId":"order-1","storeId":"store-1","expectedRevision":"revision-1"},
  {"protocolVersion":1,"purpose":"customerCollection","operation":"authorise","requestId":"scan-1","operationId":"op-scan","orderId":"order-1","storeId":"store-1","expectedRevision":"revision-2","qrPayload":"opaque-example-token"},
  {"protocolVersion":1,"purpose":"customerCollection","operation":"handOver","requestId":"hand-1","operationId":"op-hand","orderId":"order-1","storeId":"store-1","expectedRevision":"revision-3","approvalId":"approval-1"},
  {"protocolVersion":1,"purpose":"customerCollection","operation":"reconcile","requestId":"reconcile-1","operationId":"op-hand","orderId":"order-1","storeId":"store-1"}
]
```

The scanner passes the opaque QR payload unchanged to `authorise`; it must not
search the catalogue, launch a URL, invent an order from QR text or accept a
manually entered verbal code. Its expected order/store come from the signed-in
order entry, not from an untrusted QR. The shared v1 transport ceiling is **1024
UTF-8 bytes**, checked on scanned input and returned challenge payload without
truncation. The accepted backend must choose an opaque encoding within that bound
and the actual renderer/scanner's tested capacity. This bound is not a QR
readability guarantee. No parser or local token generator is authorised here.

## Result envelope and authoritative snapshot

Results echo `protocolVersion`, `operation`, `requestId` and `operationId` for
mutations/reconciliation. `outcome` is `snapshot`, `rejected` or `unknown`.
Unknown enum values, missing required fields, unsupported purpose/version and
inconsistent terminal/matched state throw FormatException, never local success.
The adapter must turn malformed responses into an honest unavailable/retry state.

Example complete retailer response after issuing a QR:

```json
{
  "protocolVersion":1,
  "operation":"issueChallenge",
  "requestId":"issue-1",
  "operationId":"op-issue",
  "outcome":"snapshot",
  "snapshot":{
    "purpose":"customerCollection",
    "orderId":"order-1",
    "storeId":"store-1",
    "purchaserAccountId":"customer-1",
    "customerName":"Example customer",
    "storeName":"Example store",
    "revision":"revision-2",
    "serverTime":"2026-09-07T10:00:00Z",
    "state":"awaitingCustomer",
    "payment":"paid",
    "readiness":"ready",
    "currency":"INR",
    "totalMinor":120000,
    "lines":[{"lineId":"line-1","productId":"product-1","skuId":"rice-5kg-sku-1","name":"Rice","pack":"5 kg bag","quantity":"2","amountMinor":120000}],
    "challenge":{"id":"challenge-1","qrPayload":"opaque-example-token","expiresAt":"2026-09-07T10:01:00Z"}
  }
}
```

Consumer `read` may return challenge `id` and `expiresAt`, but **must omit
qrPayload**. Consumer status is not a channel for obtaining the retailer's QR
without scanning. Store never obtains authority to act as the purchasing account.

State-specific snapshot fields (all common identity, commercial and time fields
above remain present; these rows are not standalone JSON responses):

| `state` | Additional fields | Visible action |
| --- | --- | --- |
| `preparing` | No challenge, approval or receipt | Packing; no QR or handover. |
| `ready` | No challenge, approval or receipt | Store may request a QR. |
| `awaitingCustomer` | `challenge: {id, expiresAt, qrPayload?}` | Show QR only on retailer card; Hand Over locked. |
| `matched` | `approval: {id, expiresAt}`; omit challenge | Matched; request Hand Over only while authoritative conditions remain valid. |
| `collected` | `receipt: {id, collectedAt, invoiceReference?}`; no challenge/approval | Collected; no second completion. |
| `cancelled` | No challenge, approval or receipt | No collection action. |

Successful `authorise` returns a `matched` snapshot, never `collected` as a new
side effect. If it discovers an already completed order, return its existing
Collected receipt without completing again. Successful `handOver` and settled
reconciliation return the same authoritative `collected` receipt. A later refund
may change payment to `refunded`, but must not erase a completed receipt or enable
another handover. Approval/challenge expiry may never undo committed completion.

Money is exact integer **minor units (paise)**, `currency: INR`, within JSON's
exact-integer range. Do not display `totalMinor` as rupees or silently round away
paise. The parser supports 1000–10000 crore amounts. Quantity is an exact positive
decimal string, including fractional sales; never round it to Work's old integer
quantity map. Purchased names, packs, quantities and amounts are immutable order
facts, not a fresh lookup of the editable catalogue. Every line requires both
`productId` and the exact purchased variant/pack `skuId`; a generic product or
store code cannot identify the collection. Total may include charges or
discounts; no assumption that line sums equal invoice total.

## Identity, freshness and security boundary

- Every caller validates the result against its request using `validateFor`.
  Consumer passes `client: consumer` and the current authenticated purchaser ID;
  Store passes `client: retailer`. This is a client guard, not server permission.
- Both clients discard replies after account/session epoch, workspace, selected
  order or relevant request changes. Never paint one order's Matched on another.
  Only a successful, current response can enable an action. An optional snapshot
  in a rejection is recovery data, not permission to complete.
- Revisions are opaque equality tokens. Mutations use the current observed
  revision; do not increment or compare them lexically. Revision conflict requires
  a fresh read and deliberate re-evaluation, not an automatic new handover intent.
- UTC server times and expiry values control challenge/approval validity. Use
  strict `YYYY-MM-DDTHH:mm:ss[.1–6 fractional digits]Z`; invalid calendar/time
  components must fail rather than normalize into another date. Example
  times above do not set a one-minute production TTL. Use monotonic elapsed time
  from serverTime for display; re-read after resume, reconnect or process restart.
  A cached Matched state never unlocks Hand Over after relaunch.
- Only a successful current result, correlated to its request, with a `matched`,
  paid, ready snapshot and unexpired approval makes result-level
  `canRequestHandOver(request, estimatedServerNow)` true. A rejected Matched
  recovery snapshot cannot enable it. Server rechecks purchaser/store/order/purpose,
  payment/readiness/revision/expiry/permission and terminal state on every request.
- The server binds every challenge and approval to the purchasing account,
  exact order/store, collection purpose, current revision and immutable purchased
  line IDs/SKU IDs/packs/quantities/amounts. A changed item, substitution or refund
  invalidates earlier approval. The QR need not expose these facts publicly;
  binding is authoritative server state, not trusting strings in a scanned code.
- Backend must reject approval by merchant-only credentials, wrong purchaser,
  wrong order/store, unpaid/refunded/cancelled/not-ready orders, altered/replayed/
  expired QR or approval, and older direct-completion APIs for collection orders.
- Tokens and approval IDs are not logged, placed in analytics or cached as durable
  authority. No QR proves physical presence or correct goods by itself; preserve
  dispute/issue recovery and independent payment/settlement restrictions.

## Retries, errors and reconciliation

Every mutation needs durable operation identity across Back/process restart.
Persist its target/order/store/account scope and original payload fingerprint,
not permission to complete. Same ID with changed business payload must fail
`operationConflict`. `requestId` is correlation only, not the idempotency key.

After timeout/disconnection/malformed mutation reply, the outcome is **unknown**,
not failed/successful. Lock another mutation and reconcile the original operation.
Do not generate a new handover ID or repeat local stock/invoice/balance effects.
Server must ensure **one completion per order even with different operation IDs,
concurrent devices and old clients**, not merely deduplicate identical requests.
Replayed operations report current terminal facts; they cannot revive an expired
approval or undo completion. Fresh QR refresh is a deliberate new issue intent
that invalidates the old challenge atomically; it cannot race past completion.

### Abuse cases and release checks

| Risk | Required prevention / recovery |
| --- | --- |
| Copied QR, wrong customer/store/order, staff approving their own customer | Authenticate the purchaser; object-level permissions on every operation; exact challenge binding. Retailer credentials cannot call customer authorise. QR possession alone is insufficient. |
| Same product, different SKU/pack/quantity or substituted bag | Preserve purchased SKU facts, invalidate approval on authoritative order changes; show the full goods list for inspection. Software cannot prove the physical bag matches it. |
| Old QR, replay or refreshed code | Server expiry and atomic replacement/consumption. An old token cannot create a new approval; a retry reconciles the original operation. No order cancellation merely from token expiry. |
| Refund/cancel races with scan or physical handover | Serialize order/payment/approval/completion decisions server-side. Protect the Matched-to-handover interval and resolve in-flight collection before allowing a conflicting refund. Expiry, silence or disconnection alone must not decide who loses money. |
| Duplicate callbacks, two store devices, different retry IDs, old completion API | One terminal collection per order across all APIs; exactly-once stock/payment/invoice/settlement effects, beyond request-id deduplication. |
| Goods passed but connection drops before confirmation | Keep the original operation identity; no second handover or local payout. Reconcile the authoritative receipt; expose an issue/recovery route if the result cannot be resolved. |
| Account/store/order changed while response was in flight | Discard by session epoch and active order/store before rendering or acting; clear cached authority after Back/relaunch. |
| Defective goods, incorrect physical items, compromised account or collusion | Preserve evidence and an order-specific dispute path; no waiver of consumer remedies and no claim that QR proves presence, contents or prevents every theft. |

These are backend/integration **release requirements**, not proven protection
from DTO tests. Use authenticated adversarial tests for all rows before public
activation. No production attack, real payment or customer account is used here.
Technical basis: [OWASP transaction authorisation](https://cheatsheetseries.owasp.org/cheatsheets/Transaction_Authorization_Cheat_Sheet.html)
and [object-level authorisation](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/).

```json
[
  {"protocolVersion":1,"operation":"handOver","requestId":"hand-1","operationId":"op-hand","outcome":"unknown"},
  {"protocolVersion":1,"operation":"authorise","requestId":"scan-1","operationId":"op-scan","outcome":"rejected","error":"challengeExpired"}
]
```

| Error codes | Required recovery; never silent completion |
| --- | --- |
| `unauthenticated` | Restore sign-in and the same order, then re-read. |
| `forbidden`, `wrongPurchaser`, `wrongOrder`, `wrongStore`, `unsupportedPurpose` | Stop this attempt; show the appropriate exact-order/account recovery. |
| `paymentRequired`, `paymentChanged`, `notReady`, `revisionConflict` | Re-read authoritative facts; return to applicable payment/packing/order action. |
| `challengeExpired`, `challengeInvalid`, `challengeConsumed` | No authorisation. Refresh order first; retailer may explicitly issue a new code if still eligible. |
| `approvalMissing`, `approvalExpired` | Hand Over remains locked; refresh exact order. A new customer scan is required if approval is no longer valid. |
| `cancelled` | Show cancelled; do not collect. |
| `alreadyCollected` | Must include authoritative `collected` snapshot/receipt; never increment anything again. |
| `operationInProgress`, `operationConflict` | Reconcile original operation; never treat conflict as a new sale. |
| `rateLimited`, `unavailable` | Honest unavailable/retry state, preserve context. Read/reconcile before another mutation. |

Transport offline/errors and malformed responses are adapter failures, not invented
server error codes. Retry reads safely; after an attempted mutation preserve its
unknown outcome and reconcile. Polling/subscriptions must be scoped to the exact
account/store/order, stop when left, and never move a button under a finger.

## UI wording and return contract

Founder interaction requirement: existing screens change state; do not add a
collection landing page, separate success page or redundant confirmation taps.

| Step | Customer's existing paid order | Retailer's existing central order card |
| --- | --- | --- |
| Packing | Order status updates; no collection action yet. | Existing acceptance/packing actions and purchased items. |
| Ready | **Scan & Pick** is available from this exact signed-in order. | After authoritative readiness, issue the initial QR automatically with a stable operation ID; do not add a Show QR tap. |
| Scan | One tap opens the order-specific native camera; automatic scan, no shutter or Confirm tap. | Same QR/card: Waiting for customer scan. |
| Validation | Guard duplicate scanner callbacks; show pending state and restore the same order after the result. | Same card waits for authoritative status; no notification tap required. |
| Matched | Same order shows Matched; no second customer approval action. | Same card enables **Hand Over**. Retailer physically passes the goods, then taps once. |
| Collected | Same order updates automatically with the receipt. | Same card shows Collected; no additional completion screen. |

Normal incremental collection taps: customer **one** from the already-open paid
order; retailer **one Hand Over** after existing packing/ready actions. Physical
goods inspection/scanning is still required. Existing shopping/payment and
order-opening taps are not hidden from the complete journey count. QR expiry,
offline recovery and account/order mismatch may need a deliberate extra recovery
action, but remain in the same order/card/camera surfaces. Cancel/Back must return
to the exact order without approval or completion. Do not auto-replace the code
while a customer is scanning or move the Hand Over button during live updates.

Founder friction requirement: safety adds **no routine interaction**. Do not add
OTP entry, a safety checkbox, an Accept terms button, a disclaimer modal, a
second scan or a post-scan customer confirmation. Initial issue, duplicate-scan
suppression, authoritative validation and status refresh run in the background.
Show each concise notice once in its relevant existing surface, not as repeated
cards. Prevent duplicate requests while preserving clear progress and Back.
An actual mismatch, expired authority or unresolved network outcome may require
same-surface recovery; never remove the check or invent success to hide waiting.

Consumer: **Scan & Pick** / **Collect at store**. “Pay in the app. Collect at the
store.” “Check your items, then scan the code on the retailer's screen.” “Scan
only at the counter, when your items are ready.” Cursor defines its exact route
and order-bound scanner entry and returns that route/commit; this document does
not invent a Buy deep link. Back/cancel restores the same order without approval.

Store: reuse the existing selected central card. “Scan & Pick orders appear here
automatically.” QR: “Ask the customer to scan this code from their order.” Stable
action safety: “Hand over only when this screen shows Matched.” State copy:
“Waiting for customer scan.” / “Waiting for confirmation.” / “Matched. You can
hand over this order.” / “Checking collection status...” / “Collected.” Keep
safety text fully readable at 200%; no new tutorial screen or permanent rail.

### Two-sided safety notices — founder update, 7 September

Customer, beside Scan & Pick / the order-specific scanner:
**Check your items before scanning at the counter. Your rights for faulty or
incorrect goods remain.**

Retailer, beside QR / Matched / Hand Over on the same card:
**Hand over only after Matched. Confirm Hand Over after giving the goods.
Payout remains pending until collection is confirmed.**

Keep these inline and readable, not a checkbox, blocking disclaimer or extra
screen. A scan authorises collection; it is not acknowledgement of physical
receipt, acceptance of hidden defects or a liability waiver. Do not use
“MoolSocial is not responsible after scanning.” This is consistent with defective
goods remedies in [Rule 6(3), Consumer Protection (E-Commerce) Rules, 2020](https://static.investindia.gov.in/s3fs-public/2020-07/220661_7.pdf).
Final terms and disputed handovers require appropriate legal review.

The retailer payout sentence is a required server/settlement condition, **not
currently implemented enforcement or a promise of immediate payout** after
scanning/collection. No confirmed collection means no automatic release; retain
dispute/reconciliation handling and applicable settlement checks. Never erase a
legitimate receivable or automatically penalise a network failure.

## Git dependency ledger and acceptance

1. Codex owns this definition/document and Store adapter/card/tests. Cursor owns
   child 022-R5-A consumer/public UI/scanner/navigation/Redmi and its tests. These
   two new exact shared-definition owners are recorded in Codex's current claim;
   no Buy owner is transferred. Consumer must report the version it consumes.
   For independent compilation before integration, coordinate adoption of only
   the exact committed contract Dart blob as a read-only Codex-owned dependency
   in Cursor's existing claim; do not cherry-pick the whole Codex commit, copy
   its registry/test owners or merge Store code. Record the imported blob/version
   in Cursor's ledger. Any definition edit returns to Codex, not a forked schema.
2. Agree v1 with Cursor before integration. Requested changes return to Codex as
   one owner; incompatible changes require a new version, not a parallel schema.
3. Store UI/session/gateway integration is **pending**. Existing generic pickup
   and six-digit code helpers are not this capability. Guard every direct/helper
   path for explicit collection orders while preserving biker/counter behaviour.
4. Consumer 022-R5-A remains **pending** at inspected committed Cursor tip
   `ad0526240e0e6a3980aa9686ffea751f4272e490`. Its five dirty files are Cart repairs,
   as Cursor confirmed; none was copied, edited or integrated by Codex.
5. Backend endpoint/role validation/payment/readiness/revision enforcement,
   challenge signing/expiry, order-wide exactly-once effects and durable
   reconciliation, cancellation/refund race protection and collection-conditioned
   payout release remain **pending**, under a later authorised backend owner.
   No schema, credentials, deployment or live calls are part of this definition.
6. Public-store link/auth/install/exact-order resume remains linked to
   STORE-LINK-CUSTOMER-RESUME-01. Notification delivery is separate; a message is
   never approval. No WhatsApp messages/tests or live payments are authorised.
7. Definition tests prove only parsing, payload shape and client guard semantics.
   Integrated acceptance requires authenticated consumer scan -> Store Matched ->
   Hand Over -> both Collected, normal/200%, Back/relaunch/order switching,
   unpaid/cancelled/wrong account/store/order, expiry/replay, simultaneous retries,
   uncertain results and unchanged biker journey. Exactly one stock, payment,
   invoice, settlement and completion effect must be proven against authority.
8. Do not mark the complete feature production-ready or enable public collection
   based on fixture success. Latest OPPO review and future integrated qualification
   remain separate. No branch integration is performed by this contract commit.
