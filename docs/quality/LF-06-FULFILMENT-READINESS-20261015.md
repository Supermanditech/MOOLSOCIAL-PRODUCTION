# LF-06 — Seller fulfilment and readiness

Founder accepted Batch05 at20fdc89b and explicitly approved Batch06. Same feature
tree, combined base3c5a454b, one application writer. No new route/framework.

## Existing inputs / authority

Store owns accepting/visible preferences, hours, extra preparation minutes,
fulfilment preference, pickup location/preference and dispatch-days input.
Products/Stock are not duplicated by Quick/Scheduled/Wholesale/Bulk.
BuyV2OfferEligibility owns exact Store/SKU/channel/customer-location binding,
source revision/time/expiry, actual ready/fleet/location result and eligible
Quick/Scheduled options/slot. Local switches, free text and prep minutes do not
grant those results. Provider, quote and dispatch connections remain pending.

## Concrete corrections

- A pickup form populated for StoreA currently writes into current StoreB after
  switching. Capture Store identity/navigation revision and enforce before mutation.
- Apply the same stale-target protection to the existing readiness/trading save
  caller before visibility or any partial settings mutation. Preserve ABA inputs.
- New Store pickup location must be unknown, not fabricated Jodhpur/Sardarpura/PIN.
  Existing saved locations are retained, not silently erased or verified.
- Allow an explicit copy of complete saved Store address into pickup draft fields
  without repeated typing, only in the captured Store. Never silently overwrite a
  distinct pickup location, serviceability, collection capability or pricing.
- Reject negative preparation and invalid location input without partial save;
  preserve supported legacy preference values and sentinel0. Do not invent limits.
- Clarify that saved preferences need service confirmation; do not claim public
  synchronisation from a local save.

## Acceptance

Failing-before stale form/default tests where practical; StoreA→B and ABA scope,
valid same-Store save, invalid-input preservation, no public eligibility from local
settings, owner-explicit address reuse, normal/200% widgets, affected existing
settings/recovery regressions. Actual evaluation Store UI only on OPPO; no injected
runtime records, orders, payments or events. Hot reload then founder approval
before Batch07. Existing publisher/location/eligibility/backend dependencies remain
unimplemented; no operator workspace or APK work.

## Implemented frontend checkpoint — founder review pending

Pickup, readiness and trading saves accept captured Store ID/navigation revision;
reject mismatch/ABA before mutation and return a result to the caller. The main
settings action checks origin before visibility or any settings save. Invalid
negative prep and location input preserves prior state; legacy preferences such
as Pickup and sentinel0 are preserved without inventing limits.

The shared publication/address form had lazy Store-ID initialisation on its first
save. It now captures Store/revision and the source snapshot in initState, so a
first stale save cannot target a new Store. This is the shared address owner,
not a new settings system. Existing per-SKU/financial/historical records unchanged.

New operational records have empty pickup city/area/PIN, not hard-coded geography.
Existing explicit locations remain intact. Where a complete saved Store city/
street/PIN exists, Use saved Store address copies it only by owner action in the
same captured scope; independent pickup exceptions are not overwritten. Copy is
a draft edit, not an apply or service grant. Full-width multiline pickup address/
area preserves readability; city/PIN remain compact. No coverage/pricing fields
became editable and local facts still supply no eligibility or fulfilment mode.

## Verification and actual scope

52 distinct selected host cases passed: publication/settings16, LF vertical18,
Store scope15, BATCH1 settings2, configuration snapshot1. Six new LF06 cases cover
unknown new location, stale/ABA session writes and negative prep, two stale shared
form scopes, and normal/200% pickup form input/address-copy/scope preservation.
Analysis has no errors/warnings; same8 pre-existing dashboard style infos remain.
These are focused outcomes, not full-project, backend, device or APK qualification.

Failing-before evidence: new location was Jodhpur; a correctly navigated StoreA
pickup draft overwrote StoreB. Initial widget attempts targeted a status popup/
wrong scrollable and then a footer-obscured target. Corrected to actual Operations
→ Store settings navigation and visible alignment, not suppressed warnings or
weakened assertions. A fixture assumed new Store acceptingOrders=true; actual
initialfalse was preserved and the expectation corrected. The existing concurrent
save test used9AM/8PM, rejected by the already-existing baseline time validator
(source checked at20fdc89b); changing to09:00/20:00 tests its intended two-save
barrier. Invalid-format tests remain. No app validation was weakened.

Native OPPO: current source hot-restarted7317ms with the existing evaluation Store,
then home profile → Operations → Store settings → Delivery & pickup. New fields
were blank, not invented geography. Empty Apply showed required/PIN errors. Entered
Pune / Evaluation pickup lane /411001 through actual UI, applied and reopened the
same form in the same session; those values remained. Pickup remained its original
true preference. One genuine local preference update/activity, no order/invoice/
payment/Stock/public campaign/eligibility event. No storage injection. The initially
clipped area was made full-width; final hot reload3045ms and screenshot confirm
all evaluation text readable. Calling-task outputs/lf06-pickup-unknown.png,
outputs/lf06-pickup-reopened.png and outputs/lf06-final-pickup.png.

Explicit Store-address reuse and stale/ABA/large-text checks are host evidence;
only the described single-Store apply/reopen/layout cases were native. OPPO remains
on the applied evaluation pickup form for founder review before Batch07.

## Held requirement — durable settings / live readiness

ReviewWorkGateway.saveOperationalState records a snapshot but supplies no durable
settings readback contract. Session apply/reopen is NOT app-restart persistence.
The UI now says applied in this session, durable sync/service confirmation pending,
and uses Apply rather than claiming durable save. Existing Stock/private-offer
draft persistence is separate and was not replaced or downgraded.

The founder's enter-once/update-later requirement across restart remains unmet
for these settings, not waived or completed. Owner: authoritative Store settings/
provider integration plus its frontend caller. Completion: accepted scoped write/
readback contract, safe load/update/error/recovery wiring, then real saved values
survive cold restart/correct-account Store restoration and provider synchronisation.
Do not replace this with a local authority, another preferences framework or an
invented successful server write. Live location/publication, customer-specific
eligibility revision/expiry, fleet, schedules/slots, ETA, fees/quotes and delivery
events remain separately unimplemented provider dependencies. No operator redesign.
