# LF-05 — Inherited terms and policy readback

Founder accepted Batch04's private-product draft correction at ad66bb9d,
documented at5f60fcc7, and explicitly approved proceeding to Batch05.
Same feature tree/single writer, accepted combined base3c5a454b unchanged.

## Bounded MVP outcomes

- Reuse Store payment/return defaults and private customer exceptions; no repeated
  product entry, credit approval, quote arithmetic or payment engine.
- Preserve product return exceptions and existing source identity. Public content
  must never expose the private customer-payment map.
- Accept optional policy readback through the existing public-content adapter and
  existing BuyV2SupplierPolicy/ProductContentSnapshot contracts. Validate exact
  product/Store, source identity, readiness, expiry and consistent acceptance flag.
  Invalid/unavailable supplied readback blocks applicable consent/purchase rather
  than pretending no policy is needed. Absence stays unknown, not new consent.
- Preserve existing Buy consent persistence and change/expiry guards; prove supplied
  policy reaches the actual consumer, not only an unused parameter. No invented
  revision/time, policy approval or customer acceptance.
- Give concrete input-format feedback in the existing payment-terms editor where
  selected advance/credit fields are invalid. Keep saved preferences unchanged on
  failed Apply. Test normal/large-text layout, inheritance, privacy and Store scope.

Existing owners: work_publication.dart, store_publication_settings.dart,
store_payment_terms.dart and existing focused content/settings/widget tests.
No new route, universal contract builder, schema/service, migration or framework.

## Verification / stop

Demonstrate supported gaps before correction where practical; targeted adapter and
actual Buy consent cases; existing inherited default/override/privacy regressions;
affected editor widgets at320px normal/200%; analysis; real evaluation Store through
the app, hot reload OPPO, then founder review before Batch06. Never inject runtime
stock, customer orders, policies, payments or events. Host providers are labelled
fixtures, not native service evidence.

## Dependencies and limits

Policy publication/revisions/readback, account consent sync, customer eligibility,
credit authorisation, quotes, payment providers and live return/refund operations
remain provider/backend-owned and unimplemented until actually connected/tested.
Supplier policy is not automatically the return-summary string: preserve their
different meanings. Optional readback wiring is not authenticated live publication.
No APK/release, Cursor/other-tree edits, redesign, policy/registry expansion or
operator workspace. This ticket is authorized, not implemented/accepted yet.

## Implemented checkpoint — founder review pending

Existing Store/customer defaults, reset-to-inherit semantics, private exception
maps, per-product return overrides and existing Buy consent logic were retained,
not duplicated. Selected advance/credit fields now show bounded whole-number
errors, update as the owner corrects input and remain readable at320px/200%.
The defaults hint distinguishes preferences from customer eligibility/payable
amounts. Failed preference saves preserve the original Store and reject stale
Store targets; no source-model migration or new publication state.

WorkspacePublicContentAdapter now accepts optional policy readback through the
existing BuyV2ProductContentAdapter contract. It validates current exact Store/
product applicability, ready state, source identity, nonfuture supplied observation,
policy expiry and consistent acceptance decision. Invalid/offline/throwing sources
return an unavailable hold, not a local no-policy fallback. A valid explicit
no-policy-required result is distinct from unknown. policyReadbackRequired=true
also holds when the source is absent; defaultfalse preserves legacy unknown.
Policy body is not assumed equivalent to the Store return-summary string.

Policy ID/revision/expiry remain supplied values. Local product copy/media retain
their local sourceId/observation metadata; policy readback cannot relabel them as
provider-verified. No timestamp/revision/consent is manufactured. The synchronous
source is read again by existing Buy consent action guards, including after saved
consent returns. No new asynchronous pipeline, ledger or acceptance mechanism.

**Runtime limitation:** the new source hook/required flag is not connected to an
authoritative service. Current Store public route is separately held by publication
confirmation. Neither that block nor host tests proves every future consumer has
configured required-policy handling. Publication integration must supply the exact
policy decision/readback, test each applicable consumer and retain service ownership.

## Verification

94 distinct selected host cases passed across current content/Store settings/
channels/publication/editor and existing Buy consent suites. Seven are new LF05
cases: four policy/actual-consumer cases, two input/layout cases, one failed-save/
Store-isolation case. The new editor cases failed before the correction (no field
error), then passed at normal/200% text. Actual Buy tests cover required missing
source with no consent bypass, changed policy before/during acceptance, valid
acceptance, expiry and retained Cart. Existing consent suite passed28 cases,
including failed writes, account changes, recovery and portrait/landscape popups.
Analysis of all changed app/test owners found no issues. No whole-project or
APK qualification claimed; unchanged results were reused where applicable.

Architect review identified composite-provenance and no-hook limits; corrected
the metadata and added explicit required-readback handling with a consumer test.
Subsequent context review found no further demonstrated stop issue, requiring
the runtime/device limitations above to remain explicit. No additional authority.

Native OPPO: hot reload completed4202ms then3383ms after the final source change.
Actual path TEST Store · product entry → home profile → Operations → Store settings
→ scroll → Business details → Payments & returns → Wholesale payment terms.
Enabled Advance · balance before dispatch (initially unchecked), entered100 and
observed the inline1–99 error; corrected to25 and observed the error clear. Hid
keyboard and unchecked the same term again. All five terms were unchecked before
and after; neither Apply terms nor Save settings was pressed. No saved preference,
Stock, customer, invoice/order/payment, offer or policy record was created/changed.
Native credit-field/policy-service/consent and new-APK checks were not performed;
credit ranges and policy actions are labelled host evidence, not native proof.

Calling-task screenshots: outputs/lf05-advance-error.png,
outputs/lf05-advance-corrected.png and outputs/lf05-review.png. OPPO remains on
the existing terms editor for founder review. One automation lookup tried an
editable value in content-desc only; it safely rejected without tapping. The
helper now supports exact native text too. A wrong diagnostic LASTEXITCODE check
after a successful PowerShell-only gate was corrected to its actual success flag;
the required checks then passed before any application edit. No gate was bypassed.

This is a frontend checkpoint awaiting founder approval before Batch06, not live
policy publication/readback, credit approval, return service or payment acceptance.
