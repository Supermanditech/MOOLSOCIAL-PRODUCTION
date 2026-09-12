# Retailer Store procurement integration bridge

Founder standing authority; parent 35b97857f3635c01aa283635fda32ad43c608a1e.
Reuse this clean isolated checkout on a new branch; the previous child branch,
repair branch and original Codex/Cursor branches remain retained and untouched.

MVP-required integration outcome: retailer Restock/Group Buying/Buy Direct must use
the exact authenticated account, approved Store and originating operation, with
independent durable Buy state and truthful supplier/offer eligibility. Ordinary
consumer Shop remains separate. No new screen, backend grant or payment authority.

Exact functional scope: procurement state reused in existing work_services.dart
and focused existing Work tests; existing
journey_router.dart entry; work_workspace_dashboard_screen.dart; Work model/session
only where required for durable operation and exact split-order references; existing
work_workspace_layout_safety_test.dart and work_store_atomic_operations_test.dart.
Reuse BuyV2ProcurementContext, BuyV2Session and existing scoped preference store.
Never synthesize buyer approval or supplier eligibility from a display name.

Qualification: account/Store/operation changes and late responses; durable origin
and commerce-before-draft relaunch; retained cart/search/product; exact order IDs;
normal/200% Store and unchanged Shop; full analysis, connected tests, actual captures.
Backend authoritative enforcement and external provider acceptance stay pending.
No APK or final admission until the entire integration is qualified.
