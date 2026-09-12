# UAW-CURSOR-UI-SHOP-LANDING-V1-FIX1-20260828

State: `founder_authorized_successor_after_preimplementation_gate_order_rejection`

## Identity

- Parent ticket: `UAW-CURSOR-UI-SHOP-LANDING-V1-20260828`
- Lane: `cursor_ui`
- Work ID: `shop-landing-v1-fix1-20260828`
- Task: `/root/cursor_shop_landing_ui_fix1_20260828`
- Branch: `work/cursor-ui/shop-landing-v1-fix1-20260828`
- Worktree: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-SHOP-LANDING-V1-FIX1-20260828`
- Starting tag: `moolsocial-reconciled-debug-baseline-v7.4-20260828`
- Starting commit: `369bb45599366de8a8d95a9f0824c8cb961d0692`

The parent branch stopped cleanly before Shop source, test, build or device
action because the incremental ticket gate did not recognize the mandatory
coordination bootstrap commit. This successor preserves that branch and fixes
only the machine ordering contract before implementation.

## Customer outcome and classification

A global shopper can open Shop from Buy, understand the available shopping
paths in a compact professional landing, enter the shared global profile with
Shop context, and use Back to recover the exact prior Buy state.

Classification: `mvp_required`. Shop is an existing reachable Buy destination
and requires a production-grade landing plus consistent shared profile access.

## Smallest complete scope

- Audit the existing native Shop landing and accepted reference evidence.
- Audit the shared global profile icon, dimensions, placement and contextual
  behavior in Workspace, Care, Travel and Social.
- Reuse that shared component from Shop and provide only Shop-specific context
  and relevant CTA recovery; never copy or fork global profile code.
- Redesign only Shop landing presentation and direct entry/Back behavior.
- Preserve existing Buy session, routing, catalogue truth and global navigation.
- Complete focused accessibility, entry, profile, Back and state-retention tests.

## Explicit exclusions

- No Shop destination beyond the landing before founder visual approval.
- No backend, API, Firebase, dependency or Android/iOS configuration change.
- No OPPO action and no `com.moolsocial.app.runtime` action.
- No HTML screenbook edit during native Flutter implementation.
- No shared global profile implementation edit without a separately proven
  shared defect and founder authorization.

## Candidate review boundary

- Wrapper/profile: `CursorUiReview`.
- Package: `com.moolsocial.app.cursorreview`.
- Version: `1.0.0-r61.5`.
- Version code: `2026082807`.
- Redmi: `TG8HCYTGGQT885OF`.
- Firebase/backend startup remains bypassed.

## Initial owner claim

- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_design.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_shop_root_single_tap_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_shop_pharmacy_seller_continuity_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart`
- `docs/quality/UAW-CURSOR-UI-SHOP-LANDING-V1-FIX1-20260828.md`

The audit may reduce this claim. A required unlisted owner is a primary
coordination request, not implied authority.

## Test and approval plan

1. Qualify the exact coordination bootstrap and incremental ticket ordering.
2. Read approved Buy/Shop and shared-profile reference/runtime owners.
3. Compare Shop profile entry with Workspace, Care, Travel and Social.
4. Implement and format only claimed Shop UI/test owners.
5. Run focused analysis, entry/profile/Back/state/accessibility/copy tests.
6. Qualify and build the UI-only candidate through the repository wrapper,
   install in place on Redmi and iterate on visible defects.
7. Present the completed Shop landing and stop for founder visual approval.

## Founder authorization

The founder authorized the Cursor-owned Shop worktree, exact v7.4 baseline,
production-grade no-regression integration quality and independent execution
on 28 August 2026.
