# LF-12 — After-sales, support and documents

Founder accepted eec5310c and answered “Approve; proceed to Batch12”. This is
ordered MVP frontend work, not live refunds, provider acceptance or APK scope.

## Bounded correction

Reuse existing cancellation/return/refund, support context and immutable invoice
owners. Delivery-exception restore/reschedule/proof-dispute currently use order-ID
cache/busy state without owner/auth/procurement/disposal/token guards. Scope these
private caches and operations, bind original order facts, recheck after notification
and await, and prevent old finally from clearing a newer operation. Reject stale
slots and unrelated exception/proof responses. Preserve valid existing contracts,
itemised receipt matching and all original order/payment/status data.

No new screen, refund/ledger engine, backend DTO, provider, route or policy/registry
expansion. No native order/payment/tracking/message action, injected records, APK,
operator workspace or other tree. Existing source ownership and safety gates apply.

## Acceptance and dependencies

Demonstrate failures before changes; test owner/auth/disposal/reentrant/late-finally,
cache/slot isolation, correlated response and valid existing actions. Run affected
original-order resolution, support and invoice tests. Host fixtures remain separate
from OPPO static/source verification and actual service acceptance. Preserve saved
Cart164/payment hold, evaluation Store and Stock. Hot reload, inspect passively,
then founder review before Batch13.

Provider owns authenticated order/customer/Store identity, policy/revision,
authoritative cancellation/refund/proof/documents and business acknowledgments.
Existing exception adapter has no idempotency key or durable unknown-command
reconciliation contract. Do not invent these or claim retry/restart safety. Map
these unfinished dependencies in the existing field inventory after verification.

## Implemented / host verification

The same demonstrated race also affects main refreshOrderResolution and
submitOrderResolution. Both families now scope cache/results/selection to the
existing owner/auth/procurement epoch, bind original purchase/order/supplier/
tracking and purchased line identity, and use per-order operation tokens. Checks
run after listener notification and adapter awaits; disposed/stale callbacks do
not write/notify or clear a newer request. Reads and mutations exclude each other.
Changed exception identity invalidates a same-labelled selected slot. Command
responses require matching exception identity; disputed proof must match its
original proof. Existing eligible quantities, policy windows and original receipt
validation remain authoritative, not inferred from delivery or requested refunds.

Exception tests: initial32 cases31 failed/1 pre-existing protection; resolution
tests:18 additional cases all failed before its correction. Final50 focused cases
pass. Lost/invalid mutation responses now show an unconfirmed/support outcome and
block blind retry within the same scoped session, even after a general read.
This does NOT provide durable/key-correlated recovery across restart or owner-
epoch changes; the adapters lack that contract. A dispatched command cannot be
undone by rejecting its stale callback. Completion still requires provider
idempotency/reconciliation and authenticated original-order binding. No automatic
resubmit or synthetic successful request was introduced.

Final selected nine-file run:226 actual cases passed,2 pre-existing skipped legacy
Assist/issue screenshot goldens (not acceptance),0 failures. Nine additional
runner loading events are not counted as cases. Coverage: new50, existing live
tracking32, order resolution110, support/Assist/issue context and invoice34.
Separately34 checkout/receipt C05 cases passed, including exact itemised receipt,
partial/multiple lines, invalid identity/quantity and offline recovery.260 distinct
selected host cases total; not whole-app, native provider or APK qualification.
Changed-source analysis: no issues; diff check passed. Protected-reference tag
warnings remain pre-existing. No golden/capture update define was enabled.

Architect context-only review emphasized per-order exclusion and uncertain-command
retry safety. Both exception and main resolution mutations now have explicit
unconfirmed holds. No independent architect execution or provider proof claimed.

## OPPO source / saved-state check

Existing attach7508 hot-restarted in45339ms after bringing MoolSocial from the
Android launcher to foreground. Read-only VM Script retrieval proves exact text
equality of running buy_v2_session.dart and the tested working source, including
both families' guards and unknown hold. No APK installed or app data cleared.
Native Cart remains one Herbal bathing soap/pack4/164 with its original payment
review hold. No payment review/submission was tapped. Existing Store stock overview
remains populated (purchase-cost29550,24 available/6 unavailable,18 low-stock
products). Customer orders still has0 saved active orders and explicit incomplete
online coverage. Viewed captures: outputs/lf12-cart-20261015.png and
outputs/lf12-orders-20261015.png in the task workspace. Phone left on Orders.

No applicable native after-sales order exists, so actual cancellation/refund,
reschedule/proof, contextual customer messaging and issued-document journeys
remain unverified. Existing host checks preserve exact support/Chat return
context, purchased invoice lines, original business/tax context, safe download
outcomes and bottom action clearance. These are not actual message/document
issuance or full backend integration acceptance. Approved screens not redesigned.

Scope/Git:13 exact-identity/negative-phase probes passed; current LF12 admission
passed61 cumulative literal owners, policy/registry unchanged. A later check
correctly rejected Flutter's generated .flutter-plugins-dependencies refresh.
Readback proved only timestamp and the same local plugin's current worktree path
changed. Restored that agent-generated file to its pre-run contents with apply_patch;
no package/dependency/user source was removed or claimed as feature work. Gate
then passed. Three existing generated support files retain zero normalized diff.
Two source-discovery commands used wrong cwd/nonexistent path and were corrected;
not application/test failures. One fresh UI dump failed during transition; no
stale XML or blind follow-up tap was used. No push, live query/action or records.

Founder review is pending before Batch13. Earlier session-only Store settings,
publication/quotes/payment/order feed/tracking and durable recovery dependencies
remain unfinished, not closed by this checkpoint.
