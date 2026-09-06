# r66.3 local child qualification

Original r66.2 native evidence is preserved in ../codex-oppo-r66-2-review-20260906/device-review.md and the external native capture directory. Full test stdout/stderr and failed attempts are preserved under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905.

Final six-suite capture replay: 232 passed, 70 intentional capture-only skips, zero failures, exit 0. Full Flutter analysis: zero issues, exit 0. Both final 33-suite connected cycles passed as recorded below. No APK or native successor pass is inferred from local tests.

Command: flutter test --no-pub --concurrency=1 --reporter expanded --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=workspace-store-overnight-review-v34-20260906 --update-goldens test/work_workspace_layout_safety_test.dart test/work_store_atomic_operations_test.dart test/work_vertical_slice_test.dart test/work_production_gateway_test.dart test/ui_v2/work/work_main_v2_test.dart test/ui_v2/work/work_opportunity_home_c24g_test.dart. Only opt-in external review captures were produced; no protected historical golden was regenerated.

Coverage includes account-scoped interrupted camera recovery, cancellation/expiry/error, in-flight account switching, zero stored OTP secrets, native-picker filename presentation, same-document retry feedback, OTP focus/keyboard clearance, submitted business-name continuity, direct approved entry, existing retailer setup validations, stable nested procurement search state, exactly one exposed contextual footer, accessible finance/supply actions, compact bill review and truthful off/paused/private copy. Parent Store/Stock tabs remain actionable from child destinations. Buy Direct remains a Store offer entry; procurement, catalogue and Group Bulk Buying use Stock context.

Actual Flutter PNGs were visually inspected across v31, v32 and v34: all pre-dashboard states and all 33 numbered first-view/first-tap/keyboard/large-text captures. Final v34 verifies rail selection after the last source change; v32 verifies Cost price/Sell price fit. The eight-image tool batch that exceeded context was not counted; its images were separately reviewed in batches of three. Test-rendered Buy font glyphs are not native typography acceptance; Buy content remains Cursor-owned, while Work hosting, search persistence, footer and accessibility are tested here. Native camera process-recreation and final appearance remain successor-device checks.

Failed attempts remain diagnostic only: focused1 152 passed/79 capture skips/7 failed; focused2 157/79/2; focused3 158/79/1. The final focused accessibility-tree test passed; it checks the exposed semantic traversal rather than treating an excluded child's nearest ancestor as that child. Capture1 225/70/3 exposed stale direct-dashboard copy plus duplicated parent/modal error presentation, both corrected. Capture2 passed 228/70/0 before the visual navigation child. Capture3 did not compile the layout suite because its local fixture declaration followed new callers; other suites passed 86 with 2 skips. Capture4 passed the complete corrected set. No failed or partial attempt is qualification.

SHA-256 evidence:
- oppo-r66-3-full-analysis2.log: 181A2942EA46D73D04A2E86540C6F13B9497984C31D40E9824AFAF92E4A48812
- oppo-r66-3-local-capture1.log: 64F389C726A5180BAF68FEDCB50A4E985E5DBADF8BF6159C35DA61BF08BD72C1
- oppo-r66-3-local-capture2.log: 7C0C264D35FB50E81B737E2561ADF662DDC244F577B5694551FBCFAAA222F85F
- oppo-r66-3-local-capture3.log: 1059AD95AB6B32A9EA03C2568399A8B9AA1AFBC60ED0D8F27616D9D729DD3926
- oppo-r66-3-local-capture4.log: 9DDCEAF182240008BC05BB2788B30391DBDA5CCA2EABFA2CD9613CE860F01699
- oppo-r66-2-child-focused1.log: 88AD556E134364B09411CD4C0F0BC0B4FF84F5CF8C5716BB630A080903CECF9D
- oppo-r66-2-child-focused2.log: B33A907F76C3382112EF3C72589EF5C62CBC0E4875D980C17739B6AC80097EFE
- oppo-r66-2-child-focused3.log: 6D0505F1BEB70ED083F62E1712008C4698505693553C06FE7A973009DA565FD5
- oppo-r66-2-child-semantics4.log: C5A6B3EA5C9A15CA3BB2F647FF41E0BAA8189CC349F98101A248EB1B66AB2D07

## Final frozen-source qualification

Both serialized 33-suite cycles passed 701 tests, 83 intentional capture-only skips, zero failures, exit 0. Cycle 1 SHA-256: 9F9325F36267BC6872B0966174AC24671DFD6C30E07AC632B6F3030BDB2EB532. Cycle 2 SHA-256: 54D271F51892D2FE5F1C0882A3C2A1BD43922624517318AA7A6740EC447C5230. Full analysis is zero issues; format check reports 10 files, zero changes (SHA-256 5FB519407C7ACC0F99C137D70450F4E14E9AD85DD9940428920DB6C234C71216). Toolchain: Flutter 3.44.6 stable, framework ee80f08bbf, engine 83675ed276, Dart 3.12.2. No source/test changed between the two cycles. The intervening registry note concerns only a fail-closed external helper text guard; it did not affect test execution or source.

Both commands: flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference, followed by this exact file list:

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

Final source manifest: 336 owners, SHA-256 44C25BEDDEDF3CE6D3EA7FC51B947A075AB81A2FB8A4CA32DEE40F3CFCD0430F. No Cursor Buy source/test, original atomic-operations test, dependency/generated metadata or protected reference changed. Existing REG-4495 protected historical runtime-copy assertion remains separately dispositioned; the complete release_runtime_configuration_test.dart behavioral suite passes in both cycles. This is not a claim that the excluded historical reference test passed.

Local capture inventory (144 preserved PNGs across v31/v32/v34): oppo-r66-3-local-visual-evidence-sha256.json, SHA-256 425CAFA606C803C32E067E890269968667A77E09F46B498589F55960E5E84CDC. Source qualification permits the next guarded UI-review candidate after positive gates and Git seal; native successor and founder appearance acceptance remain pending.
