# LF-08 — Cart / Checkout / profile consistency

Founder accepted f8b9c1eb and approved Batch08. One writer, same tree/base and
existing screens/contracts. MVP outcome: address selection/edit/removal/request
returns cannot cross account or page context; valid same-context flows and exact
Cart lines/totals remain. No redesign, new framework, backend, APK or commerce.

## Inspection / bounded corrections

Existing quote fingerprints include lines/quantities/prices, address details,
selected payment and benefit revisions; address edits invalidate price contracts.
Business invoice support is truthfully held; private recipient profiles and
immutable orders remain separate. Reuse these paths, not new pricing/credit logic.

The address editor already captures owner/navigation, but the parent picker does
not: choice after reverse animation and deletion after confirmation can act on a
changed account with the same address IDs. Its stale Add/Edit/Request entry can
also rebind old context to a new owner. Request-link async completion/manual-entry
must respect its original owner/page, not copy/share a link or recipient later.
Demonstrate then guard these existing actions with captured scope. Preserve input
on rejection and show usable reopen guidance; no runtime account switch performed.

## Tests and review

Isolated host fixtures: unchanged current-owner selection and cancellation,
owner drift/reverse-return/navigation ABA, delete confirmation, stale editor/request
entry and delayed request completion; normal/200% address layout. Relevant existing
GST/profile, quote/terms invalidation and seven Cart composition cases. OPPO is
read-only with saved soap164 and unresolved original payment lock; never submit,
reconcile or alter that payment/Cart. Hot reload then founder review before09.

## Deferred dependencies

Authoritative catalogue/publication, eligibility, accepted quotes/fees/tax/credit,
policy/business invoice issuance, address-link services, durable account profiles
and Store settings sync remain held where absent. Host fixtures are not live
service, genuine commerce or native acceptance. No guessed endpoints/results.

## Implemented checkpoint — review pending

Address picker actions capture storage owner, authenticated buyer account/session,
navigation sequence and page/destination; procurement scope must still be current.
Validate before choosing/opening Add/Edit/Request/removal and after reverse/dialog
completion, immediately before local mutations. The existing editor also checks
the captured buyer account/session before Save. Current valid actions stay usable.

The same original scope follows the existing address-request form, including
manual-entry and copy/share preparation. Late results are not copied/shared after
an owner/auth/page change. An already-sent request cannot be unsent by a frontend
guard; this only prevents its stale local result/application. Service exceptions
reset that form's busy state, show retry guidance and preserve recipient input.
No new pricing/credit/consent/quote/identity engine or duplicated profile/store.

Fail-before tests reproduced: owner/nav return selected Work instead of retaining
Home; stale delete removed Work; stale Add/Edit/Request opened a new form; late
owner request copied a link; service failure escaped. Additional auth/session and
same-account/new-session ABA checks also failed before the auth guard. These are
isolated host fixtures, not real account changes or public provider results.

67 distinct selected host cases passed: LF08 new18, existing responsive address/
manual-request12, GST/profile continuity5, all7 Cart compositions at normal/200%
14, supplier terms/address/consent14, original payment changed-account/session2,
itemised quote1 and hot-reassembly pending-attempt1. Existing protected-reference
tag warnings remain in the older test files; no cases skipped or new tag policy.
Changed app/test analysis is clean. Two new async-context infos were corrected by
mounted checks before final analysis, not suppressed. Final LF08 rerun covers the
mounted change. Existing quote/terms authority and immutable purchase rules reused.

OPPO: current source hot-reloaded8828ms and final7062ms. Through existing Visit
Store Cart control, inspected Cart1 soap/pack4/164, address and original payment-
review hold. No change/review-payment/checkout submission, saved-address mutation,
recipient switch, request sharing, Stock/invoice/payment/provider action or runtime
injection. Task outputs/lf08-cart-review.png retains actual native state. Native
owner/auth races and a fresh editable checkout were NOT exercised because the
existing Cart is legitimately locked; those checks are host-only. No APK built.

Context-only architect review endorsed the bounded fix and timing boundary; it is
not independent source/native acceptance. Founder approval is pending before09.
All earlier service-dependent requirements and durable settings remain unfinished.
