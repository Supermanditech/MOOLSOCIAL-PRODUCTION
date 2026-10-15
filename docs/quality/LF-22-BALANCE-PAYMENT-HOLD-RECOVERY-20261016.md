# LF-22 — Buyer original balance-payment hold across restart

MVP-required outcome: the customer cannot unknowingly initiate a second balance
payment after a restart loses the original attempt. This is frontend duplicate
prevention, not payment verification or a complete recovery service. Reuse the
existing customer-state snapshot and serialized writer; no new route, storage
service, gateway, ledger, policy or recovery framework. The concrete old gap is
an in-memory-only order/key/amount map that disappears on restart/scope reset.

Retain a typed version1 original hold scoped to existing persistence owner and
authenticated account where supplied, immutable order/purchase identity, INR
amount and exact initiation key. Confirm device persistence before dispatch and
recheck operation/account/Store context. No storage/read failure may permit an
external start. Save returned references without making saved client state into
payment authority. A reference-save failure retains the earlier unresolved hold.

Restore holds without dispatch or navigation. Known-reference status reads must
pass the existing matching reference/amount guards; no-reference holds require
provider recovery by the original key, which remains missing. A crash after the
pre-dispatch save cannot prove whether dispatch happened. Never release a hold
from unrelated due/paid/zero-balance responses. No automatic charge/retry, local
payment success, Stock posting or settlement. Preserve unrelated Cart/Checkout,
attempts and private data, including concurrent customer-state writes.

Focused host acceptance: demonstrate restart gap first; confirmed-save-before-
dispatch, read/write/corruption failures, missing versus legacy journal data,
unknown initiation, known-reference restore, failed reference save, scope/ABA,
immutable purchase mismatch and interleaved Cart writes. Retain existing LF09/
T07 original-attempt and seven-Cart protections. Fixtures are host-only; native
OPPO checks are passive retained Cart/navigation and source-load verification,
not financial initiation/status queries. No runtime injected records.

Existing customer storage uses SharedPreferences, not an encrypted payment
vault. Persist only correlation/hold metadata already required for private
recovery, never credentials, bank/UPI action URIs or provider success payloads.
Authoritative production storage/security and payment services remain separate
integration obligations. Missing provider/key recovery is not marked complete.

Founder authorized supported pending frontend work overnight, without waiting
between small checkpoints. Morning approval remains pending. One Codex writer;
no backend/service work, APK/build/install, Cursor/other tree, push, redesign,
registry expansion or unrelated governance. Reuse the existing narrow admission.

## Implemented checkpoint — morning acceptance pending

The failing-before new-session case restored the order but lost the original
uncertain balance attempt. The same customer snapshot now retains a strict
version1 hold: persistence owner, authenticated account where supplied, immutable
order/purchase fingerprint, original key, whole-rupee INR amount and optional
reference. No action URI, credential, provider success payload or local settlement
is persisted. Legacy snapshots without this field remain readable; malformed or
foreign/duplicate journals and unreadable root state fail closed, never absence.
An invalid procurement draft cannot hide a present payment journal.

The existing operation token is acquired before awaiting actual serialized
storage. Failed/throwing pre-dispatch saves make no provider call and retry with
the same original key while this session knows it was unsent. The existing
request record's dispatched flag is set immediately before adapter invocation.
That unsent knowledge is deliberately NOT restored from disk or after scope loss:
retained holds become unknown, never permission to replay. Returned references
are saved before enabling a handoff; failed reference persistence leaves the
earlier durable hold, with known-reference reconciliation still explicitly
correlated and missing-reference resolution still provider-held.

No hold is erased by Cart saves, due-only status or unrelated paid results.
Account/Store/operation checks follow async read/write boundaries; an old finally
releases only its own token. Read readiness is cleared at the start of a new
scoped read and requires that current read to succeed. A reused order ID with a
different immutable purchase cannot query the old reference or initiate payment.
The existing Cart/Checkout snapshot writer has no other application constructor
that could silently omit the new journal field.

122 distinct selected host checks pass:23 LF22,20 LF09,42 shared persistence,
33 T07 original Checkout/financial-closure recovery,2 T08 mixed order summaries
and2 T10 editable mixed-Cart/Checkout Back cases. LF09 and analysis passed again
after the final request-record hardening. T07/persistence/Cart results are reused
where their serialization/source behavior did not change; no whole-app/full
seven-combination device qualification is claimed. Focused analysis has no issues.
The existing protected-reference tag warning remains; no test was skipped here.

Initial candidate failures are not passes: eager Future.error fixtures became
unhandled during the new storage await, so failure now originates in the actual
adapter invocation; duplicate/finally tests now wait for real async preflight
before checking dispatch/owner transition, retaining their original assertions.
The new thrown-write case proves safe retry keeps the exact original key. A
live test handle briefly emitted no output; it was polled to terminal success,
not duplicated or restarted. Architect context review supports the bounded
claim, with all provider/native transaction limits retained.

OPPO source restart6800ms and4517ms preserved the existing Cart. Final source
restart6126ms, fresh Cart capture and screenshot lf22-cart-final-20261016.png:
Herbal bathing soap, pack4, quantity1, total164; original review-payment hold and
disabled edit controls remain. No payment/Check status action, journal seed,
product/order/invoice mutation, account switch, install or APK operation. A fresh
UI dump temporarily failed after navigation; it rejected stale data, and a new
read (without repeating the tap) succeeded. Screenshot visually inspected.
This is native retained-data/source-load evidence only; new balance holds,
financial callbacks and restart races are host-tested, not native-live accepted.

No push or founder acceptance is implied. Payment recovery by original key,
authoritative storage/services, full public/Store provider mapping and the other
original goal packages remain open. Old-writer/downgrade compatibility is not
qualified by this additive snapshot field.
