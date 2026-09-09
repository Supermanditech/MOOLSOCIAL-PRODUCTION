# r66.11 local qualification

## Successor document fixes — final local qualification, not installed yet

REG4552 prevents a file lacking the existing PDF preview signature from replacing an attachment. REG4553 preserves full source-sheet labels, reflows choices only when needed, and pins Cancel outside the scrollable content. No other product owner, approved dashboard geometry, Cursor work, authentication, backend or dependency version is changed.

Final source SHA-256:

- work_services.dart: 89AB638622D0DB3D11AF2AD4C084387D138443B60A7DEC981666008B17276DF1
- work_onboarding_screens.dart: D9CCA1E293983983E5EDA9B5E4E79939BFEF1823E1B12860C8A1101F079C4D40
- work_production_gateway_test.dart: 832B489E3E4A6CAB6CC6D2C5BA8BEB7CCF564B67E058A3229E98F135D7952022
- work_workspace_layout_safety_test.dart: B1A6E59A9E7655BBF5A18FEE9CED8F64B89ED84DA54A065FEF5977CCA52AE0F8

All four pins remained unchanged through both final serial cycles and full analysis. Each cycle passed1487 tests,83 existing skips,0 failures; five protected-reference tag exclusions remain separate. No new skip or protected reference edit.

External evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905.

| Final log | Result | SHA-256 |
| --- | --- | --- |
| r6612-pinned-cancel-focused-attempt8.log | 20 passed,0 failed,exit0 | 94F31E03745C33655B3558B0A8BA5645D93CDE6863966FB616AC2A1CD27D7532 |
| r6612-final-pinned-connected16-cycle1.log | 1085 passed,81 skips,exit0 | 2603363F9E00D8A389F703654F09F5ADA3AB7F82140FF35F29950286F57A06DB |
| r6612-final-pinned-remaining28-cycle1.log | 402 passed,2 skips,exit0 | 677FA9C14CAE789552C07E726A34801E108C55C58589CD0A09E40A08E130DDEE |
| r6612-final-pinned-connected16-cycle2.log | 1085 passed,81 skips,exit0 | 1CE21529134A12DFBCF0202A3F342B0A2C4511ACECA3D1A04377F67C713FA038 |
| r6612-final-pinned-remaining28-cycle2.log | 402 passed,2 skips,exit0 | A20B32ECD9F12B93E4BC074BD67B02654FA9097EFC757831F474541B9305C1A0 |
| r6612-final-pinned-full-analysis.log | zero issues,exit0 | 2C6196932E1A9517F3C1BE44565F4EE6CD38F13144B069CCFC27030EF1A8C4AB |

Run from apps/mobile with C:/Users/jisal/develop/flutter/bin/flutter.bat. Execute each exact partition command below twice, in order, then `flutter analyze --no-pub`:

```text
flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference test/ui_v2/work/work_main_v2_test.dart test/ui_v2/work/work_opportunity_home_c24g_test.dart test/work_production_gateway_test.dart test/work_store_atomic_operations_test.dart test/work_vertical_slice_test.dart test/work_workspace_layout_safety_test.dart test/chat_flow_test.dart test/chat_settings_hub_test.dart test/global_contextual_chat_shell_test.dart test/universal_intent_completion_test.dart test/ui_v2/buy/buy_v2_router_test.dart test/chat_draft_continuity_test.dart test/chat_message_controls_test.dart test/chat_photo_attachment_test.dart test/chat_media_voice_delivery_test.dart test/chat_inbox_controls_test.dart
flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference test/ui_v2/profile/global_help_support_v2_test.dart test/ui_v2/profile/global_privacy_preferences_v2_test.dart test/ui_v2/profile/global_security_v2_test.dart test/chat_production_gateway_test.dart test/ui_v2/universal/mool_domain_action_catalogue_c25b_test.dart test/ui_v2/universal/mool_six_domain_route_projection_c25e_test.dart test/ui_v2/universal/uaw_r08_personal_book_exposure_test.dart test/ui_v2/universal/uaw_r12_personal_legacy_route_containment_test.dart test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart test/core/design/mool_motion_primitives_test.dart test/android_review_share_contract_test.dart test/ui_v2/buy/buy_v2_screen_test.dart test/ui_v2/buy/buy_v2_session_test.dart test/ui_v2/buy/buy_v2_address_sheet_motion_test.dart test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart test/ui_v2/buy/buy_v2_wholesale_checkout_pack_count_test.dart test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_lines_test.dart test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_location_test.dart test/release_runtime_configuration_test.dart test/global_customer_copy_professionalization_test.dart test/ui_v2/universal/mool_native_back_control_test.dart test/ui_v2/social/uaw_personal_mvp_social_youtube_account_state_journey_c30j_test.dart test/ui_v2/profile/global_profile_entry_contract_test.dart test/ui_v2/profile/global_personal_profile_v2_test.dart test/platform_configuration_test.dart
```

Focused capture command:
```text
flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference --update-goldens --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=r6612-pinned-cancel-local-attempt8 test/work_production_gateway_test.dart test/work_workspace_layout_safety_test.dart --name "REG4552|REG4553|OPPO document image pinned controls"
```

The15 new local PNGs are bound in r6612-pinned-cancel-local-attempt8/capture-manifest.json (SHA256 DE4A32547EE89E1A8D2484FE3B630824DF697A2145AA990DA0496989B2E884A0). Normal and140% controls match attempt6 byte-for-byte. Inspected200% controls have full labels, readable inline error and pinned Cancel; content remains scrollable. These are Flutter widget images, not physical200%/TalkBack acceptance.

Retain earlier failures: original final connected16 cycle1 had1083 passed/81 skips/2 pinned-Cancel failures, SHA25637099BB1F7AED574B960F2C49D4EF1AB0C478C817BC2F6770BFA869961E63638; corrected without weakening those tests. Capture attempt7 had11 passes/9 missing-reference failures due to wrong capture invocation, SHA256500EE9D4806AD88EB084986D41BADB3D86897A6ABB605EDA4606734EBB4DED04. Earlier Add-versus-Replace test-harness failure, title/choice truncation discoveries and all intermediate logs/captures remain preserved under REG4530/4552/4553; none are substituted for final evidence.

Supervised agents reviewed the supplied narrow Cancel structure and boundary scenarios through reasoning only; they did not independently run source/device tests. Primary performed edits, commands and image inspection. Native evidence113-153 is separately preserved; camera capture/save was founder-assisted, subsequent retake/cancel was Codex-operated.

Corrected APK, native replay and closure remain pending. Seven previously recorded exploratory assertions, physical200%/TalkBack, private cloud completion and real backend/admin/OTP authority remain unqualified. A PDF signature is not evidence of renderability or document authenticity.

## Original r66.11 APK qualification (unchanged)


Application source b5236a11f770cb96cecae08c5419e4881eb45578 includes both founder-selected fixes and REG-4550. Complete exact commands,44-file partition lists, existing skip/exclusion inventory, failed attempts, supervised-review scope and inspected PNG hashes are retained in the successor section of artifacts/quality/codex-oppo-r66-10-review-20260908/local-validation.md.

Final source was unchanged through both cycles and full analysis. Each partitioned cycle:1473 passed,83 existing reported skips,0 failed. No new skip or protected-reference modification.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905.

| Log | Result | SHA-256 |
| --- | --- | --- |
| oppo-r6611-post4550-connected16-cycle1.log | 1071 passed/81 skips/0 failed/exit0 | BA0840BA52A2AFD858B4814C0E756525E5447FB9A4A66DBBDFB34977C8DA7629 |
| oppo-r6611-post4550-remaining28-cycle1.log | 402 passed/2 skips/0 failed/exit0 | 6B42C98B0C7EFCA08DF27160D9C89F1CBA9FB83A63D2AA05A8E759533516916E |
| oppo-r6611-post4550-connected16-cycle2.log | 1071 passed/81 skips/0 failed/exit0 | 32250F564125323FCE226B12CDD1D4AC8FFA499793AEBC6B20187EBC260C9C04 |
| oppo-r6611-post4550-remaining28-cycle2.log | 402 passed/2 skips/0 failed/exit0 | C044D696E3AE048C14077DEA3B0F61FF73821D77014B63241BFCAF64CEB8B451 |
| oppo-r6611-post4550-full-analysis.log | zero issues/exit0 | 664B888889E9FB0FCD917BE7661FF79B1DA16A30488D758C1253906E155B837E |
| oppo-r6611-support-error-capture-attempt3.log | 3 passed/0 failed/exit0 | 97BBA9226F7E43B47894684F0ABEFD5E7E1528164B0B0837E1C8976AD9ECA8B9 |

Nine contact cases and six contact captures are retained in the referenced successor evidence. Support captures cover normal text and200% with a simulated keyboard; shortest viewport320x536 keeps48px Dismiss, scrollable complete error and composer above IME. Widget captures do not qualify native keyboard/TalkBack.

Seven exploratory assertions remain unresolved: chat_final_intent_matrix_test(1), C10D exact-return test(1), R11 continuity(3), Cursor-owned buy_v2_shop_chat_test(2). Raw log oppo-r6611-chat-regressions-attempt1.log:180 passed/7 failed, SHA256180424418F821146E6DF2A13D12BFFCBF58ABDE8C7E475FA664A2C06CBA36FC5. Their expected strings/entry keys differ from current contracts, but no executed parent comparison has established whether they are inherited/stale; unchanged product blobs alone are insufficient. No Cursor owner was edited. These are not hidden passes or a claim of all-repository production readiness.
