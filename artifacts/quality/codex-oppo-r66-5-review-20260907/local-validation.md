# r66.5 local qualification

## Scope and final source

Codex-owned Workspace and Store frontend only. Shared baseline and Cursor work remain unchanged. Source manifest: 376 owners, SHA-256 F06DECD5EE139E6C01163354DF42506EB892EE8F475196B19BB0A05A156D9673. No source or test changes after the final analysis/capture/connected-run sequence began.

Implemented dashboard-wide blue/white hierarchy, finite confirmed-digit and state transitions, pressed feedback, reduced-motion/background containment and existing first-tap surfaces. Retained approved positions and exact amounts. Completed the More time request frontend with an optional typed boundary; no local approval/extension. Corrected invoice-sheet exit ordering before opening the existing Chat draft; one system Back restores the same Store invoice without marking it sent.

## Verification results

- Full Flutter analysis: zero issues, exit 0. Log r665-finish-analysis6-20260907.log; SHA-256 D1FD222AC099557D880CD62A5EA3CAABF68A0EC851D39F0F5FD75AAF849C9BFD.
- Invoice handoff focused regression: three consecutive independent passes. Corrected1 SHA-256 07E2E6C7AF9145E9D11872B34273F50E1F696B3F9E30F8ED72380C7F7DEBBC32; corrected2 and corrected3 each SHA-256 2DBD3938829680C1C478A012E6072075D5425BEEAE4160DA3C41F82EB4BEEBBC.
- Final native capture suite: 89 passed, 0 failed, exit 0. Log r665-finish-all-views3-20260907.log; SHA-256 77EE28054AD5C3F7A68DBCA4A71E020AA1E22CAB58F4DE60016290ADAF1218E0.
- Connected cycle 8: 1315 passed, 83 unchanged exclusions, 0 failed, exit 0. SHA-256 5AE0E9269422E4E8D4AF65DF59CEB0AA16FD560771630A4C9B6541D1DDEE47EF.
- Connected cycle 9: 1315 passed, 83 unchanged exclusions, 0 failed, exit 0. SHA-256 F5E69884A81D163D544F6BD75461590523C19E29EF4CAD6E7219B5A94BE637C3. This completes two full connected runs on unchanged final source.

External raw logs and native captures: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905. Previous failed and diagnostic outputs remain preserved and registered under REG-20260906-4503-STORE-FIRST-ENTRY-AND-MULTIORDER-ISOLATION; they are not passes. The added exploratory second Back in diagnostic3 is not part of the final test. Final assertions use one system Back, the visible dashboard/invoice, absent Chat, retained invoice identity and no false send.

The 83 exclusions are existing 64 Work capture cases, 17 protected references and two Buy capture cases; no exclusions were added and none count as passes. Current native captures run separately. Protected historical references remain unchanged.

## Native visual review

156 current PNGs in r665-finish-all-views3-20260907. 122 are byte-identical to the preceding reviewed sweep; all 34 changed/new images were directly inspected. Reviewed normal, compact/140%, 200%, pressed/reduced-motion, request-time, multiple-store and customer-collection groups plus invoice-to-Chat Back. Actual first-tap statements, dues, bills, catalogue, supply/reach, status, onboarding, document, review and admin-outcome surfaces remain covered by the current/identical captures.

At enlarged text, existing horizontal financial navigation and vertical content scrolling remain intentional. Not every amount or collection control is simultaneously visible in a still; reveal/scroll and full-value assertions test access. A captured scrolled task is not represented as the initial first view. Stills do not prove physical frame pacing, keyboard smoothness, backend authority or integrated consumer collection.

All 156 image filenames, sizes and SHA-256 values are retained in r665-finish-all-views3-20260907/manifest.json; manifest SHA-256 FD099635BDA07B1B26339580203B3058382A2CE61285189AD1DA2467F90D8BB5.

## Exact connected command

From apps/mobile:

    flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference <the 38 files below>

The final two cycles use this identical file list, toolchain and unchanged source:

- test/ui_v2/profile/global_help_support_v2_test.dart
- test/ui_v2/profile/global_privacy_preferences_v2_test.dart
- test/ui_v2/profile/global_security_v2_test.dart
- test/ui_v2/work/work_main_v2_test.dart
- test/ui_v2/work/work_opportunity_home_c24g_test.dart
- test/work_production_gateway_test.dart
- test/work_store_atomic_operations_test.dart
- test/work_vertical_slice_test.dart
- test/work_workspace_layout_safety_test.dart
- test/global_contextual_chat_shell_test.dart
- test/chat_flow_test.dart
- test/chat_settings_hub_test.dart
- test/chat_production_gateway_test.dart
- test/ui_v2/universal/mool_domain_action_catalogue_c25b_test.dart
- test/ui_v2/universal/mool_six_domain_route_projection_c25e_test.dart
- test/ui_v2/universal/uaw_r08_personal_book_exposure_test.dart
- test/ui_v2/universal/uaw_r12_personal_legacy_route_containment_test.dart
- test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart
- test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart
- test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart
- test/core/design/mool_motion_primitives_test.dart
- test/universal_intent_completion_test.dart
- test/android_review_share_contract_test.dart
- test/ui_v2/buy/buy_v2_router_test.dart
- test/ui_v2/buy/buy_v2_screen_test.dart
- test/ui_v2/buy/buy_v2_session_test.dart
- test/ui_v2/buy/buy_v2_address_sheet_motion_test.dart
- test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart
- test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart
- test/ui_v2/buy/buy_v2_wholesale_checkout_pack_count_test.dart
- test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_lines_test.dart
- test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_location_test.dart
- test/release_runtime_configuration_test.dart
- test/global_customer_copy_professionalization_test.dart
- test/ui_v2/universal/mool_native_back_control_test.dart
- test/ui_v2/social/uaw_personal_mvp_social_youtube_account_state_journey_c30j_test.dart
- test/ui_v2/profile/global_profile_entry_contract_test.dart
- test/ui_v2/profile/global_personal_profile_v2_test.dart

## Native command

    flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=r665-finish-all-views3-20260907 --update-goldens --name <current capture selection> test/work_workspace_layout_safety_test.dart

Selection: S01 growth placement; OPPO S01 inline discovery/search; OPPO S02 document copy; OPPO S04 setup headers; S03 compact contact first view/draft cold restart; OPPO S06 inline review corrections; S07 S08 application; Store Review first tap/compact requirement window/compact bill actions/global Chat/requirement keyboard; Store collection actual dashboard; Store scope native; Store View v2; Store Desk exact order; Order time UI; Store finish; pickup order becomes customer pickup and produces invoice.

No protected references were regenerated. Toolchain: Flutter 3.44.6 / Dart 3.12.2. Dependency/generated owners remain unchanged. OPPO and founder review are separate pending qualification.
