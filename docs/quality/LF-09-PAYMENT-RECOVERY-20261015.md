# LF-09 — Payment return and recovery

Founder accepted cf85172e and approved Batch09. One writer; current Checkout
and later-balance payment hooks only. Preserve original attempt/account/order and
amount; no backend/payment engine, redesign, APK or actual payment/status action.

## Inspected source / minimal correction

Main Checkout already captures owner/auth/operation and original submitted facts.
Later balance load/start/handoff/reconciliation instead cache by order ID and can
apply late results after owner/disposal changes. Their finally blocks can clear a
new operation, and reconciliation accepts paid0 without matching original reference.
Initiation errors become offline, allowing a due reload to enable another key.

Guard scoped balance cache/operations with existing owner/auth/procurement context
and exact order/purchase identity; use per-operation tokens for late completion.
Retain initiation key/requested amount before awaiting and known original reference.
Transport failure is unknown, never permission for a fresh payment. Reject unrelated
references and due-only readback for unresolved initiation. No inferred settlement,
new failure state hierarchy, refund/ledger posting or provider implementation.

## Acceptance

Fail before owner/disposal/late-finally and reference/uncertain-initiation gaps.
Prove valid same-owner flow, repeated-tap suppression, retained unknown context,
wrong-reference rejection, existing Checkout/QR/grouped/native-handoff recovery
and seven Cart composition protections. Host fixtures only for payment operations.
Hot-reload OPPO passively on Cart, preserving one soap164 and original pending
payment. No initiation/status query/reconciliation; founder review before Batch10.

## Explicit missing dependencies

Host fixture setup: first selected run failed compilation because the new fixture
referenced a later local productFor declaration. Correct only that fixture to an
explicit existing wholesale product; this is not application-failure evidence.

The balance adapter does not supply recovery by original initiation key or durable
attempt restoration. An unknown start without a reference cannot be resolved by
an uncorrelated pending/paid or zero-balance readback. Retain a truthful unresolved
hold; provider-correlated recovery contract and persisted readback remain required.
An in-memory guard is NOT restart-safe duplicate prevention or live qualification.
Live payment/UPI/secure Card, quotes, credit/policy, publishing and Store sync remain
unimplemented where absent. Existing screenshots/fixtures do not prove those services.

## Verification — 15 October 2026

After correcting the fixture compile setup,18 of19 initial LF09 cases failed
against the original application; repeated initiation was already protected.
An added reentrant-listener case separately demonstrated a provider read after
the owner changed during notification. The scoped correction passes20 new cases.

67 distinct selected host tests passed:22 balance cases (20 new plus2 existing),
33 T07 original-attempt/durable-write/grouped recovery cases,4 D11 mocked native
handoff cases,2 UPI and2 Card secure-handoff widget cases,2 QR layout cases, and
2 Cart widget cases exercising all seven Shop/Wholesale/Bulk compositions at
normal/200% text. Payment adapters/native launches in these are isolated fixtures,
not actual provider results. Changed session/test analysis: no issues. Diff check
passed. No whole-project regression or APK qualification is claimed.

OPPO USB reconnected but the previous debugger had terminated. A fresh attach
waited until one scoped app relaunch advertised its service; app data was not
cleared. Attach sync and a subsequent zero-library reload still exposed the older
session source through the read-only VM Script API. A hot restart completed in
3826ms; VM source then contained both _balancePaymentOperations and
_holdUnknownBalanceStart, source length637355. Future reconnect acceptance must
verify the expected loaded source rather than treating attachment/zero reload as
proof. This is debug-loading evidence, not a new APK or live payment test.

Fresh native capture outputs/lf09-cart-stable-20261015.png in the task workspace
shows the same one Herbal bathing soap, pack4, quantity1, total164 and original
payment-review hold after relaunch/hot restart. No Review payment/status action,
initiation, reconciliation, data reset, install or financial write was performed.
Host ownership/reference races are not native payment acceptance. Context-only
architect review identified no established bounded-correction blocker and stressed
that in-memory holds are not durable recovery. Scope changes/disposal/restart may
discard that private attempt knowledge; authoritative restoration remains required
before live balance-payment qualification. Founder review is pending before10.
