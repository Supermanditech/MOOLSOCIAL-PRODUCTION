# r66.7 local qualification

## Final combined qualification

Two identical38-file serialized cycles passed on unchanged source:1339passed,83 unchanged exclusions,0failed,exit0 EACH. Cycle1:11m06s,SHA256EA27A92C282FB7F920CF136465AC16DC4FD8CEB91FDEEEC6CBF559E0D5004101. Cycle2:8m44s,SHA2568F2C148044524A6D2EFD4480072208237A0CC85227EC01FA795F75D498B36313. Logs r667-final-connected1-20260908.log and r667-final-connected2-20260908.log retain exact command, output and NATIVE_EXIT_CODE=0. All376 source hashes verified after analysis and each cycle. No source/test edit, new skip or golden rewrite between cycles. This supersedes earlier pending combined-status notes below; prebuild controls and native successor replay are separate.

## Verified focused/visual checkpoint

- Full analysis:zero issues,95.3seconds,exit0;A91C11C6D8C4152D7B257A8C2F0E9E54B43223C52703FE2ECFD536D62B525CAB.
- New focal regression before correction:3passed/3failed/exit1;106E271F331AFFD2DB2052885F11D5731B94285D468EE7B9B854EAA244390135. At320px expected scene centre144; actual72 demonstrates origin scaling.
- Incorrect initial capture invocation:0passed/6capture failures/exit1;FF84013314C2E0486B95DABBE9F7C42FB95281F9587BE4FA6197F9610BBA4DB5. Preserved, never qualification.
- Corrected focused run:6passed/0failed/exit0;33CECBEBDF6BE8274DC7EA1C7039B55C1C8FE9FFB87F3F37B46734A3FA59AE3F. Command: flutter test --no-pub --concurrency=1 --reporter expanded --update-goldens --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=r667-zoom-visual2-20260908 test/work_workspace_layout_safety_test.dart --plain-name "OPPO document image pinned controls". New external directory only; no historical reference rewritten.
-9 fresh PNGs:5 byte-identical to directly reviewed r666-final-visual1;4 others directly inspected (three centred zooms and normal Fit). Synthetic QA image/font blocks are not native legibility evidence; geometric tests verify exact focal preservation. Metadata may scroll at200percent, while controls stay visible and48px. Parent scope/motion/other163screen visuals unchanged.
-376-owner source manifest:9B54CC78770A221F127213E52B01658D44117693ECEA2556F4FFC17150AEC8BA. Both combined cycles pending.

External evidence root C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905. Capture files in r667-zoom-visual2-20260908:

```text
r666-document-320.0-1.4-corrupt-false.png 23673 BA19FEF769C356565E2AB75ED01AEB3160652F8A3367CE16AFEEC871DA95393F
r666-document-320.0-1.4-corrupt-true.png 30458 4B914E2D1A63A50E5B0F9CFB33E93480CDF4BDFF3CFECEC9793DC61AB05CE534
r666-document-320.0-2.0-corrupt-false.png 20472 1BFB3FD4421723F6EB354BE7A724CEF9A5236EB12FFF5A8AE00F66ECFA885C49
r666-document-320.0-2.0-corrupt-true.png 31132 419720CDB385E807AFBCC26CC63CB17E3D8621404552331FD771C8995706C1B2
r666-document-412.0-1.0-corrupt-false.png 34815 39160994FA3145B2A7631DB3CF08DFC5B4B585AA2F51C154A8DE960D6A1074F5
r666-document-412.0-1.0-corrupt-true.png 39297 5072725175C8711B4956BC9A6EA9C9AD492336197E6ECE3059A20677AEE6E76C
r667-document-centred-320.0-1.4.png 22956 58FBF0B0D837056FF40C1159949E426E77636A8D4E035F4590A0548DE5B405F5
r667-document-centred-320.0-2.0.png 19820 CEE3277313E2018304EB9FE014D14F1041CF3CAD6BA2AEFEC5CDDC47BCA957E1
r667-document-centred-412.0-1.0.png 34947 17F0A7A7E4316CBD13534A0DBBDA3BEF912BB523393A8DEAB574DAC8320E680C
```

Pending final combined qualification. Red test reproduced origin-based zoom:3passed/3failed/exit1 at normal/140/200percent; complete r667-zoom-regression-before-fix-20260908.log retained. First capture invocation incorrectly supplied an absolute directory to a relative capture helper and omitted capture-generation mode;6capture failures/exit1, no visual qualification or historical overwrite. Corrected fresh external capture invocation r667-zoom-focused2-20260908.log passes6/0/exit0. All assertions retained, including stable viewport focal point after pan, repeated zoom4x cap, Fit and pinned actions. Complete hashes/visual review and combined cycles to follow.

Exact combined files inherited unchanged from r66.6 (38):

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
