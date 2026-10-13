# r66.17 local qualification

## Authorized host-fixture correction — qualified locally

Founder authorized the minimum blocker correction for the scoped OPPO round. Only global_contextual_chat_shell_test.dart now injects a per-test, account/application-keyed in-memory ChatSupportDraftStore into the existing r6616 keyboard/retry cases. All existing assertions remain unchanged. No product, Android, storage timeout, policy or gate behavior changed. Historical failed output below is retained.

Enabled-review exact rerun:10 passed,0 failed,exit0. External r6617-review-isolation-fixture-v2.log SHA256 8B89805A2ADB4FE5156FB83F3583F627579296020C214829F71F23749BE00B90.

Connected default-mode global_contextual_chat_shell_test.dart plus chat_flow_test.dart, existing protected-reference exclusion, serialized expanded:117 passed,0 failed,exit0. External r6617-chat-fixture-connected-v2.log SHA256 A80F971A090ED9480E2C8BCDBFE16C7BB1907CCDD56516F4547913FA5710A6E9. Full flutter analyze --no-pub:zero issues,exit0; r6617-chat-fixture-analysis-v2.log SHA256 2AAA215CF16B5C9185DAB967F38DEAD4A8B2BA31098AD0440128F2FDBBE998CF.

Actual Flutter capture replay with both review defines and MOOL_CAPTURE_STORE_VIEW_V2=true:2 passed,exit0; r6617-chat-fixture-visual-v2.log SHA256 217BCD64B331B752A2F31471DFE3D243FA7BF809FA7348D7127CECBFF5379B2A. Four PNGs under external r6617-chat-fixture-visual-v2 inspected: normal error/retry fits;320x568 at200% with220px keyboard inset requires scrolling to expose Retry, which is asserted hit-testable at least48px and succeeds. This is not a claim that all content fits simultaneously or physical accessibility is qualified. Device replay remains pending.

The two earlier44-file cycles still apply to unchanged runtime source; this correction changes only test dependency setup, with connected and enabled-mode requalification above.391-input manifest refreshed only for the changed test. No APK or device closure yet.

## Build blocker: enabled-review host fixture

Final command: flutter test --no-pub test/work_production_gateway_test.dart test/global_contextual_chat_shell_test.dart --name 'r66.8 review state isolation|r6616' --dart-define=MOOLSOCIAL_DEVICE_REVIEW=true --dart-define=MOOLSOCIAL_UI_REVIEW_ONLY=true --reporter expanded --concurrency=1. Result8passed/2failed,exit1. Full external r6617-final-review-isolation-v1.log SHA25696D190C5887A0F9D14E350A53AEF28EDC9E17CED7B14701F29D7F21E3E371299.

Failed names: r6616 review failure control and keyboard recovery1.0 and2.0. Both report pending10second FakeAsync timers from SecureChatSupportDraftStore.read/write (chat_session.dart43/67); the existing test constructs ChatSession with only a review send gateway, leaving the newly enabled review secure-draft store dependent on native host calls. This is evidence of missing host storage isolation, not proof of a device defect or permission to remove timeouts. The six Work review-isolation cases and two Chat scope-isolation cases passed. No retry or source/test change made. Final analysis command did not run because the preceding command failed.

Both default-mode44-file cycles passed, but do not cover this enabled-review dependency. Build authorization stays disabled. A bounded existing-test storage fixture correction and rerun needs founder authority beyond candidate evidence bindings; preserve current source and assertions. No APK or device closure.

Both complete cycles now passed. Cycle2 remaining28:402passed,2existing skips,0failed,exit0; r6617-preapk-remaining28-cycle2.log SHA25638F77F8231A41C5BF9CDEE43DDAF32EFC8A0F87CC5C978849E95FFCEC33EFD12. Each complete44-file cycle totals1906passed/83skipped/0failed. Repeated and focused counts are not unique test totals. Final enabled-review isolation and analysis are running; no APK/device qualification yet. Earlier running/pending notes below remain historical.

Cycle2 connected16 completed1504passed,81existing skips,0failed,exit0. Complete r6617-preapk-connected16-cycle2.log SHA256 A24233A43840C1B7ADA2FB0FE36AE0EF0CADD584B0A831ED687D4B48C6211653. Final remaining28 partition running; build not activated.

Cycle1 remaining28 completed402passed,2existing skips,0failed,exit0. Complete r6617-preapk-remaining28-cycle1.log SHA2561A7B8F0B573CAD3DFE388946B75AE53FB85AB5BC782251C5A2C3EF58F96B229F. Combined cycle1 total1906passed/83skipped/0failed. Cycle2 has started; build remains disabled.

Cycle1 connected16 completed1504passed,81existing skips,0failed,exit0. Complete r6617-preapk-connected16-cycle1.log SHA256 DA2B8383F355B185D1D419F0B81F6C8AF9F05FCD822365D929856DDBF10E2D6A. Remaining28/cycle2 are still running; no full-cycle or APK qualification yet.

Pre-APK cycles running on unchanged e5799bd6 source/tests. Exact connected16/remaining28 lists reused from ../codex-oppo-r66-14-review-20260911/local-validation.md, each extracted from its named text block and verified for count and file existence. Each of two cycles runs both partitions with flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference. Existing exclusion is unchanged, not a new pass or an omitted known failure.

Logs are external under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6617-preapk-<partition>-cycle<1-or-2>.log. Do not claim results until terminal exit and full output are checked. Stop the batch on a failure; no product fix authorized in this round.

Prior consolidated local result1372pass/79skip/0fail and full clean analysis are in the sealed r66.16 ticket ledger. They do not substitute for these required full candidate cycles. Shared Files picker/draft tests remain covered by that source-identical prior six-suite run. Deferred Buy compatibility cases and backend/physical accessibility limitations stay explicit.
