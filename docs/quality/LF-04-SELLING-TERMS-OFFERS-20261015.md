# LF-04 — Selling terms and supplier offers

Founder approved Batch03 at 26e0f23a and explicitly requested proceeding to
Batch04 on 15 October 2026. This continues the same single-writer frontend tree
from accepted combined baseline 3c5a454b. No new worktree, policy or framework.

Actor: existing Retailer/Grocery Store owner configuring an exact saved SKU;
public customer consuming the same Store's eligible selling terms.
Classification: mvp_required. Customers must not buy at a quantity or price that
silently drops the Store's saved MOQ/increment/tier conditions.

## Required outcomes

1. Keep Retail/Wholesale/Bulk on the same saved Stock identity. Reuse explicit
   saleType, price, minimum packs, increment and tiers; no repeated channel forms.
2. Validate existing provider-supplied pack/pricing terms against the saved source,
   exact Store/SKU/pack and freshness. Missing required terms must not silently
   become step1/base-price-only purchasing. Never invent a pack revision/time.
3. Supplier-offer preparation stays distinct from MoolSocial/platform funding.
   Reuse existing offer input/draft and accepted public offer/benefit contracts.
   Draft/local Save cannot claim public publication or applied savings.
4. Preserve saved inputs, scope, private data, historical invoices and Cart recovery.
   Display pending/unavailable states with useful correction/retry where applicable.

## Evidence-backed starting gaps

- Store wholesale increment/tiers are saved but current toBuyPublicProduct drops
  them; public quantityStep defaults1 without packTerms.
- BuyV2PackTerms already owns accepted pack revision and tier pricing provenance.
  Saved local quantity alone does not supply these authoritative facts.
- Store currently has one wholesaleOffer with explicit wholesale OR bulk type.
  Simultaneous independent terms are not represented; do not overwrite or duplicate
  Stock to pretend both are supported. Keep disposition explicit.
- ReviewWorkGateway offer action can report published without a real publisher.
  Existing text offer is not a complete public campaign/benefit producer.

## Bounded implementation and verification

Reuse existing product/editor/import/public audit, quantity consumers and scoped
offer draft. Add failing regressions before concrete corrections where practical.
Test exact MOQ+n×step, tier prices in correct units, channel isolation, mismatched
Store/SKU/pack, source expiry/change/unavailable and existing Cart protection.
Valid supplied terms must drive a real consumer test—not only an unused hook.
Preserve v1 export explicitly; no hidden migration. Test supported provider input
and absence separately from live integration. Run affected regressions, inspect
OPPO hot-reloaded source, then founder review before Batch05.

No backend, discount/quote/funding engine, live publication/payment, operator
workspace, APK, accounts reset, runtime-storage injection, mandatory universal
attributes, redesign or edits in Cursor/other worktrees. Required source revisions,
service eligibility, publishing/benefit application remain unimplemented provider
dependencies until supplied and actually integrated. No runtime success fixtures.

## Implemented frontend checkpoint — founder approved

- Existing BuyV2PackTerms may be supplied to the Store projection. Validate exact
  SKU/pack, quantity step, case/content quantity when supplied, every tier threshold
  and whole-rupee price, Store pricing scope and validity. A nondefault wholesale
  increment/tier without that contract now returns a controlled publication issue;
  direct projection rejects instead of emitting a purchasable step1 fallback.
  Source validation is NOT provider authentication or a final customer quote.
- The only production wholesale projection caller is the publication audit, which
  checks the issue before projection. Journey router/content/editor callers use
  Shop. No speculative public Store preview or service transport was added.
- Actual Buy session host tests add MOQ6, reject7, increase12 at ₹240 each (₹2880),
  decrease6 at ₹250 each (₹1500). Offset MOQ3/step2 accepts3/5/7, rejects6. Expiry
  blocks further additions/quantity edits while retaining the Cart and Stock.
- Review transport no longer creates WorkspaceStoreOffer, a published activity,
  success message or operational publication write. UI separates Store offers
  from MoolSocial offers and marks publication unavailable; local records are not
  labelled live. Existing historical offer records are not deleted or republished.
- Explicit Save draft reuses encrypted pending-draft storage with a separate
  account/Store/review key namespace. Private partial offer input survives restart;
  it is NOT an active public offer, benefit or customer consent. Per-account memory
  is isolated within Store state. Reads await pending same-key writes, unreadable
  records block overwrite, writes serialize across instances, late Store/account
  responses cannot update another scope, and newer typing is not labelled saved.
  Failures retain input with retry. No legacy whole-Store server overwrite.

The sealed v1 JSON is unchanged. Its historical test-only serializer emits the
original frozen fields from original fixture inputs, without normalizing away
their selling steps/tiers. It is deliberately lossy and cannot qualify current
purchasing. Current projection tests instead supply explicit host-only contracts.

## Verification and limitations

84 distinct selected host cases passed: 69 product/content/publication/handoff/
channels/Store settings; 14 LF02/LF03/LF04 navigation/editor/draft cases (including
320px normal/200% offer save/restore and selling fields); 1 production offer guard.
Terminal outcomes read. Changed model/audit/session/services and focused tests
analysis has no issues. Dashboard has the same 8 pre-existing brace-style infos;
no new warning/error. Ten narrow admission identity/no-build probes passed;
historical policy, registry, baseline and build/install restrictions unchanged.

Failing-before evidence: dropped wholesale terms returned an unsafe product;
Review gateway created an offer as published. Both new regressions passed after
correction. Six current projection tests plus an inherited-settings case required
explicit host contracts; neither their negative coverage nor sealed export changed.
One 200% widget fixture initially queried a lazily unbuilt field; scroll to build it
before inspecting, then the full case passed. A compact reporter truncated a
tool-output chunk; reran expanded and read through terminal success. Two inspection
commands used a root-relative path while in apps/mobile; use absolute paths for
mixed-root reads. A native helper rejected a non-clickable tooltip node without
tapping; use the observed clickable profile button instead. These are tooling/
fixture limits, not fabricated product regressions or new registry/policy work.

### OPPO actual-app evidence

Reattached the existing debug package after the earlier attach ended. On confirmed
saved Stock (no editor/draft in progress), restarted only MoolSocial to recover its
debug connection; no clear-data/build/install. Current source hot-restarted and
opened TEST Store · product entry through Work → Workspace. Actual UI path:
Store home profile → Operations → Promote store and post requirements → Create.

Entered headline `LF04 Evaluation Offer Draft`, detail
`Private evaluation draft - not published`, default order limit `50`; no product
or end date selected. Tapped Save draft. After a successful Flutter hot restart
(3285ms), reopened that same Store/form and observed all three exact values, with
product/date still unset. Grow showed **0 Offers recorded**, not a published offer.
No invoice, order, payment, customer message or public campaign was created.
Native partial draft is an evaluation user journey, not storage injection.

Calling-task evidence: outputs/lf04-offer-draft-saved.png,
outputs/lf04-offer-draft-restored.png and outputs/lf04-offer-draft-restored.xml.
This proves the private draft after Flutter hot restart; NOT cold-process/new-APK,
backend sync, public pack-pricing readback, actual wholesale customer purchase or
live supplier/MoolSocial benefit acceptance. Commercial Cart proofs are host-only.

## Explicit remaining work / no silent closure

| Remaining | Owner / completion condition |
| --- | --- |
| Genuine accepted pack/pricing contracts | Publication/provider must supply exact source revisions/validity; adapter wired to actual readback and tested. No invented local acknowledgement. |
| Supplier public campaign publish/edit/pause/expiry and conditional benefits | Accepted publisher/submission/result contract and service; remaining frontend integration is still required when that contract exists. A saved private text draft does not complete this. |
| Platform-funded/MoolSocial offers and applied savings | Platform benefit/quote source; Store input cannot grant funding, eligibility or an applied discount. |
| Independent concurrent Wholesale and Bulk terms for one SKU | Existing producer has one alternative trade-offer type. Preserve same Stock. Exact launch need/source contract must be resolved; not claimed implemented by this checkpoint. |
| Native public quantity/tier acceptance | Genuine Store-origin provider data must reach Buy before this can be a real device journey; host fixtures are not a substitute. |

This is a tested supported-frontend checkpoint, NOT whole-Batch04, connected MVP,
provider or APK completion. Founder explicitly approved checkpoint 11c8b53f on
OPPO; live publishing, benefits and provider readback were excluded. Keep the full
active two-way MVP goal unchanged.

### Private saved-product draft correction — OPPO verified, founder review pending

The offer draft listed only published products, preventing private preparation
against saved Stock while publishing is unavailable. The same selector now lists
the current Store's saved products. Private selections are explicitly draft-only;
missing/foreign references stay unresolved and retained, not silently replaced.
The publication guard still requires a public product and the session refuses
publication without a publisher. No Stock duplication, provider acknowledgement,
live benefit or campaign engine.

Failing-before: both 320px normal/200% widget cases could not find the saved private
product. After correction, all 12 LF04 cases pass, including two additional missing
reference cases. Save/reopen preserves the exact private product ID, Stock12 and
private status; missing references save without exposing another Store's details.
Changed source/test analysis has no errors/warnings, only the same8 pre-existing
dashboard style infos. One new test initially used a generic helper that attempted
to scroll an inner text field; selecting the known offer ListView fixed that test
warning and the full12-case rerun is clean. This is a test-scrolling correction,
not another product defect. Previously verified unchanged-source69+1 cases remain
valid; they were not needlessly rerun for this UI-only change.

Hot reload reported one library loaded in4082ms, then the attach disconnected.
OPPO moved outside MoolSocial before this new selector could be inspected. No tap
was made in the other app; founder was asked to return. The earlier11c8b53f approval
does not accept an unseen successor. Architect context review found no demonstrated
stop issue; it grants no device/provider acceptance.

After the founder returned/reconnected OPPO, current source at ad66bb9d was loaded
and hot-restarted successfully (4040ms). USB interruptions required reconnection.
An Android null-root capture could leave an old dump behind; the task-local UI
helper now requires a fresh uniquely named capture and rejects failed captures,
never reading a previous file as current state. This was an automation issue, not
evidence that Store/account state or product data was lost. A noninteractive attach
was replaced by an interactive terminal; no application/source fix was needed.

Actual path: TEST Store · product entry → home profile → Operations → Promote
store and post requirements → Create → Saved product for this draft. Selected the
existing manual-entry `LF03 Evaluation Cumin · 100 g pouch` (saved SKU
`LF03-MAN-CUMIN100`, product `custom-1792061502317910`, see Batch03 entry evidence),
not a new or injected product. Retained headline `LF04 Evaluation Offer Draft`,
detail `Private evaluation draft - not published`, order limit50; date stays unset.
Tapped Save draft and observed “Offer draft saved on this device. Not published.”
Private-product warning was visible and Publish offer was disabled.

Then restarted only MoolSocial after the explicit draft save, reattached the same
source, hot-restarted successfully (3757ms), reopened the same Store/form and
observed the same selected Cumin/pack, headline, detail and limit50. No product,
Stock, invoice, order, payment, public campaign or customer-message operation was
performed. This is native draft persistence/recovery evidence, not a newly built
APK, provider publication, quote, actual discount or public purchase acceptance.
Screens: calling-task outputs/lf04-private-product-saved.png and
outputs/lf04-private-product-restored.png. Founder review of ad66bb9d remains pending.

Subsequent founder decision: "Approve; proceed to Batch 05" accepts the ad66bb9d
private-product correction, documented at5f60fcc7. This supersedes the pending
review status above, not the explicit service/concurrent-terms limitations.
