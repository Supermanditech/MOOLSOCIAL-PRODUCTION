# Fresh Redmi Buy corrections — 5 September 2026

Ticket: UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905. Classification: mvp_required.

## Authority and immutable starting point

Founder requests fresh Redmi real-user audit, registration of actual defects, then necessary Cursor-owned corrections one by one, local regression, a new review APK and original-sequence Redmi retest. Standing authority remains active; no GM CURSOR or stop instruction has arrived. WhatsApp remains prohibited. This serialized child starts from the clean, pushed, exact remote-equal audit checkpoint `a09a2ecccf1e701a60117bdf34aa6a732cb132e2`, descended from source correction `e2dd3bc706065fbc08d9c526c48e24374cd32e6e` and accepted combined baseline `f94cfd4752dd73b58a69568475803d6cf25cb8d0`.

Worktree: C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-redmi-fixes-v1-20260905.
Branch: work/cursor-ui/buy-redmi-fixes-v1-20260905.
The audit branch remains preserved and does not mutate concurrently. No merge, integration, history rewrite, production/accepted checkout edit or Codex-owned source consumption.

## Minimum outcome and reuse assessment

Correct the existing customer journeys identified by fresh R66-UAT-001–035, preserving a separate reproduction/test/retest for every finding. This is not permission to add 35 screens or a new marketplace. The 35-row register in `docs/quality/cursor-buy-redmi-uat-v1-20260905/DEFECTS.md` remains authoritative; incomplete coverage and operational boundaries in UAT.md remain open, not passed.

Reuse existing catalogue, saved sheet, scanner, Buy session, cart, checkout, product/store views, comparison, orders and tracking. No new screen/route/backend owner is planned. Exact source/target actor and recovery are mandatory for each atomic slice:

| Initial sequence | Exact customer capability and required recovery | Findings |
|---|---|---|
| 1 | Retail/Wholesale buyer can keep or clear only their selected Saved collection; Back never deletes | 018 |
| 2 | Buyer can scan or enter a code with honest camera capability, empty-input feedback, readable keyboard actions and Back | 021/022/031 |
| 3 | Buyer can read current prices and tap scoped cart/actions at normal or enlarged text without hidden hit regions | 004/005/006/008/009/026/028/029 |
| 4 | Buyer can return through saved/store/product/cart/comparison/alerts to the actual origin without cross-scope leakage | 007/013/017/023/025/033/034 |
| 5 | Buyer can inspect compact product/recent/sparse-result information and recover filters without losing unique purchase facts | 003/014/016/020/030 |
| 6 | Review buyer receives collision-free local order identity and truthful address/progress/price/offer/basket/payment-state presentation | 002/010/011/012/024/027/032/035 |

Shared orientation (001), provider promise eligibility (019), authoritative per-item resolution (015), live supplier/payment/COD/courier adapters and actual preference persistence require explicit owner-boundary assessment. Implement only truthful Buy projection/fallback within this claim; do not invent commercial policy, real delivery, payment success or backend availability. Codex owns Workspaces, shared Chat/Care/routing and backend/native integrations.

## Exact claimed implementation owners

A claim is an upper bound mapped to the listed observations, not a requirement to edit every file. One coherent finding/slice is implemented at a time. Unused owners remain byte-identical.

- apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_views.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_scanner.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_design.dart
- apps/mobile/lib/features/buy/buy_v2_session.dart
- apps/mobile/lib/features/buy/buy_v2_models.dart
- apps/mobile/lib/features/buy/buy_v2_content_contracts.dart
- apps/mobile/lib/features/buy/buy_v2_order_resolution_contracts.dart

Focused existing tests (no historical golden replacement):

- apps/mobile/test/ui_v2/buy/buy_v2_saved_clear_sheet_motion_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_manual_code_sheet_motion_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_responsive_product_grid_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_recently_viewed_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_widget_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_shopping_settings_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_shopping_alerts_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_honest_recovery_origin_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_decision_glance_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_compact_action_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_order_delivery_address_context_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_honest_order_motion_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_order_progress_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_order_resolution_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_search_result_recovery_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_discovery_refinement_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_variant_selection_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_wholesale_trade_decision_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_benefit_selection_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_benefits_preview_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_session_test.dart

Five existing audit documents remain claimed only for honest status/provenance updates in this child; their previous Git snapshots and all external capture triples remain immutable. New results owner: docs/quality/cursor-buy-redmi-fixes-v1-20260905/RESULTS.md.

## First atomic slice and test plan

R66-UAT-018: reuse `_SavedClearDecisionSheet`, `_confirmClearSaved`, existing Saved operations and motion. Preserve design/shape/colour/normal spacing. Make both complete 44dp-or-larger actions visible above Android system navigation using real layout constraints. Test 320/360/430dp widths, compact height, normal/140%/200% text, safe-area padding, reduced motion, Keep, Back, confirm and other-scope/cart preservation. Reproduce the current failure before source correction; then focused tests and two affected connected regressions. Future slice-specific results are recorded independently.

No source acceptance from semantics alone, no overflow suppression, no blind golden update and no duplicate state/navigation owner. Native command exits and complete logs must be retained. Fresh unexpected failures get an evidence/child record before retry; existing registered reproductions remain permanent.

## Device, build and completion limits

Existing installed r66.1 is review-only, package com.moolsocial.app.cursorreview, APK SHA 30A71FE8B6696BF51400FBED5A90C3179E25CE0A6153A998F5A041657C9D35C3. Its captured defects are not yet fixed on the phone. No current build authorization is consumed by implementation; each later candidate must pass the existing source-bound build gate and receive unique provenance/version.

Redmi TG8HCYTGGQT885OF only. No OPPO, WhatsApp, real payment/order/refund/supplier message/call, external recipient sharing, production app mutation, deployment or laptop/device shutdown. Preserve review data and restore temporary font/density/rotation settings. Live/unavailable backend states, physical optical decoding and untested cases stay explicitly unqualified.

Commit source/test/results atomically per slice, run mandatory gates, push and verify exact remote SHA equality. Register new shared-owner findings for Codex; do not integrate now. Founder final review remains required; neither this bootstrap nor a host-test pass is acceptance.

## Founder-authorized dependent-test ownership amendment

On 5 September the founder authorized Cursor to register the existing honest-order-motion test for R66-UAT-002/011, and confirmed that Codex received the coordination message. The claim grows from40 to41 owners, with no additional product, shared, native, backend or integration owner. The founder's morning resumption limits execution to the35 fresh Redmi observations and necessary children; the earlier no-GM statement above is historical, not current sequencing. Existing source and evidence commits remain intact.

One coordination-only checkpoint must have parent c6ffece62a6e4dea0810b88eb7fc98775c832fe6 and change exactly the coordination policy, this manifest, its local scope-state hash binding and the coordination gate. Its sole purpose is the exact test owner and safe admission while seven checksum-bound drafts remain unstaged. Do not commit those drafts in the ownership checkpoint; afterward the normal fully-staged atomic implementation and clean-handoff gates apply. Freeze all four coordination blobs after that checkpoint. Do not waive tests, alter the global registry, create a new worktree, touch Codex files or integrate. Run positive and fail-closed gate checks before the checkpoint; correct and qualify the dependent test afterward.
