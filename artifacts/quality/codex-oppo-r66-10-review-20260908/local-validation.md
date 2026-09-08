# r66.10 local validation

## Qualified source and explicit scope

Application input c82c7b8e2eeca36b425b98687cca78b9c41c90a6; metadata correction 6f8644f020a476308c40ba3a6495841a9b391089. Application tree e619e8fd20bbb54df2450b335d63c38296a1329d is identical. All 381 source/dependency hashes matched before and after both new cycles. Manifest SHA-256: 057E24CF2F0259DBE46E3363D2627990ACD5A409DD9769F417A7A9E40F6F0B5F.

The existing 39-file set was tested in two partitions, twice each, on identical source. This is not represented as a single 39-file command.
- Eleven connected Work/Store/Chat/router suites: both retained final cycles 1021 passed, 81 unchanged reported skips, 0 failed, exit 0.
- Twenty-eight remaining suites: both new cycles 402 passed, 2 existing capture-only skips, 0 failed, exit 0.
- Total per partitioned qualification pass: 1423 passed, 83 existing reported skips, 0 failed.

Five existing protected-reference tag exclusions remain separate from reported skips. The two remaining-batch skips are optional R56.9 address-sheet and R56.7 payment-sheet evidence captures. No new skip, weakened assertion or protected-reference change.

## Commands and complete evidence

Working directory apps/mobile; both partition commands use:
```text
C:/Users/jisal/develop/flutter/bin/flutter.bat test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference <exact partition files>
```

Eleven files: test/ui_v2/work/work_main_v2_test.dart; test/ui_v2/work/work_opportunity_home_c24g_test.dart; test/work_production_gateway_test.dart; test/work_store_atomic_operations_test.dart; test/work_vertical_slice_test.dart; test/work_workspace_layout_safety_test.dart; test/chat_flow_test.dart; test/chat_settings_hub_test.dart; test/global_contextual_chat_shell_test.dart; test/universal_intent_completion_test.dart; test/ui_v2/buy/buy_v2_router_test.dart.

Exact commands, complete logs and 14 inspected normal/200% PNGs for that partition remain in artifacts/quality/codex-oppo-r66-9-review-20260908/ticket-and-screen-coverage.md. Final log SHA-256: cycle2 B0140A9B47E07B48B30C50E4FC5AE4D0F4608A89FAAB5A620D85B252B21E4B86; cycle3 34697B177970E92C75B3A167D559E3F7DC513F8F0523E179F62EFF8C880D8F91.

Twenty-eight files:
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

Complete new raw logs under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/:
- r6610-remaining-28-cycle1-20260909.log: SHA-256 48B07C6505D3E3A5BCDF3D0BEAEBFBB6DEF5DA0081440A6496F92A5073CF78EF; exit 0.
- r6610-remaining-28-cycle2-20260909.log: SHA-256 4F5B1EBC2FA98CDDB68D269E92CA43E84B25DA77655E7D630B4A6387F2E33C28; exit 0.
- r6610-analysis-20260909.log: flutter analyze --no-pub; zero issues, exit 0; SHA-256 E839C1E02196D296B9E8A41778259EE9C587F3B4BBBB5C5F1DB7D126E627CC31.

Review-only isolation command:
```text
flutter test --no-pub --concurrency=1 --reporter expanded --dart-define=MOOLSOCIAL_DEVICE_REVIEW=true --dart-define=MOOLSOCIAL_UI_REVIEW_ONLY=true test/work_production_gateway_test.dart --name "r66.8 review state isolation|S07 device review defaults"
```
Five passed, no failures, exit 0. Covers unique application identity across gateway lifetimes, both flags, unknown-ID refusal, exact submitted-case selection and no approval from failed submission. r6610-review-state-isolation-20260909.log SHA-256 CCB60209614E26BBCB416972504978C27160985A241D57432F0A5B56F3D4EB1C.

## Remaining distinctions

The additional historical twelve-file audit containing the complete legacy journey01_test.dart suite had twelve failures; its log, pending parent comparison and legacy contract disposition remain explicit. This suite is not passed by the above results. The exact current Work Back case and four first-open interruption tests pass separately. No locked setup/sign-in source was altered.

Host qualification does not imply APK/device, physical 200%/TalkBack, live backend approval/document retrieval, OTP, notifications, payment or customer-collection security qualification. Build controls, source seal and OPPO replay remain separate.
