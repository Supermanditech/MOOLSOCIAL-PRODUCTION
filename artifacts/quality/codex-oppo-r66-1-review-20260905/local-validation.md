# Codex OPPO r66.1 local validation

UI-review candidate only; not production or founder/device acceptance. Flutter 3.44.6 / Dart 3.12.2. No protected golden was generated or accepted.

- Shared Universal focused correction: 19 passed.
- Connected cycles 2 and 3: each 601 passed, 72 existing capture skips, zero failed across the same 32 files.
- Final connected cycles 4 and 5: each 602 passed, 72 existing capture skips, zero failed, running the relocated current platform contract and the added Android isolation check.
- After the Android-only build condition, platform/runtime cycles 1 and 2: each 26 passed, zero failed.
- Full final Flutter analysis: zero issues. The Android change does not alter the Dart journey implementation; actual native task-state checks are reported separately in prebuild-validation.md.
- Runtime isolation suite: 12 passed, including debug-only/provider-free mode and fail-closed startup.
- Candidate binding condition: one positive and 13 negative controls passed before the additional exact Android owner; no general roots changed.

The failed original cycle and two focused attempts are retained in the candidate contract and external evidence. The earlier repository-wide audit (2454 passed, 385 failed, 112 skipped) remains a failed historical audit; these targeted qualifications do not reclassify it.

## Exact connected command

Working directory: apps/mobile

`flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference` followed by:

- `test/ui_v2/profile/global_help_support_v2_test.dart`
- `test/ui_v2/profile/global_privacy_preferences_v2_test.dart`
- `test/ui_v2/profile/global_security_v2_test.dart`
- `test/ui_v2/work/work_main_v2_test.dart`
- `test/ui_v2/work/work_opportunity_home_c24g_test.dart`
- `test/work_production_gateway_test.dart`
- `test/work_store_atomic_operations_test.dart`
- `test/work_vertical_slice_test.dart`
- `test/work_workspace_layout_safety_test.dart`
- `test/global_contextual_chat_shell_test.dart`
- `test/chat_flow_test.dart`
- `test/chat_settings_hub_test.dart`
- `test/chat_production_gateway_test.dart`
- `test/ui_v2/universal/mool_domain_action_catalogue_c25b_test.dart`
- `test/ui_v2/universal/mool_six_domain_route_projection_c25e_test.dart`
- `test/ui_v2/universal/uaw_r08_personal_book_exposure_test.dart`
- `test/ui_v2/universal/uaw_r12_personal_legacy_route_containment_test.dart`
- `test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart`
- `test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart`
- `test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart`
- `test/core/design/mool_motion_primitives_test.dart`
- `test/universal_intent_completion_test.dart`
- `test/android_review_share_contract_test.dart` (cycles 4/5; cycles 2/3 used the corrected historical owner before its relocation)
- `test/ui_v2/buy/buy_v2_router_test.dart`
- `test/ui_v2/buy/buy_v2_screen_test.dart`
- `test/ui_v2/buy/buy_v2_session_test.dart`
- `test/ui_v2/buy/buy_v2_address_sheet_motion_test.dart`
- `test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart`
- `test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart`
- `test/ui_v2/buy/buy_v2_wholesale_checkout_pack_count_test.dart`
- `test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_lines_test.dart`
- `test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_location_test.dart`

## Retained evidence hashes

Root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/codex-oppo-r66-1

- focused3.result.json: exit 0; log SHA-256 `9FFD14D315973A38F6DA28FAE81A7D4F364D28BDFDFB185CBE48D5D9F6E265D7`.
- cycle2.result.json: exit 0; log SHA-256 `E869DC277F28FDA36ECF16A3F9A9C73B3B40DEE9A8E661794497A6F11E6B1839`.
- cycle3.result.json: exit 0; log SHA-256 `A427AEBB31FD737CDAB2343051749AD8F2E03CFA336E06B1C313F8364C43536A`.
- analysis-final.log.result.json: exit 0; log SHA-256 `87BEE99745E4DD054DDE6B3500C2CAECA9B9CEE9F529B25AD8F929DC4FE43ABE`.
- platform-cycle1.log.result.json: exit 0; log SHA-256 `E588EE7FB12D5ADC6F0E4A5FBC1BBC93A88BD3F94D4678012C2E613CC63569DF`.
- platform-cycle2.log.result.json: exit 0; log SHA-256 `E588EE7FB12D5ADC6F0E4A5FBC1BBC93A88BD3F94D4678012C2E613CC63569DF`.
- runtime.result.json: exit 0; log SHA-256 `7352A55BA389F73684FB47109A527CF95A0DC0D549FDA9E958F2B8B3846FF98E`.

## Preserved boundaries

Cursor Buy V2 source/tests, dependency metadata, pubspec/lock, main.dart, MainActivity and the immutable platform_configuration_test.dart remain byte-identical to f94cfd4752dd73b58a69568475803d6cf25cb8d0. Eighteen copied child blobs remain exact; the legacy Care scaffold differs only by the declared Back fallback. The platform child contract and Android debug check are retained in the new android_review_share_contract_test.dart, not the locked owner. No assertion is dropped from the corrected contract. The shared Universal test and Android build condition are the other bounded candidate corrections. No production services, credentials, payment, backend or device acceptance is claimed. Cursor's separately assigned responsive catalogue issue and native Gmail discard observation remain outside this candidate's completed verdict.

## Historical locked-test disposition

REG-4495: the unchanged accepted platform file independently has one obsolete source-string assertion: `release builds require live Firebase configuration` expects `Device review mode requires the isolated local emulator`, while unchanged accepted main.dart calls the current `isQualifiedDeviceReviewRuntimeMode` boundary. Attempt6 across the locked file, new share tests and behavioral runtime suite returned 25 passed/1 failed; log hash 19C9BFECB21ED9EA7561DC4DAA54D5BD0E69588FB2ABB468893A4FD972002241. This failed result is preserved. No lock hash or production bootstrap was altered. The new focused owner retains every assertion in the already corrected child contract, and the separate 12-test runtime suite verifies the actual positive/negative fail-closed behavior. This is explicit UI-review scope qualification, not a claim that the historical full suite passes.

Attempt7 current contract plus behavioral runtime: two cycles of 26 passed; full analysis zero issues. Cycle1 log SHA-256 7137DE3141765E6D78DA2D9975EAE3FAE69D6C6FC9B05A4DAF81259FD7FB3370. Analysis SHA-256 D5409E2CFFB1F8430814436A3ADD2979699F15C5F542D3ABAF465AA7055361F0. The new focused owner was subsequently formatted without changing assertions or implementation. Final formatted-owner checks are recorded below when complete.

Final connected cycle4: 602 passed, 72 existing capture skips, zero failed; log SHA-256 58572015C4533AC23ED322B3277B63894D27B30BA5F74CB64C847B768ED1F50F. The extra passing case versus cycles2/3 is the Android review task-isolation assertion. No new test exclusion was added; the historical locked file is retained as the separately reported diagnostic above, with the corrected contract run from its dedicated owner.

Final connected cycle5: 602 passed, 72 existing capture skips, zero failed; log SHA-256 938B899CB9C893FFA4162686A00A2E3D221D3100B50BAA1C187D7A4BAE7C263E. Exact commands and all 32 file names are preserved in cycle4.result.json and cycle5.result.json. The locked historical assertion remains explicitly failed as documented above, not counted among these passes. The dedicated corrected contract includes all original behavioral/platform assertions, so relocating it does not discard that coverage. Dart formatting changed only the new test owner and passes the no-write formatting check.

Final formatted-owner attempt8: both focused/platform/runtime cycles passed 26 tests, zero failed; hashes 7137DE3141765E6D78DA2D9975EAE3FAE69D6C6FC9B05A4DAF81259FD7FB3370 and 399EC47786D8523517C32021C1E2E1CEC0482B3A5694515E6C41C68932894FC6. Full analysis: zero issues, log SHA-256 A2987A7BEB3F5C44E877F6FAEB2C3BF6639A5D65BBB8C696D6F26113A4B3B327. Final git diff --check passed. All 336 source-manifest rows remain exact. Eighteen imported Chat/Care blobs are exact; only the declared Care fallback and relocated platform contract differ. No new Cursor work was read or imported.
