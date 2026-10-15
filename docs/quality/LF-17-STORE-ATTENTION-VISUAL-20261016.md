# LF-17 — Readable selling-Store attention and payment review

Exact actor: approved Retailer/Grocery Store owner reviewing outstanding alerts.
MVP-supporting verified visual correction, authorized by the founder's overnight
defect-fix direction. Morning review pending; LF16 recovery checkpoint4a94f8af
remains preserved. No redesign of approved neighbouring screens.

Current OPPO screenshot outputs/oppo-current-20261016-visual-audit.png and
existing field-map findings identify eight defects: missing attention heading;
unbounded items; dominant technical reference; unlabelled customer; ambiguous
bill/refund amount; weak pending-state hierarchy; generic large payment action;
icon-only status with no visible state. Assess search/scanner relevance against
actual callbacks rather than remove globally. Partial rows are normal scrolling.

Reuse the existing dashboard header/alerts list/content and finance route guards.
Show a compact attention heading/count, compact customer/reference hierarchy,
labelled amount meaning, clear outstanding state and precise review action.
Keep full item/reference detail accessible without losing stored text. Never use
bill total as a refund amount. Preserve original identity, routes, revalidation,
finance focus, dismissal permissions and all business records. Responsive normal
and large text; no controls overlap or forced single-line amount clipping.

Before edits demonstrate focused visible failures, then test labels/full-detail
access, long lists/references, large amounts, normal/200% text and stale/correct
Store action guards. Inspect actual OPPO hot-reloaded result without executing
payment/refund/provider queries or changing commerce data. Synthetic host fixtures
are automated evidence only, never runtime evaluation data. No new screen/route,
backend/API, native dependency, APK/install, push, another tree or policy/registry
expansion. Search/scanner decisions must preserve their supported entry points.

All other mapped settings/product/offers/order/recovery/feedback/analytics scope
remains open. This ticket cannot complete missing services or claim APK parity.

## Implemented and checked — 16 October 2026

Existing alert header is compact with visible selected preference and Needs
attention count. Removed only this view's generic search/scanner band: traced
callbacks open general saved-record search or catalogue scanning, not an
attention-specific filter. Those entry points elsewhere are unchanged; Back
remains. No global header/profile redesign.

Finance alerts use a nullable presentation projection, not another stored model:
customer labelled separately, abbreviated preview reference with exact selectable
full reference in Full details, two-line item summary with every original item
in expandable details. Outstanding payment/refund/settlement state is prominent;
bill total and settlement amount remain distinct. Pending refund amount is not
available in WorkspacePaymentRecord, so explicitly unavailable, never inferred
from amountMinor/refundedMinor. Existing invoice acceptance binds amountMinor to
invoice.payableMinor and review records derive it from order total. Original
finance focus/actions/guards are unchanged; Review refund only opens review.
Supplied update time/staleness stay visible; active fulfilment remains visible,
while completed-order history is in full detail. Other alert types keep their
existing actions/layout. All original identities/data/detail remain retained.

Failing-before2 new normal/200% tests reproduced missing heading. Candidate6-case
run caught missing Awaiting acceptance in collapsed payment preview: restored the
active fulfilment line, not weaken the existing test. Subsequent6 passed. Wider
final run22 passed,0 failed,1 existing local screenshot/review-evidence test
skipped. Coverage includes new21-item/long-reference/100-crore fixtures, normal/
large-text full-detail access, 1000 payment/order exact routing, stale/resolved/
cross-Store actions, supplier alerts, LF15 status truthfulness and LF16 editors.

The wider run exposed2 inherited FREEHEADER failures expecting profile on Orders,
contrary to founder-approved Batch02 home-only profile architecture. Corrected
the test to check unframed48px profile/callback on Store home, its absence on
Orders, and retained48px unframed alerts/callback on Orders. No profile was added.
Other development failures: overbroad full-items finder matched summary and
expanded content; scope the assertion to expanded details. A plain-name command
with regex alternatives selected no tests and is not a pass; reran with --name.
One admission patch with unordered hunks rejected atomically; ordered exact
hunks then succeeded. No history/registry/policy expansion followed these errors.

OPPO current-source hot reload3216ms; actual attention list now has heading5,
visible Open preference, labelled customer9000091941, original bill1616 and260,
distinct Refund pending/unknown amount and update dates. Opened first Full details
only: exact ORD-1790492160769743 and all21 original items through OPPO37E Rice0003
are visible/readable. Viewed task outputs/lf17-attention-after-20261016.png and
lf17-attention-expanded-20261016.png; collapsed again for morning review. No
Review payment/refund, settlement/provider query or transaction was executed.
Large-text and100-crore cases are host-only, not fresh native settings checks.
No new APK/build/install or push. Architect context-only review found no material
blocker after confirming field meaning, freshness, callbacks and active fulfilment.
Founder morning acceptance and the rest of the mapped goal remain pending.
