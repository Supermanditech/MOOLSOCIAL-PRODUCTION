# r66.14 local qualification

Source/test HEAD: 7dbb7f87f598e0a372fdef5097d2682d35d49c5c. Runtime unchanged during these runs. Logs retained under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/dashboard-load-implementation-20260909/.

| Run | Result | SHA-256 |
| --- | --- | --- |
| product-copy-contract-focused-v1.log | 8 passed, exit 0 | 412EEB54C45419C6F606B88F80EE8876E6E9E5DC6D10342762E8644D57F1AEAE |
| product-copy-contract-buy-combined-v1.log | 138 passed, exit 0 | 42445292FC33A1743F378E40E11D4931BDDDBF770C4AC4CF8FD19B921C236642 |
| product-copy-contract-analysis-v1.log | Full analysis: zero issues, exit 0 | 745F8775F89DA0D6DCC7997A30EEAD07C9D51B450AB198140D2C7DB8F01F72FC |
| store-preapk-7dbb7f87-connected16-cycle1.log | 1422 passed, 81 skipped, exit 0 | B64226673B7A976D2A49117C7CACFC9403492DD277EC5E0A423B7E5615061920 |
| store-preapk-7dbb7f87-remaining28-cycle1.log | 402 passed, 2 skipped, exit 0 | 766938A124BBA4E7AA93E8863E242BCA9359B3D8DFB19C2A1E3565A3C84C79A7 |

Cycle 1: 1824 passed / 83 existing skips / zero failures. Cycle 2 and review-only isolation pending. Counts from overlapping focused suites are not summed into cycle totals. Protected-reference exclusions remain the existing boundary, not new passing evidence.

Each cycle runs both partitions below, from apps/mobile, using C:/Users/jisal/develop/flutter/bin/flutter.bat:
`flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference <exact partition files>`

## connected16

```text
test/ui_v2/work/work_main_v2_test.dart
test/ui_v2/work/work_opportunity_home_c24g_test.dart
test/work_production_gateway_test.dart
test/work_store_atomic_operations_test.dart
test/work_vertical_slice_test.dart
test/work_workspace_layout_safety_test.dart
test/chat_flow_test.dart
test/chat_settings_hub_test.dart
test/global_contextual_chat_shell_test.dart
test/universal_intent_completion_test.dart
test/ui_v2/buy/buy_v2_router_test.dart
test/chat_draft_continuity_test.dart
test/chat_message_controls_test.dart
test/chat_photo_attachment_test.dart
test/chat_media_voice_delivery_test.dart
test/chat_inbox_controls_test.dart
```

## remaining28

```text
test/ui_v2/profile/global_help_support_v2_test.dart
test/ui_v2/profile/global_privacy_preferences_v2_test.dart
test/ui_v2/profile/global_security_v2_test.dart
test/chat_production_gateway_test.dart
test/ui_v2/universal/mool_domain_action_catalogue_c25b_test.dart
test/ui_v2/universal/mool_six_domain_route_projection_c25e_test.dart
test/ui_v2/universal/uaw_r08_personal_book_exposure_test.dart
test/ui_v2/universal/uaw_r12_personal_legacy_route_containment_test.dart
test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart
test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart
test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart
test/core/design/mool_motion_primitives_test.dart
test/android_review_share_contract_test.dart
test/ui_v2/buy/buy_v2_screen_test.dart
test/ui_v2/buy/buy_v2_session_test.dart
test/ui_v2/buy/buy_v2_address_sheet_motion_test.dart
test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart
test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart
test/ui_v2/buy/buy_v2_wholesale_checkout_pack_count_test.dart
test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_lines_test.dart
test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_location_test.dart
test/release_runtime_configuration_test.dart
test/global_customer_copy_professionalization_test.dart
test/ui_v2/universal/mool_native_back_control_test.dart
test/ui_v2/social/uaw_personal_mvp_social_youtube_account_state_journey_c30j_test.dart
test/ui_v2/profile/global_profile_entry_contract_test.dart
test/ui_v2/profile/global_personal_profile_v2_test.dart
test/platform_configuration_test.dart
```

## Focused and visual evidence

The full commands, original failures, corrections and 14 actual Flutter catalogue captures are retained in ../codex-oppo-r66-13-review-20260909/ticket-and-screen-coverage.md. Final focused Store restock journey: normal 412x915/100% and compact 320x568/200%, retained cart/search, keyboard, Clear search, populated results, promotion reveal and Back all pass locally. Capture manifest digest: 97EF90F63F8B87E0C315597DEDBE4F576397724295B35B07714227026A6DAC87. This is not physical OPPO/TalkBack acceptance.

Two separate inherited Buy/Chat cases remain unqualified outside this unchanged 44-file current-contract set: order Help single supplier conversation, and Medicine Help exact Care return. Preserve their prior failing evidence; no new exclusion or generic-copy weakening.
