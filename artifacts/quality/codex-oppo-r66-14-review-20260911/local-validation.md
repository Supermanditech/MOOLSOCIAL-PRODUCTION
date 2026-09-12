# r66.14 local qualification

Source/test HEAD: 7dbb7f87f598e0a372fdef5097d2682d35d49c5c. Runtime unchanged during these runs. Logs retained under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/dashboard-load-implementation-20260909/.

| Run | Result | SHA-256 |
| --- | --- | --- |
| product-copy-contract-focused-v1.log | 8 passed, exit 0 | 412EEB54C45419C6F606B88F80EE8876E6E9E5DC6D10342762E8644D57F1AEAE |
| product-copy-contract-buy-combined-v1.log | 138 passed, exit 0 | 42445292FC33A1743F378E40E11D4931BDDDBF770C4AC4CF8FD19B921C236642 |
| product-copy-contract-analysis-v1.log | Full analysis: zero issues, exit 0 | 745F8775F89DA0D6DCC7997A30EEAD07C9D51B450AB198140D2C7DB8F01F72FC |
| store-preapk-7dbb7f87-connected16-cycle1.log | 1422 passed, 81 skipped, exit 0 | B64226673B7A976D2A49117C7CACFC9403492DD277EC5E0A423B7E5615061920 |
| store-preapk-7dbb7f87-remaining28-cycle1.log | 402 passed, 2 skipped, exit 0 | 766938A124BBA4E7AA93E8863E242BCA9359B3D8DFB19C2A1E3565A3C84C79A7 |
| store-preapk-7dbb7f87-connected16-cycle2.log | 1422 passed, 81 skipped, exit 0 | C0DD1D416771615BB96AFED8E68D13161B910B33BE2A07B0014E299A8D7EF71A |
| store-preapk-7dbb7f87-remaining28-cycle2.log | 402 passed, 2 skipped, exit 0 | 0FF802228A487AB1A130C7E3743712E2A4826A106F48DDEA519C001F3ECF382C |
| store-preapk-7dbb7f87-review-isolation.log | 5 passed, exit 0 | CCB60209614E26BBCB416972504978C27160985A241D57432F0A5B56F3D4EB1C |
| r6614-comment-counter-regression-v1.log | 214 passed, exit 0 | 954DB0FC7BDE9686C1BA3ED5E490EF30626E74565310E4416C82F3820DCDB5DB |
| r6614-comment-analysis-v1.log | Full analysis: zero issues, exit 0 | 745F8775F89DA0D6DCC7997A30EEAD07C9D51B450AB198140D2C7DB8F01F72FC |
| r6614-comment-copy-check-v1.log | Unchanged customer-copy gate passed, exit 0 | B638156BB33D2E2ABB62FC5DCEF7BB7F96C8E508E7597024C70B1AE8924D717F |

Each complete cycle: 1824 passed / 83 existing skips / zero failures. Review-only isolation: 5 passed. Counts from overlapping focused suites are not summed into cycle totals. Protected-reference exclusions remain the existing boundary, not new passing evidence.

Isolation command: `flutter test --no-pub --concurrency=1 --reporter expanded --dart-define=MOOLSOCIAL_DEVICE_REVIEW=true --dart-define=MOOLSOCIAL_UI_REVIEW_ONLY=true test/work_production_gateway_test.dart --name "r66.8 review state isolation|S07 device review defaults"`. Both flags, unique application identity, explicit submitted-case selection, unknown-case refusal and failed-submission isolation passed; no backend approval is implied.

After these cycles, the unchanged copy scanner rejected an internal comment. The only later app-file change is `work_session.dart`: `// Exact local review snapshot, not a cryptographic or backend authorization.` becomes `// Exact bill comparison snapshot, not a cryptographic or backend authorization.` Complete normalized-file comparison to 8885d98a proves exactly this one replacement; all executable code and tests remain unchanged. The two full cycles therefore remain evidence for the unchanged executable code, not a claim that they ran on the new comment bytes. Fresh atomic-operation tests (214), full analysis (zero issues) and the unchanged copy check pass. Source manifest was refreshed explicitly to 962D8984C32169F3307C79BF50BB81B41DE61332C2F69E1CFC1AB253682D00E2, with all 391 inputs verified; old failed prebuild evidence is preserved.

Comment-only verification commands: from apps/mobile, `flutter test --no-pub --concurrency=1 --reporter expanded test/work_store_atomic_operations_test.dart`, then `dart analyze`; from the repository root, `./scripts/check-user-facing-copy.ps1`. All exited 0. No test, gate, customer wording or executable behavior was changed to obtain these results.

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

## Post-r66.14 contact correction — successor source, not installed APK qualification

R6614-UAT-CONTACT-01 reuses normalizeWorkspaceMobile for primary/alternate Send code, Continue, readiness and the existing contact correction-focus predicate. Malformed text is retained for correction rather than stripped into a valid-looking value. Optional backup removal, duplicate-primary rejection, independent email/phone confirmation and stale account/contact response protections remain intact. Functional owners are work_session.dart and screens/work_workspace_contact_screen.dart; focused owners are work_production_gateway_test.dart and work_workspace_layout_safety_test.dart. No Buy, backend, native Android, dependency or approved geometry change.

Commands run from apps/mobile with C:/Users/jisal/develop/flutter/bin/flutter.bat; logs are retained under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/dashboard-load-implementation-20260909:

```text
test --no-pub --reporter expanded --concurrency=1 test/work_production_gateway_test.dart test/work_vertical_slice_test.dart --name "r6614 workspace contact mobile format|S03 contact|r6611 contact"
test --no-pub --reporter expanded --concurrency=1 --update-goldens --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=r6614-contact-format-local-20260911-v2 test/work_workspace_layout_safety_test.dart --name "r6611 contact format correction stays visible"
```

- Focused attempt1:45 passed,0 failed,exit0. Log r6614-contact-format-focused-attempt1.log SHA-256 9E5330816BE35415D3A115F858B269CCEA705C93C62D0EFF819B2B1DC9A089A0. Includes20 new format/correction cases plus existing Change/Cancel, stale send/verify, account isolation, optional backup and field-specific Continue checks; simulated gateways are not real OTP delivery evidence.
- Layout attempt1:9 passed,1 failed,exit1. Original log SHA-256 2786E0633D59F31E680D59ADEE80E0BC6CC2682D6DB9F693527BFDF3F57D2D39 and v1 captures retained. Exact alternate1213131313/412-width failure revealed the stale length-only UI focus predicate; the test was not weakened.
- Layout attempt2:10 passed,0 failed,exit0. Log r6614-contact-format-layout-attempt2.log SHA-256 07A289B82FA9C460E83BB71ED12B42CB3CC334753E8D4E60FA2088C0636319C6. Four new invalid-prefix cases supplement the original short-phone/email checks at412x915/100% and320x568/200%, with keyboard insets, visible correction/field, Cancel or optional-empty recovery and no Flutter exception.
- Ten actual Flutter images in external r6614-contact-format-local-20260911-v2 were inspected;303715 bytes, sorted filename/uppercase-hash LF aggregate SHA-256 1B4BB95C4BAB6AA953617673DA5F9254E9175F8C4F2C3A360609B67478509FBE. They show focused/scrolled correction states, not every field simultaneously or a physical keyboard/TalkBack pass. Existing approved layout remains; the top of a scrolled backup label can be outside the viewport while its value, full error and action remain visible.

Connected qualification of this contact correction:

```text
test --no-pub --reporter expanded --concurrency=1 --exclude-tags protected-reference test/work_production_gateway_test.dart test/work_vertical_slice_test.dart test/work_workspace_layout_safety_test.dart
analyze --no-pub
```

- Connected attempt1:1040 passed,79 existing skips,0 failed,exit0. Log r6614-contact-format-connected-attempt1.log SHA-256 C41ECBFBE903393D0935D91250F59BDDFEA7631CD6A5DC6AF12A312327E058B8. The existing protected-reference boundary is unchanged; default-disabled capture cases remain skipped, not newly claimed device evidence. Counts overlap the focused runs and must not be added as unique tests.
- Full Flutter analysis:zero issues,exit0,126.2seconds. Log r6614-contact-format-analysis-attempt1.log SHA-256 E5024822B6E9AAA44B6E2A28B88405AD55AE3E5121882B6A9FD1EE8E82700F13. Correct-path formatter subsequently processed both contact UI/layout owners with zero changes.

Founder then requested the complete defect report before further implementation. No additional product changes follow that request; preserve and seal this already-started correction and evidence. No new APK was built. The remaining candidate-wide prebuild cycles and successor-APK OPPO replay are still required; this child is not device-closed, and installed r66.14 does not contain these changes.
