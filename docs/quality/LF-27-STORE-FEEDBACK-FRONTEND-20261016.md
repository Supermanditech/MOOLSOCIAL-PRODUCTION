# LF27 — Store customer-feedback frontend, 16 October 2026

Parent: LF13. Actor: Retailer/Grocery Store owner. Classification: mvp_supporting.
Founder delegated the minimal frontend versus wait-for-API choice; decision is the minimal frontend now, provider disconnected. New checkpoint review pending.

## Smallest complete scope

Orders entry and order-scoped entry, inbox with Overall order / Store service / Product filters, detail and capability/audience-guarded reply/report fields. Reuse WorkSession account/Store/navigation lifetime and existing Orders surface. No global route or duplicate buyer review datastore. Buyer submit target is not a Store authorization payload.

One optional frontend-proposed adapter supplies exact account/Store page, availability/coverage, central review IDs and opaque versions, permitted author/content and receiving-Store order/product references, and explicit action audiences. Default absence means unavailable, never verified empty. Duplicate pages deduplicate identical IDs/versions; conflicting versions demand refresh, not invented recency.

Commands capture original operation ID, scope, review/version, audience and content. Correlated acceptance/rejection only; timeouts/malformed/mismatched results remain unknown, no blind retry. Reconcile the original command. Session holds are not restart recovery. Enabling live actions requires a separately qualified durable-recovery adapter; this slice connects none. Never mutate customer text/stars, locally hide reports, disclose private buyer/full mixed-order data or aggregate overall into Store/product ratings.

## Acceptance and exclusions

Host-only fixtures test unavailable/empty/partial/error, scoped paging, filters/detail, scope/lifetime races, permissions/audiences, original-command recovery and retained typing, compact/enlarged layout and Orders return. Native OPPO verifies real unavailable state/navigation only; no synthetic feedback or live submission. Saved Cart/Stock/transactions preserved.

Live feed, agreed backend API, authorization, moderation, durable command recovery, order-link authority and analytics synchronization remain dependencies. No endpoint guesses, backend, runtime seeding, actual review/reply/report, APK, push, policy/registry expansion or framework. Existing literal ticket/path admission only; safety predicates/history unchanged.

## Results

Frontend slice implemented; founder review and live/provider acceptance remain pending.

Preparation correction: the first admission attempt rejected the unsupported
`thin_adapter` disposition label before application edits. Use the existing
disposition vocabulary; the optional frontend seam remains described explicitly.
No validation rule was changed and that attempt is not a pass.

First host run: 20 passed, four widget cases failed; not acceptance. Correct the
opaque ColoredBox hiding ListTile ink and test scrolling to lazily unmounted
header controls. Reply submission also did not reach its pending assertion;
diagnose the actual interaction before retry. Initial analysis warnings were
removed; subsequent analysis has zero errors/warnings and eight existing
dashboard style infos. No runtime data was changed.

Second host run: 22 passed, two test viewport assertions failed after lazy-list
scroll/rebuild; do not count it as green. Material/ink and send-after-frame fixes
worked. Re-settle and reveal actual controls before hit-testing, without silencing
missed taps or weakening command assertions. Add scoped order-link validation at
the controller boundary so a retained callback cannot navigate another context.

Third host run: all25 feedback cases passed. Architect review then identified
three additional concrete gaps, not covered by that result: reentrant context
changes during notification could still dispatch, old composers could rebind to
a refreshed version, and stale draft/completion callbacks lacked an editor
generation binding. Add failing reproductions, fix only those boundaries and
rerun. Native/provider acceptance remains pending.

All four new reentrant/stale-editor reproductions failed before the fix, then
all29 leaf cases passed after binding context/read-epoch/review-version and
rechecking immediately before dispatch. The first integrated Orders test attempt
did not compile: the new test registration preceded its local mount helper.
Move that registration below the helper; this is a host-test placement error,
not an application failure. Root-relative inspection must run at repository root,
not apps/mobile (the accompanying hash read used the wrong directory).

## Final scoped evidence

- Optional typed adapter, session-owned account/Store controller and Orders inbox/detail/reply/report view implemented. No adapter is connected in the app. Existing buyer feedback and Store operational authority remain separate.
- Final affected group: 748 passed, 21 pre-existing skips, zero failures (feedback30 + existing Store atomic operations and buyer feedback scope). Orders integration: two additional passed cases at360x720/100% and640x360/200%, preserving products/orders/invoices. Intermediate layout assertions were lazy-list fixture reachability issues; unavailable status now precedes filters and the test scrolls/reveals before asserting.
- After final unknown-refresh/undispatched-draft assertions and selected-check contrast correction, all30 feedback cases passed again. Timeout keeps the original hold; a late acceptance cannot clear it. Refresh cannot enable duplicate submission; only correlated reconciliation resolves the original. An undispatched submission clears its own hold without losing the draft.
- Analysis: zero errors/warnings; new feedback leaves/test have no issues. Broader touched analysis retains nine existing style infos (eight dashboard, one layout test).
- Architect pre-plan and final context-only review completed. Four new reentrant/stale-editor regressions failed before repair and passed afterward. No remaining critical blocker identified by that review; it is not independent source/device/provider qualification.
- OPPO2b3e0f71/com.moolsocial.app.runtime: actual source hot restart5278ms, VM readback confirms both new leaves/bindings; contrast successor hot reload one library1730ms. Orders -> Customer feedback -> Store service/Product -> Back to customer orders exercised. Default unavailable state is truthful, no invented zero/feed/reply/report. Screenshot inspected at task outputs/lf27-feedback-final-20261016.png. Native populated/reply/report, enlarged text/landscape and real provider paths remain host-only or unverified, not passed native cases.
- Restart retained the one-item₹164 Cart readback and Store overview₹29550 Stock cost,18 low-stock products,24 available/6 unavailable. No new Stock/order/invoice/payment/review/reply/report, feedback backend call, runtime injection, APK or publication was performed. Original financial/provider holds were not operated.

Limitations: `commandRecoveryReady` is an adapter assertion, not proof of real authorization or recovery. Before any live adapter is enabled, qualify authentication/Store membership, permitted privacy projection/audience enforcement, original-command durable restoration/correlation, moderation and real feed paging/versions. The current hold and reply drafts are session-local. This source checkpoint does not close LF13 or the whole frontend/MVP.
