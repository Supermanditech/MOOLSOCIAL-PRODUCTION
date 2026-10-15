# LF-11 — Selling-Store handover and customer tracking

Founder accepted3817fa03/proceed11. One writer; existing handover/collection
containment and customer tracking presentation only. No operator workspace,
dispatch/map engine, real order/action, provider request on OPPO, backend or APK.

## Demonstrated source gap / correction boundary

Store scoped public orders already reject legacy dispatch/handover/pickup effects;
authenticated customer collection has its separate controller. Preserve these.
Delivery, customer acceptance and settlement must not become one inferred status.

BuyV2Session.refreshLiveDelivery instead uses order-ID-only caches/busy Set and
unguarded callbacks/finally. Late readbacks can leak another owner's driver/location,
notify disposed sessions or clear a newer operation. Reuse existing owner/auth/
procurement scope and per-operation tokens, bind immutable order facts and existing
tracking identity, recheck after notification before provider reads. No new route.

Retain last confirmed ready/delivered tracking with separate refresh-unavailable
message on invalid/offline/error. Reject older comparable timestamp updates only
within the same source/tracking stream; do not invent revision ordering across
reassignment or permanently freeze a delivered state against valid corrections.
Never change order status, acceptance, financial balances or settlement from a map.

## Verification / dependency boundary

Fail-before owner/auth/disposal, reentrant notification, late-finally, older same-
stream readback and delivered refresh-failure regressions. Preserve valid updates,
changed-stream handling, polling/background/disposal, original orders and Store
handover/collection containment. Host fixtures only; no runtime order injection.
Hot-reload OPPO and verify exact loaded source, passively inspect existing Store
surfaces and saved Cart without opening tracking or performing business actions.
Native empty-order coverage is not acceptance of delivery/ingestion/handover.

Order/logistics provider owns authenticated Store/order/delivery stream/revision,
reassignment, coverage/freshness, proof, customer acceptance and status readback.
Existing live-delivery adapter has orderId/sourceId/optional trackingReference and
timestamps, not a complete authoritative revision/assignment contract. Missing
identity or timestamp does not establish freshness. Full integration and frontend
mapping of that accepted contract remain unimplemented where absent; no guessed
DTO or local business transition substitutes for it. Settlement remains separately
supplied finance authority. Delivery-exception mutations are Batch12, not11.
Review this bounded frontend checkpoint before Batch12; preserve all earlier
provider/settings/durability dependencies as unfinished.

## Host verification — 15 October 2026

Initial17 isolated LF11 cases demonstrated15 application failures and2 existing
protections. Corrected current owner/auth/epoch/order bindings, cached location
visibility, late cleanup/disposal, reentrant notification and confirmed-state loss.
The shared private scope getter was renamed for its two actual callers; the
existing balance behavior is unchanged and its22 selected regressions passed.

Two boundary cases then verified missing stream identity and valid newer provider
correction. The first candidate incorrectly treated two null tracking references
as the same stream; the added test failed and comparison now requires a nonempty
equal supplied reference. Unknown/different streams are NOT freshness-qualified.
Three removal/reassignment cases initially inherited debug review seeds instead
of their custom read adapter:2 failed and1 was insufficient evidence. Explicit
reviewDataEnabled=false plus loaded order-ID assertions corrected that fixture;
all3 pass. This was test setup, not an application regression or runtime data.

Final complete live-tracking file:32 passed, including22 new LF11 tests and10
existing map/ETA/coordinate/polling/background/disposal/unavailable widget checks.
Final changed-source analysis: no issues. Additional completed checks: balance22;
full order-progress file197 (original order, acceptance, supply/partial/refund,
mixed seven Cart fulfilment combinations at normal/200% text, return/recovery and
presentation); Store handover4; pickup versus settlement8; DASH06 projections4;
scoped-order legacy handover containment1.268 distinct cases passed across these
bounded runs. This is not one application-wide regression, real delivery, payment,
native Map or APK acceptance. No screenshot-capture define was enabled.

Diff check passed; no unrelated formatting or application owners changed. Two
source-discovery commands used unsupported Windows literal glob/nonexistent
paths; corrected directory-scoped reads, not test/application failures. Existing
protected-reference tag warnings are unchanged, not new test skips or failures.
Context-only architect review found no established bounded-fix blocker and
emphasized that missing-stream timestamps are not proof of freshness.

## OPPO checkpoint — pending, not passed

Existing debug attach56087 ended with Lost connection to device when reload was
requested. Fresh adb reports OPPO2b3e0f71 offline/transport9. No restart, reset,
reinstall, native order/handover/tracking query or financial action was performed
for LF11. The source is NOT yet claimed loaded. Reconnect, attach/reload and verify
the actual loaded guard before passive review; preserve Cart164/pending payment
and current evaluation Store. That Store's0 saved orders limits native coverage
to static/empty surfaces; do not seed orders to manufacture acceptance. Founder
review remains pending before Batch12. No service dependency is closed here.

## OPPO reconnection follow-up — 15 October 2026

Founder answered Reconnected. Fresh adb shows device/transport11, MoolSocial in
foreground and a new app process. Attach7508 waited for the service address;
the app showed the saved Store Orders surface, no open edit. One app relaunch
advertised the service, followed by a4004ms debug hot restart. No data was cleared
and no APK was installed. Read-only VM Script retrieval now proves exact text
equality of running buy_v2_session.dart and the tested working file, including
_prepareLiveDeliveryOrder and _liveDeliveryOperations. Source checkpoint332848e1
is loaded; the earlier offline limitation above is historical, not current.

Native Cart inspection retained one Herbal bathing soap, pack4, quantity1, total164
and its original payment-review hold. Review payment was not tapped. Returned
through Work/Workspace to the same TEST Store product-entry evaluation Store,
then Orders→Delivery:0 saved delivery orders, with unverified online coverage
explicit. No order, tracking, handover, collection or financial action. Captures
in task outputs: lf11-cart-restored-20261015.png and
lf11-store-delivery-review-20261015.png; both visually inspected. One UI dump
failed during the Workspace transition; fresh capture succeeded, no stale file
or repeated navigation tap used. USB/app remained connected.

Native evidence proves source loading and retained/static navigation only, not
live tracking/provider actions on absent orders. Existing268 host checks remain
the relevant tested-code evidence; no application source changed in this follow-up.
Founder checkpoint acceptance is still pending before Batch12. Live providers,
missing revision/stream contracts and all earlier dependencies remain unfinished.
