# r66.10 local validation

## Successor application-support correction — r66.11 host verification passed

9 September 2026. REG-4549/R6610-SUPPORT-DRAFT-SCOPE-01 corrects the confirmed r66.10 application-header/composer mismatch. Contact input remains sealed at00995b0c9755c3a74ee91b678572e24f2f65441f. The support correction is not yet committed or OPPO-qualified. This section records successor work; it does not rewrite the historical r66.10 APK result below.

The existing workspace-support conversation keeps its real thread identity. Only application-specific local drafts, replies, pending photos/files, recording state and composer feedback use the application identity as an additional key. Deliberately empty drafts remain empty. Returning to application A does not borrow B's text; generic and other conversations remain independent. Session-generation and draft-revision checks protect newer edits against late send/retry/attachment completions and reset/disposal. Retry cleanup uses the original failed-send revision. Settings and shared-content returns preserve that application scope. No backend endpoint, production application approval, authentication, Buy code, dependency or navigation route is added.

Existing focused Work fixtures now seed/read their actual application ID while asserting the unrelated generic support draft is untouched. The inbox action-size fixture first scrolls its real lazy inbox to the row before measuring; all existing pin/unread/archive/undo assertions remain. Two exact additional existing owners (chat_widgets.dart and chat_inbox_controls_test.dart) were admitted only to this continuation's literal claim; no general lane, root, lifecycle or gate behavior changed.

### Additional real accessibility child

REG-4550 caught error feedback overflowing with200% text and an open simulated keyboard. The existing fixed banner now bounds only its long text in a native scroll; Dismiss remains outside that scroll with Android's actual48px target. The calculation reserves that48px target instead of44px, reducing only spare vertical spacing on the shortest viewport. Message indexes/list placement, keyboard-safe composer, original feedback wording, full text scaling and application isolation remain intact. Other shared scaffold callers do not opt into the thread-specific height bound.

The new error-state tests pass at412x915/100%,320x568/200% and320x536/200%, all with220px simulated keyboard. They assert no framework exception, error above the composer, full scroll reach,48px dismissal and an edge tap dismissing only B while preserving A's error and both drafts. Three real Flutter captures were inspected independently. The large-text captures are deliberately after scrolling the error to its end; they are not evidence that the entire paragraph fits simultaneously. Physical OPPO200%/TalkBack and native keyboard behavior remain separate checks.

All raw evidence below is retained under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905:

| Run | Complete result | SHA-256 |
| --- | --- | --- |
| oppo-r6611-support-banner-fixtures-attempt2.log | 23 passed,0 failed; support scope,8 Work recovery fixtures and inbox action fixture | 4F80FFF939199767F2C92B4ADC24043B68339267C21AA841629D74C414F0DEDA |
| oppo-r6611-support-error-capture-attempt1.log | 1 passed,1 failed; real71px overflow, retained | 5252ECB78D9A5918664D0CA650D60C2B1AC133220FFD2BE362A5C18E6FCFE3AF |
| oppo-r6611-support-error-capture-attempt2.log | 2 passed,1 failed; shortest viewport still4px overflow, retained | C1FD8890850DCC120EC1E5E04F8E593EB04CCF3FAD469C3921FD6A907819834B |
| oppo-r6611-support-error-capture-attempt3.log | 3 passed,0 failed,exit0 after actual48px budgeting | 97BBA9226F7E43B47894684F0ABEFD5E7E1528164B0B0837E1C8976AD9ECA8B9 |

Capture command: flutter test --no-pub --concurrency=1 --reporter expanded test/global_contextual_chat_shell_test.dart --plain-name 'r6611 support feedback' --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true --dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=oppo-r6611-error-local-v3-20260909 --update-goldens. Only these new external images were created; no protected/historical golden was changed.

Capture directory oppo-r6611-error-local-v3-20260909:

```text
7F3CB120F7B1A907A29ADC9836E572E9E3BD24CFCD7428EC0450E107BA0BD19A  r6611-support-error-1.0-915.0.png
DC469ADB7631F3363C3C34D8A994F0A6685F03D56D20BFB180850C04BEBAA701  r6611-support-error-2.0-568.0.png
95C21E437E8604294CEE84D76C981074BC96C85B5B403A96B8F6835507DBCEF7  r6611-support-error-2.0-536.0.png
```

Before REG-4550's additional error/keyboard case, two44-file partitioned cycles each passed1471 tests with83 existing skips and zero failures. Those older cycles and full analysis are retained, but do not qualify the later banner change. The final post4550 two-cycle44-file qualification is now complete: each partitioned cycle1473 passed,83 unchanged reported skips,0 failed. Full analysis reports zero issues. All native/OPPO acceptance remains pending.

| Final unchanged-source run | Result | SHA-256 |
| --- | --- | --- |
| oppo-r6611-post4550-connected16-cycle1.log | 1071 passed,81 existing skips,0 failed,exit0 | BA0840BA52A2AFD858B4814C0E756525E5447FB9A4A66DBBDFB34977C8DA7629 |
| oppo-r6611-post4550-remaining28-cycle1.log | 402 passed,2 existing capture skips,0 failed,exit0 | 6B42C98B0C7EFCA08DF27160D9C89F1CBA9FB83A63D2AA05A8E759533516916E |
| oppo-r6611-post4550-connected16-cycle2.log | 1071 passed,81 existing skips,0 failed,exit0 | 32250F564125323FCE226B12CDD1D4AC8FFA499793AEBC6B20187EBC260C9C04 |
| oppo-r6611-post4550-remaining28-cycle2.log | 402 passed,2 existing capture skips,0 failed,exit0 | C044D696E3AE048C14077DEA3B0F61FF73821D77014B63241BFCAF64CEB8B451 |
| oppo-r6611-post4550-full-analysis.log | flutter analyze --no-pub; zero issues,exit0 | 664B888889E9FB0FCD917BE7661FF79B1DA16A30488D758C1253906E155B837E |

Each partition uses flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference. The connected16 list is the historical eleven exact files listed below plus test/chat_draft_continuity_test.dart, test/chat_message_controls_test.dart, test/chat_photo_attachment_test.dart, test/chat_media_voice_delivery_test.dart and test/chat_inbox_controls_test.dart. The remaining28 list is exactly the unchanged28-file list below. Five protected-reference tag exclusions remain separate from the83 reported skips. No new skip or protected golden was introduced. Product/test files were frozen through all four partition runs and analysis; only the evidence document was updated during the run.

### Supplemental failures remain explicitly separate

The broader exploratory12-file run oppo-r6611-chat-regressions-attempt1.log returned180 passed/7 failed, exit1, SHA256180424418F821146E6DF2A13D12BFFCBF58ABDE8C7E475FA664A2C06CBA36FC5. Do not report it as passed. Its complete failure list is:

- chat_final_intent_matrix_test.dart: call voice document and video intents recover without leaving Chat — expects different sharing-notice text; the relevant current/HEAD notice implementation is unchanged.
- uaw_personal_mvp_chat_global_dock_exact_return_c10d_test.dart: thread Back restores the exact live inbox query and filter — excludes the existing people filter.
- uaw_r11_personal_global_chat_continuity_test.dart: Chat returns to exact buy origin; Chat returns to exact work origin; Buy contextual send preserves its draft in production Chat — historical entry keys differ from the accepted current journeys.
- Cursor-owned buy_v2_shop_chat_test.dart: order Help stays in one supplier conversation with one composer; Medicine order Help stays on Care and returns to Care — generic Conversation title expectations differ from contextual identity.

The relevant inbox, Buy screen/views, route and entry-context blobs are unchanged by this child. This is source-based contract triage, not an executed parent-baseline comparison or closure of those seven tests. Shared dependencies can affect unchanged owners, so unchanged blobs alone do not establish that a failure is inherited or stale. Keep their owner-lane disposition pending; do not edit Cursor's tests, weaken assertions or claim all-repository production readiness. The required current-contract44-file regression set remains independently required. Native review APK qualification is not production/backend acceptance.

Native replay plan: retain app data; verify exact new saved/installed checksum; test malformed primary/email/alternate messages and independent existing confirmations without requesting real OTP; exercise application A/B support entry, edited drafts, Back/reentry and correct header/return; send no real support or WhatsApp message. Do not infer process-death Chat-draft persistence or live support delivery from in-memory/widget tests. Preserve original device drafts. Resume Dashboard first-tap review only after the two native fixes pass.

## Successor contact correction — local qualification, not r66.10 device closure

Contact implementation commit00995b0c9755c3a74ee91b678572e24f2f65441f was pushed and independently remote-equal. Its first clean check and subsequent handoff rejected only the historical memory document's CRLF/index residue after this attempt's addition had been removed. The canonical working blob and HEAD both equal dd4b219ce580be1a4a24f5b867af4b75c4afb13e. An exact-path index refresh produced zero staged changes and a clean worktree without changing document content; remote equality was rechecked. This is retained continuation evidence for REG-4530's already-registered memory-owner recovery, not a product change or new owner allowance. Do not report the failed handoff as passing; final whole-slice handoff remains to be rerun after support qualification.

9 September 2026, after standing-review commit b7049755a904cf1a370fcdcedd50fc69d36f3915: founder directed fixing both confirmed findings, local regressions, Git sealing, a corrected APK and OPPO retest before first-tap review. Contact OPPO-S03-02 is implemented first. r66.10 remains the installed earlier APK; its native finding is not closed by these host results.

Functional owners: work_session.dart plus the existing work_vertical_slice_test.dart and work_workspace_layout_safety_test.dart. Sixteen source lines add primary-phone, email and nonempty optional alternate-number format checks before each corresponding verification instruction in continueToProof. Rules/messages match Send code. No new screen, geometry, verification bypass, live OTP/backend call, dependency, Cursor or Android change.

Nine added tests distinguish malformed/blank input from changed valid-but-unconfirmed input, preserve required-field Cancel and independent confirmations, accept cleared optional alternate, and exercise 412/100% plus320/200% error/keyboard fit. Final assertions bound the entire rendered error above the simulated keyboard. This is local simulated-IME evidence, not physical TalkBack or200% OPPO qualification and not a new process-death test.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905.

| Run | Result | Log SHA-256 |
| --- | --- | --- |
| oppo-r6611-contact-focused-attempt1.log | 7 passed,2 harness failures,exit1. Both optional-number cases wrongly requested Cancel for an initially empty field. Validation/keyboard assertions had already passed. Preserved under REG-4510; corrected only that recovery action to native field clearing. | 8242461A6732CFB785AFCC904C4C5A7246828C4B63C4FD5BC8D2E803ED822F8B |
| oppo-r6611-contact-focused-attempt2.log | 9 passed,0 failed,exit0 | 81E0AEAF4BDE62E1E940D04D65FC92083E3BA398C99A587E28301CE1E14CC97A |
| oppo-r6611-contact-capture-attempt1.log | 6 passed,0 failed,exit0; six new captures inspected independently | F1F5803EFF7C2080B1B384A3B3160E00AAF9D126D0DF2C8352DEF4D47CB90E09 |
| oppo-r6611-contact-work-regressions-attempt1.log | Six connected suites:905 passed,81 existing skips,0 failed,exit0. No skip or historical assertion changed. | A285977D85679DBA6C3E1EEBF72A7650484FA37628A733A9A92BC6865551A500 |
| oppo-r6611-contact-focused-final.log | 9 passed,0 failed,exit0 including added full-error boundary assertions | 40F7B2A49280B7AFF92CFF86D672AA62AC4C34AADFE66A0A05D482BD264337D3 |
| oppo-r6611-contact-full-analysis.log | Full Flutter analysis: zero issues,exit0 | 9D482EA59788118BC7F0304FE25603846551A55981C01BB8A80D69C51286401A |

Commands used Flutter test --no-pub --concurrency=1 --reporter expanded. Focused runs: test/work_vertical_slice_test.dart and test/work_workspace_layout_safety_test.dart --plain-name 'r6611 contact'. Capture ran only the new contact-format cases with MOOL_CAPTURE_STORE_VIEW_V2=true, MOOL_STORE_VIEW_CAPTURE_DIR=oppo-r6611-contact-local-v1-20260909 and --update-goldens; historical images were not updated. Six-suite run: test/work_production_gateway_test.dart, test/work_vertical_slice_test.dart, test/work_workspace_layout_safety_test.dart, test/work_store_atomic_operations_test.dart, test/ui_v2/work/work_main_v2_test.dart and test/ui_v2/work/work_opportunity_home_c24g_test.dart. Full analysis: flutter analyze --no-pub.

Founder explicitly requested supervised agents. Two independent reasoning-only reviewers received source/contract excerpts; neither edited files, ran tests, touched a device or required a parallel mutation claim. Their recommendations were reviewed by the primary; contact error-boundary assertions were strengthened. Do not represent those reviews as extra executed tests.

Support child REG-20260909-4549 / R6610-SUPPORT-DRAFT-SCOPE-01 is registered but not implemented in this contact slice. Existing primary claims already include the required Chat source/tests. Its forthcoming correction must keep actual conversation IDs unchanged and scope all local composer content by application, including asynchronous attachment/send handling and account reset. No mutable global active-draft context or unsent-data overwrite is approved.

Only mechanical registry/binding updates support these already-authorized defects. The historical regression-memory document was restored to byte-equivalent Git content after the owner gate rejected the attempt's addition; no owner/root/gate expansion occurred. Failed cached-path and output reads changed no product file. A read of the analysis log before its first output correctly found it absent; the completed producer result and hash above, not that early read, qualify analysis.

New local captures are under oppo-r6611-contact-local-v1-20260909:
```text
801023915216F82D0B1A1FE7FCCF7FD3B4B7F15B9C3988E0F42295EF03E9454C  r6611-work-alternate-contact-format-320.png
9BCB949B29A856D10824B09C5963D22A70D423D47C3902DD4F5E218513FE17EF  r6611-work-alternate-contact-format-412.png
12973C009965C4171793C8CB1D95F9E1BD7F24BEB42BD7D93BE04E653039274C  r6611-work-contact-email-format-320.png
A29AA774E9A8F3EB5B75503B228A11D7E65DD8BE30038AE8DC51F674E13AC142  r6611-work-contact-email-format-412.png
407E6B5CFB0C6B6444D943574B090791E78840F603F7A035E7795D96DF098A91  r6611-work-primary-contact-format-320.png
199680BA9F51B7AE019F9061190B7B6AC4EB77473FE6A7BF57ECD93DE4F48592  r6611-work-primary-contact-format-412.png
```

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
