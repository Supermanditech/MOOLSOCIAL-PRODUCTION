# LF-13 — Customer feedback

Founder accepted ff6bfe53 and answered Approve; proceed to Batch13. MVP-required
privacy/recovery corrections to existing customer product/Store/delivery/overall
purchase rating and product-report paths; not a new screen or provider service.

Reuse BuyV2VerifiedRatingAdapter/target/request/result and exact idempotency key,
review drafts and existing sheet/motion. Current verified submission captures
owner only, then unguarded catch/finally; report callback has no current-owner
checks. Use current owner/auth/procurement/disposal scope and per-operation tokens,
validate original target and exact product/Store, recheck after notification and
await, and prevent old cleanup from clearing a new operation. Scope eligibility,
review/report caches and drafts; preserve same-owner failed-save draft and retry
key. Existing authoritative eligibility/version/Store map remains required.

Demonstrate focused failures first; test races, response correlation, draft/retry
and valid mixed-Store purchase behavior plus existing product/trust/motion cases.
Hot-reload/passively inspect OPPO without a real review/report/reply/message.
Preserve Cart164/payment hold and saved evaluation Store/Stock. Review before14.

No redesign, runtime injection, backend/moderation engine, APK, operator workspace,
other tree or policy/registry expansion. No accepted Store feedback inbox/reply/
report/feed contract was found in Work owners: keep these original requirements
explicitly unimplemented pending accepted authenticated review/Store/order/scope,
version, permission, moderation and acknowledgment contracts. Then wire/test the
actual Store/customer journey; no unavailable-only invented inbox claims fulfilment.

## Implemented / tests

Verified rating and listing report operations now use the existing owner/auth/
procurement epoch record, per-operation tokens and original target/product
binding. Recheck after notification before dispatch and after awaits; stale
catch/finally cannot notify disposed sessions or clear a newer request. Feedback
eligibility/review/report caches reset for a changed context; commerce refresh
cannot repopulate them from a late old-session response. Existing exact saved
rating/version/line/Store/purchase/provider/ship/map checks and idempotency key
remain unchanged. Identical rating retry uses the same key and retains its draft;
a successful prior submission does not erase newer typing.

Review/report sheets retain their opening feedback context, not merely owner
string. A same-owner new login makes the stale sheet non-actionable with Close;
the report sheet now listens to existing session changes. Old sheet draft writes
cannot cross that boundary. A same-account draft is preserved for reopening;
changing owner clears only in-memory draft visibility, not saved history.
The first candidate cleared same-owner drafts unnecessarily. A focused failing
regression exposed this; corrected the scope reset to preserve that draft and
separately reject old-context writes. No stored draft deletion/migration performed.

Product reports were cached by shared canonical product only. A failing Store-
replacement test demonstrated cross-Store contamination. Cache and uncertainty
keys now include Store and existing listing identity. A report throw or empty
acknowledgment becomes unconfirmed, not definitely failed; current scoped session
blocks blind retry even after generic refresh. No automatic resubmit. Reporting
contract exposes only accepted/message, no returned owner/listing/request identity
or idempotency/reconcile API: correlated provider acknowledgment and durable
uncertain recovery across restart/epoch changes remain unimplemented dependencies.

Initial22 host tests:17 demonstrated failures and5 prior protections. Additional
failed-before cases cover two open-sheet new-login widgets, unknown report retry
and cross-Store report cache. The candidate draft-preservation regression above
is separate from pre-existing defects. Final new file:27 passing cases.
Final five-file run:151 actual cases passed,1 pre-existing skipped motion golden,
0 failures; runner loading events excluded. Includes product actions/verified
ratings and mixed-Store overall purchase, marketplace trust, feedback motion and
50 prior after-sales safeguards. The skipped golden remains unpassed; references
were not regenerated. Changed session/views/test analysis: no issues. Diff check
passed. No whole-app, provider, native authentication-switch or APK claim.

Architect context-only review emphasized exact target/result correlation,
same-key retry, newer draft protection, unknown mutation safety and missing Store
inbox integration. These boundaries remain explicit; no additional framework,
policy/registry mutation, moderation logic or source owner was introduced.

## OPPO / acceptance boundary

Existing attach7508 hot-restarted in9663ms. Read-only VM source retrieval proves
exact text equality for both running buy_v2_session.dart and buy_v2_views.dart
with tested working files. Existing Cart remains one soap pack164 with original
payment review hold; no quantity/address/payment action. Opened that same product,
scrolled to feedback: Rate or review truthfully shows delivery/collection
eligibility unavailable. Did not tap Check again. Report issue opens existing
reason form; no reason selected, text entered or Send report tapped. Both Close
controls return safely; Cart/payment hold still intact. Viewed task captures:
outputs/lf13-review-20261015.png and outputs/lf13-report-20261015.png. One fresh
UI dump failed during transition; subsequent action used a separate fresh target
lookup, never stale XML. Approved feedback layout/motion otherwise unchanged.

No APK/install/account switch or native rating/report/reply/message submission.
Actual eligibility, save/readback/moderation, Store inbox/replies/report permissions
and durable report recovery remain unverified/unimplemented where providers or
contracts are absent. Customer-side safeguards do not complete the Store feedback
workflow. Keep previous public publication/settings/payment/order/tracking and
after-sales dependencies. Founder review required before Batch14 analytics
reconciliation; no automatic advancement or whole-MVP closure.
