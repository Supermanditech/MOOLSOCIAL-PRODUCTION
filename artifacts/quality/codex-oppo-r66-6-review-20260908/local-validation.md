# r66.6 local qualification

Qualified unchanged frontend source through 01bc64a7ed3ca9eff227be934897ed38391eabb3; 376 manifest owners, SHA-256 6E18577B4FA608FDC70F922B3B942E8314C3ACA60D252E01D2217313FCE758EC. No product or test edits occurred between these runs or during the final visual/control sweep. This is a non-promotable UI-review build qualification, not live backend or founder acceptance.

## Results

| Check | Result | Raw log SHA-256 |
| --- | --- | --- |
| Full Flutter analysis | Zero issues; exit0 | F3704911DBEED50B7A4BF1B7C265A8702CD175164006F526FA8A2667FBA8E9D0 |
| Connected cycle1 | 1339passed;83 unchanged exclusions;0failed;exit0 | 1EB4240A7160A3616839858DDCE3B18E1F7CE5AA311B4861C8A810377000E701 |
| Connected cycle2 | 1339passed;83 unchanged exclusions;0failed;exit0 | B1F05E58439D0E37CD96E7FC6DCE4EA08A9E11EC3C5E67A8AA20FC3AF61C7B97 |
| Final visual sweep | 119passed;0failed;exit0 | 26EC1516745C7BD273EE659098B1E742B1E9CCBDD0921300F4788B4059D0A9EC |
| Existing prebuild controls | Passed;exit0;376 source owners unchanged | B5FC92A415C140796A38A02313A8494A418385ED6A9286BEDBAE4A23E5B09C88 |

Logs are retained under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905: r666-document-analysis2-20260908.log, r666-final-connected1-20260908.log, r666-final-connected2-20260908.log, r666-final-visual1-20260908.log, r666-final-prebuild-controls1-20260908.log. Individual child corrections, failed attempts and earlier focused captures remain in ../codex-oppo-r66-5-review-20260907/local-validation.md and the existing regression parent. No new skip or protected golden rewrite was introduced.

## Visual disposition

163 fresh actual Flutter images in r666-final-visual1-20260908. 135 are byte-identical to previously directly reviewed sets; all28 remaining images were directly inspected. The exact filenames, bytes, hashes and prior-match references are in that folder's manifest.json, SHA-256 9AF516D6242D605784132C4CA985D0177AD29351B019C9B33DEADF2E30C5F5DA.

Normal, compact140percent and200percent layouts preserve their intended scrolling and fixed controls. Not all statement rows or full document metadata are simultaneously visible at200percent; scrolling is required. Date/time-dependent fixture text changes account for several screenshot differences. Synthetic document-font blocks are test imagery, not proof of real document legibility. Actual labelled QA-image viewing remains a physical-device check. PDF File details is honest metadata, not a content preview. These stills do not prove native frame pacing, keyboard behaviour or live services. Founder dashboard/first-tap appearance acceptance remains separate.

## Exact connected command

From apps/mobile: flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference followed by these same38 files in both cycles. Full command is also preserved as the first line of each raw log.

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

## Exact visual command

flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=r666-final-visual1-20260908 --update-goldens --name 'S01 growth placement|OPPO S01 inline|OPPO S02 document|OPPO S04 setup|S03 compact|OPPO S06 inline|S07 S08 application|Store Review|Store collection actual dashboard|Store scope native|Store View v2|Store Desk exact order|Order time UI|Store finish|pickup order becomes customer pickup|OPPO document image|Workspace request sheet' test/work_workspace_layout_safety_test.dart

Full analysis command: flutter analyze --no-pub. Toolchain remains Flutter3.44.6/Dart3.12.2. Locked dependency resolution and the tracked-support guard preserved all generated owners. APK build/install and native qualification are subsequent steps, not inferred here.
