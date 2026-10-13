# r66.2 local validation

## Final local qualification

Source remained frozen for both final cycles. Exact command for each: `flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference` followed by the 33 files below. The first 32 are the original connected contract; the full release-runtime behavioral suite was added explicitly.

- store-overnight-final-connected2.log: 686 passed, 83 intentional capture-only skips, zero failures, exit 0. SHA256 76271D3A2FE89F5F2A8C91733323095F9B3E5564EA6FDCBCBB10B7CF6A190AFD.
- store-overnight-final-connected3.log: 686 passed, 83 intentional capture-only skips, zero failures, exit 0. SHA256 8CBE549BBC45BA7839FDF939F37991565461ABE7701D53FEC893C016F4EC417C.
- Full Flutter analysis: zero issues, exit 0; store-overnight-final-analysis4.log SHA256 9AA01FB1FBAA0F64751BB60DEC7B8F372E7024DF9D2A33CF98921D72943C7E92.
- Source manifest: 336 files, including every tracked mobile lib owner; SHA256 7327DEEC74B04B8F6FB385625CD94CEE979C9279B42A05509B776B58092BE589.
- Original atomic-operations test and all tracked dependency/generated metadata remain byte-identical to HEAD. Current Buy source/test diff is zero; no Cursor workspace or Redmi action occurred.
- New actual Flutter captures: workspace-store-overnight-review-v30-20260906. Changed full-name, status/timer and compact Workspace picker images were visually inspected after the final correction; earlier pre-dashboard and first-tap observations are retained above.

No device or live backend qualification is claimed by these results. Native OPPO testing and founder visual acceptance remain pending.

Exact test files:
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
- `test/android_review_share_contract_test.dart`
- `test/ui_v2/buy/buy_v2_router_test.dart`
- `test/ui_v2/buy/buy_v2_screen_test.dart`
- `test/ui_v2/buy/buy_v2_session_test.dart`
- `test/ui_v2/buy/buy_v2_address_sheet_motion_test.dart`
- `test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart`
- `test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart`
- `test/ui_v2/buy/buy_v2_wholesale_checkout_pack_count_test.dart`
- `test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_lines_test.dart`
- `test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_location_test.dart`
- `test/release_runtime_configuration_test.dart`


Final frozen-source connected runs are in progress. Previous successful and failed local runs remain recorded in ../codex-oppo-r66-1-review-20260905/local-validation.md. No APK or device qualification is claimed yet.

## Overnight local children — 6 September 2026

Pre-dashboard source was atomically sealed at cc6414dda1b41733f24f7141e55f11dab6fd3c35, pushed, remote-equal and clean. This successor addresses REG-4503/4506/4507: approved stores keep finance, supply and customer-reach rails before publication; the setup centre is compact; exact-order selection isolates packing/rider state and refuses unsafe switching; queue actions are content-sized with 48-pixel targets; the acceptance label and amount remain separate at 320 pixels/140 percent text; the full store name wraps in the application font; the Workspace switcher sizes to its content and clears the actual outside Android inset.

REG-4504 retains two failed owner checks. The original atomic test is byte-identical to HEAD: the new unit regression was moved unchanged to already-owned work_production_gateway_test.dart instead of widening lane roots. REG-4505 retains the wrong-directory runner, guessed manifest suffix and not-yet-created evidence claim checks; none is product qualification. The initial bounded patch guard rejected out-of-order hunks without changing source; corrected ascending hunks preserved the exact current context. A read-only hash expression parse error was corrected using a pipeline; no test/output was manufactured.

REG-4508 retains stale C24G expectations: title/progressive steps, Continue setup, When applicable and preservation of the selected Workspace on Back. Route, touch semantics, no fabricated verification, real chooser and expanded-benefits checks remain. No accessibility assertion was relaxed.

Exploratory results: child-connected1 ran no tests (wrong working directory); child-connected2 207 passed/68 skips/1 compact-queue failure; child-connected3 208/68/0 before the next visual children; child-connected4 213/70/4 (three actual picker-inset assertions plus stale C24G copy); child-connected5 216/70/1 (stale selection-clearing expectation); final-connected1 671/83/1 (older C24G contract). These failed runs remain diagnostic evidence, not passing qualification.

Frozen local six-suite replay child-connected6 passed 217 tests/70 existing capture skips/0 failures, exit 0. Full analysis4 returned zero issues/exit 0. Command: flutter test --no-pub --concurrency=1 --reporter expanded --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=workspace-store-overnight-review-v30-20260906 --update-goldens test/work_workspace_layout_safety_test.dart test/work_store_atomic_operations_test.dart test/work_vertical_slice_test.dart test/work_production_gateway_test.dart test/ui_v2/work/work_main_v2_test.dart test/ui_v2/work/work_opportunity_home_c24g_test.dart.

Actual v25-v30 Flutter PNGs were inspected. v30 incorporates the final selected-order and narrow/full-name corrections; pre-dashboard contact, prerequisites/GST guidance, document chooser/preview, review/consent, pending, clarification/rejection and approved entry were inspected across those recorded versions. Historical protected goldens were not regenerated. Final two connected runs and native OPPO review remain required.

Evidence directory: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905. SHA-256:
- store-overnight-child-connected1.log: 18C2DA42E93FCDDFEB97F550A6AE165B4C09379806ED8A550CD16C0F596D9DA6.
- store-overnight-child-connected2.log: D5C3CC9DB45205ED7AB7B8AA5D53DC6B14AA766BC6F68B7347E4724AD70EE6C9.
- store-overnight-child-connected3.log: 9043393290CC9078C3300F869A99D6F3D8A3CB6D6B397061FEDDC0B5D4FB6C27.
- store-overnight-child-connected4.log: E5792D7E5C070CBEDD921BD57BC96014050FDB15DC3249897F726AB1883D4C3E.
- store-overnight-final-connected1.log: F48191668D76DF30439181339214D27395A09100A8799D2AF709BAA31826FFCF.
- store-r66-2-positive-controls1.log: 18181264647C6E4500610D38E9CCF3FCBEC96FCD29EF98CF36504A0FD5DDE75C.
- store-r66-2-wrapper-controls1.log: 42A940CA643B07DF47D60A6132D8A1016C90CFD74D2D5CB718AB883FB2D2E4DE.
- store-overnight-child-connected5.log: 436EBB25A723F16C520DCF908D6AC2084DBB1C21ACA5F73DD75BFB4D9C317E46.
- store-overnight-child-connected6.log: EFEAE1B50D13C321F476934953B748DFC19408ACEF95E63B7C93CFCFD825A076.
- store-overnight-final-analysis4.log: 9AA01FB1FBAA0F64751BB60DEC7B8F372E7024DF9D2A33CF98921D72943C7E92.

New r66.2 candidate inputs use nine exact evidence owner names under the existing branch/task/ticket exception. No lane roots, bootstrap boundaries, general checker behavior, Cursor owner or integration scope changed. Generated provenance/install/device results are claimed only after they exist. All r66.1 artifacts remain historical and untouched.
