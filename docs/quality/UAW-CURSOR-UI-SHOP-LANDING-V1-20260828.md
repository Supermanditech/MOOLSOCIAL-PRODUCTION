# UAW-CURSOR-UI-SHOP-LANDING-V1-20260828

State: `founder_authorized_for_isolated_ui_audit_and_implementation`

## Identity

- Lane: `cursor_ui`
- Work ID: `shop-landing-v1-20260828`
- Task: `/root/cursor_shop_landing_ui_20260828`
- Branch: `work/cursor-ui/shop-landing-v1-20260828`
- Worktree: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-SHOP-LANDING-V1-20260828`
- Starting tag: `moolsocial-reconciled-debug-baseline-v7.4-20260828`
- Starting commit: `369bb45599366de8a8d95a9f0824c8cb961d0692`

## Customer outcome and MVP classification

A global shopper can open Shop from Buy, understand the available shopping
paths in a compact professional landing, and use Back to recover the exact Buy
state from which Shop was opened.

Classification: `mvp_required`. Shop is an already-declared reachable Buy
destination, and the launch journey is incomplete without a usable landing.

## Smallest complete scope

- Audit the existing native Shop landing and its accepted reference evidence.
- Redesign only the Shop landing presentation and direct entry/Back journey.
- Reuse the existing Buy session, route, shared global profile and shared
  global navigation without cloning or editing those shared owners.
- Audit the accepted global profile icon, dimensions, placement and contextual
  behavior in Workspace, Care, Travel and Social, then wire Shop to that same
  shared profile entry with Shop-specific context and relevant CTA recovery.
- Preserve one brand-consistent shared profile implementation; dimensions are
  matched by component reuse, never by copying or forking profile code.
- Preserve truthful existing catalogue data and UI-only recovery behavior.
- Complete focused accessibility, entry, Back and state-retention tests.

## Explicit exclusions

- No Shop destination beyond the landing before founder visual approval.
- No backend, API, Firebase, dependency or Android/iOS configuration change.
- No OPPO action and no `com.moolsocial.app.runtime` action.
- No edit to the approved HTML screenbook during Flutter implementation.
- No duplicate global profile, account or navigation implementation.
- No edit to the shared global profile implementation unless a separately
  proven shared defect is escalated for founder authorization.

## Candidate review boundary

- Build mode: repository wrapper with `CursorUiReview`.
- Package: `com.moolsocial.app.cursorreview`.
- Version: `1.0.0-r61.5`.
- Version code: `2026082807`.
- Review device: Redmi `TG8HCYTGGQT885OF`.
- Firebase/backend startup must remain bypassed for this UI-only candidate.

## Initial owner claim

- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_design.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_shop_root_single_tap_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_shop_pharmacy_seller_continuity_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart`
- `docs/quality/UAW-CURSOR-UI-SHOP-LANDING-V1-20260828.md`

The audit may reduce this claim before implementation. Any required owner not
listed here is a primary coordination request, not implied authority.

## Test and approval plan

1. Run the coordination, incremental-ticket and applicable regression-memory
   gates at the exact baseline.
2. Read the approved Buy/Shop reference and current production owners.
3. Compare Shop against Workspace, Care, Travel and Social profile-entry
   geometry/context, then implement and format only claimed Shop UI/test owners.
4. Run focused analysis plus Shop entry, Back, state-retention, accessibility
   and customer-copy tests.
5. Qualify and build the unique UI-only candidate through the repository
   wrapper, install it in place on Redmi and iterate on visible defects.
6. Present the completed Shop landing and stop for founder visual approval
   before opening the next Shop destination ticket.

## Founder authorization

The founder authorized this isolated Cursor-owned Shop ticket on 28 August
2026, directed it to start from the exact v7.4 reconciled OPPO-qualified
baseline, and required one-screen-at-a-time visual approval.
