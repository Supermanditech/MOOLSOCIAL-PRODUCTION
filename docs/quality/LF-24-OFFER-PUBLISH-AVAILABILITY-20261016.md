# LF-24 — Store owner sees truthful offer publishing availability

Existing LF04 child, mvp_supporting. Actor: Retailer/Grocery Store owner preparing
a supplier-funded offer against an existing saved product. Outcome: completing
valid fields must not enable an action that the current session always rejects
because no publisher is connected; private draft editing and Save remain usable.

Source finding: the form banner says publishing is unavailable; WorkSession's
addWorkspaceOffer always rejects it without a publisher. The form enables Publish
when title/detail/date/public-product/customer/cap checks pass. Existing private-
product tests do not cover that valid-form boundary. Demonstrate it first.

Reuse the existing form, draft storage, defensive session rejection and approved
layout. Add one explicit read-only publisher-capability seam, false while no
accepted publisher exists, and include it in Publish availability. Do not claim
form validity, public listing intent or local customer-message preferences grant
publication permission. Do not implement a publisher, campaign engine, discount,
marketing consent, monetary allocation or provider-success fixture.

Acceptance: host normal/200% form with an explicitly public exact product, allowed
test customer, valid date/title/detail/cap has no other prerequisite failures,
yet Publish stays disabled and unavailable explanation remains accessible.
Save draft confirms private persistence and retains all exact fields/Stock.
Existing LF04 draft/recovery/foreign/missing-product and direct rejection tests
remain passing. Source reload and inspect the existing OPPO draft without editing
or saving it; no public offer/customer message or commerce transaction.

Founder authorized verified defects and supported frontend work overnight;
morning acceptance remains pending. One application writer in the same feature
tree; only exact existing owners and this evidence pair are added to the current
admission. No policy/registry expansion, other tree, backend, APK or push.

Unfinished: supplier campaign representation/submission/lifecycle/readback and
applied benefits remain frontend plus service dependencies, not completed by a
disabled button. Concurrent Wholesale/Bulk for one SKU is a separate MVP choice
awaiting founder response; never duplicate Stock or invent public offer IDs.

## Implemented — morning review pending

The completed-form regression failed at normal/200% text with a non-null Publish
callback despite no publisher. Exact approved-photo public product, allowed host
customer, valid date/title/detail/cap and absent prerequisite warnings establish
that another invalid field did not cause the expectation. A separate duplicate
test disposal was corrected: the shared mount helper already owns disposal.
The failed run is not counted as a pass or a native business journey.

WorkSession now explicitly reports publisher availability false while no accepted
publisher exists. The same form checks that capability before enabling Publish;
all field checks and the existing session rejection remain. Draft editing, Save,
scope and schema are unchanged. No publication, consent or eligibility authority
is inferred from owner inputs.

Two new normal/200% cases and all12 existing LF04 vertical-slice cases pass.
The new cases save exact private fields to the test store with unchanged Stock and
no recorded offer. Existing cases cover account/Store/late-write/read failure,
private/missing product, restart recovery, selling editor and direct rejection.
Focused analysis:0 errors/warnings,8 pre-existing dashboard brace-style infos.
A combined space-free LF04|LF24 regex failed at the Windows batch launcher before
tests ran; the two literal plain-name selections then ran successfully. No failed
launch, fixture error or host fixture is counted as provider/device acceptance.

OPPO hot reload3813ms. Same TEST Store -> profile -> Operations -> Promote ->
Create recovered existing Cumin100g private product, headline LF04 Evaluation
Offer Draft, detail Private evaluation draft - not published, cap50/date unset.
Existing unavailable explanation was readable at form top. After a guarded form
scroll, Save draft was enabled and Publish offer disabled in fresh native UI.
Viewed task screenshot lf24-offer-availability-20261016.png. No typing, Save,
Publish, consent/message, product/Stock/invoice/payment or provider operation.
Native draft is incomplete/private; the fully valid public-form edge is host-only.
No new APK, backend, push or founder acceptance. Phone left on this draft form.
