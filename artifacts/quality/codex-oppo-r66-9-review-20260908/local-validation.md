# r66.9 local validation

## Complete Flutter qualification

Full analysis: zero issues, exit0,70.5seconds. Log r669-final-analysis1-20260908.log,99bytes, SHA256874ECF4DF7B7C3926BC59FDD488D8B671E21798C8831AB3FBB7FD9EB1A1D84CB.

Two exact39-file serialized cycles each completed **1367 passed,83 reported existing skips,0 failed,exit0**. Cycle1 took7m42s; cycle2 took8m40s. Five existing protected-reference-tag exclusions remain separate; no new skip/exclusion/reference update. All381 source/test/dependency hashes verified unchanged before and after both runs.

| Complete raw log | Bytes | SHA-256 |
| --- | ---: | --- |
| r669-qualified-connected1-20260908.log | 439691 | F87194797B7A4E01ED92D2E9A6D06E141FAACD09641081C292B713C2533FBFCA |
| r669-qualified-connected2-20260908.log | 439691 | 78003DA5A2145E5C153A2707B81B76BEB505FED3C1EEF6302EC38F9880723117 |

Logs remain in the external evidence directory recorded above and include the exact command, full output, manifest SHA and native exit0. Analysis/test source is not changed while qualification runs.

Exact invocation from apps/mobile:

```text
flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference test/ui_v2/profile/global_help_support_v2_test.dart test/ui_v2/profile/global_privacy_preferences_v2_test.dart test/ui_v2/profile/global_security_v2_test.dart test/ui_v2/work/work_main_v2_test.dart test/ui_v2/work/work_opportunity_home_c24g_test.dart test/work_production_gateway_test.dart test/work_store_atomic_operations_test.dart test/work_vertical_slice_test.dart test/work_workspace_layout_safety_test.dart test/global_contextual_chat_shell_test.dart test/chat_flow_test.dart test/chat_settings_hub_test.dart test/chat_production_gateway_test.dart test/ui_v2/universal/mool_domain_action_catalogue_c25b_test.dart test/ui_v2/universal/mool_six_domain_route_projection_c25e_test.dart test/ui_v2/universal/uaw_r08_personal_book_exposure_test.dart test/ui_v2/universal/uaw_r12_personal_legacy_route_containment_test.dart test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart test/core/design/mool_motion_primitives_test.dart test/universal_intent_completion_test.dart test/android_review_share_contract_test.dart test/ui_v2/buy/buy_v2_router_test.dart test/ui_v2/buy/buy_v2_screen_test.dart test/ui_v2/buy/buy_v2_session_test.dart test/ui_v2/buy/buy_v2_address_sheet_motion_test.dart test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart test/ui_v2/buy/buy_v2_wholesale_checkout_pack_count_test.dart test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_lines_test.dart test/ui_v2/buy/buy_v2_wholesale_checkout_receiving_location_test.dart test/release_runtime_configuration_test.dart test/global_customer_copy_professionalization_test.dart test/ui_v2/universal/mool_native_back_control_test.dart test/ui_v2/social/uaw_personal_mvp_social_youtube_account_state_journey_c30j_test.dart test/ui_v2/profile/global_profile_entry_contract_test.dart test/ui_v2/profile/global_personal_profile_v2_test.dart test/platform_configuration_test.dart
```

Exact39 owners:

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
- test/platform_configuration_test.dart

Visual boundary: all pre-existing Flutter layout/motion owners are byte-identical to r66.8. Its20 final normal/200% captures remain applicable to unchanged controls/geometry, not native PDF page content. The native child changes pipe transport only. Recheck actual page rendering/paging/recovery on the unique successor APK; no host fixture closes this requirement.

Native attempt1 compiled, then stalled after14 passing cases on non-progress header reading. The exact test process was stopped and its log retained (SHA2568673EBFA55B96C2CFA12246EEBDFB1B663F0135A484C8492CD7924F6004CBA5D). Header decoding was corrected to four checked single-byte reads; the complete23-case executable test is unchanged.

Attempt2: actual native Kotlin compilation passed and Java test completed23 passed,0 failed,0 skipped. Its surrounding report command returned1 because a zero-output compiler piped to Tee-Object produced no compile-log file for the later Get-Item. Do not fabricate the missing log or call the report command fully passed. A preceding PowerShell quoting error executed nothing; corrected before attempt2. Rerun with unique attempt3 artifacts and direct compiler redirection, retaining the60second native-test limit. Flutter connected cycles/analysis and native OPPO success remain pending.

## Qualified native transport attempt3

Both actual Android Kotlin owners and the standalone regression owner compiled with cached Kotlin2.3.20, Java target17, Android36 and the Flutter Android embedding. Exit0. Complete executable native transport suite:23 passed,0 failed,0 skipped; Java and wrapper exit0. This proves byte framing and bounds, not Binder/PdfRenderer/device success.

- Compiled jar: r669-pdf-native-classes3.jar,33569bytes, SHA25617813A456591F31C1ADB7787DDDEA36C5109E6CA804C7180F91FD717D7C3182A.
- Compiler log: r669-pdf-native-compile3-20260908.log,0bytes, SHA256E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855.
- Test log: r669-pdf-native-regression3-20260908.log,1275bytes, SHA256E0AE40673E7D238D79EE9727CCBF77BC7EBC63978ACA7A6A8F043F20250B4339; stderr empty.
- All artifacts retained under C:\GUARANTEED OUTCOME\MOOLSOCIAL-POST-UI-AUDIT-20260905. Attempt1/2 files are not overwritten.
- Source manifest381 SHA256831D5C40921C2F523622BF240DDE1E3C2D86C51A11697C153384DF30B318DFCC; only two native production owners differ from r66.8, plus the new native test. All pre-existing Flutter product/test/locked dependency blobs are unchanged.

### Reproduction command

The command below intentionally refuses existing outputs; use a new attempt suffix for another run. It adds no project dependency or reusable test framework.

```powershell
$ErrorActionPreference='Stop'
$taskCache='C:\Users\jisal\.gradle\caches\modules-2\files-2.1'
function Exact-CachedJar([string]$relative){
 $taskMatches=@(Get-ChildItem -LiteralPath (Join-Path $taskCache $relative) -File -Filter '*.jar' -Recurse)
 if($taskMatches.Count -ne 1){throw "Expected one cached jar: $relative"}
 return $taskMatches[0].FullName
}
$taskCompiler=Exact-CachedJar 'org.jetbrains.kotlin\kotlin-compiler-embeddable\2.3.20'
$taskStdlib=Exact-CachedJar 'org.jetbrains.kotlin\kotlin-stdlib\2.3.20'
$taskCompilerCp=@($taskCompiler,$taskStdlib,(Exact-CachedJar 'org.jetbrains.kotlin\kotlin-script-runtime\2.3.20'),(Exact-CachedJar 'org.jetbrains.kotlin\kotlin-reflect\1.6.10'),(Exact-CachedJar 'org.jetbrains.kotlin\kotlin-daemon-embeddable\2.3.20'),(Exact-CachedJar 'org.jetbrains.kotlinx\kotlinx-coroutines-core-jvm\1.8.0'),(Exact-CachedJar 'org.jetbrains\annotations\13.0')) -join ';'
$taskApiCp=@('C:\Users\jisal\AppData\Local\Android\Sdk\platforms\android-36\android.jar','C:\Users\jisal\develop\flutter\bin\cache\artifacts\engine\android-arm64\flutter.jar',$taskStdlib,(Exact-CachedJar 'org.jetbrains\annotations\13.0')) -join ';'
$taskJar='C:\GUARANTEED OUTCOME\MOOLSOCIAL-POST-UI-AUDIT-20260905\r669-pdf-native-classes3.jar'
$taskCompileLog='C:\GUARANTEED OUTCOME\MOOLSOCIAL-POST-UI-AUDIT-20260905\r669-pdf-native-compile3-20260908.log'
$taskTestLog='C:\GUARANTEED OUTCOME\MOOLSOCIAL-POST-UI-AUDIT-20260905\r669-pdf-native-regression3-20260908.log'
foreach($taskFile in @($taskJar,$taskCompileLog,$taskTestLog)){if(Test-Path -LiteralPath $taskFile){throw "Existing evidence: $taskFile"}}
$taskSources=@('apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/WorkDocumentPreviewBridge.kt','apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/WorkDocumentRenderService.kt','apps/mobile/android/app/src/test/kotlin/com/moolsocial/app/WorkDocumentFrameRegression.kt')
$taskJava='C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
& $taskJava -cp $taskCompilerCp org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect -jvm-target 17 -classpath $taskApiCp -d $taskJar @taskSources *> $taskCompileLog
if($LASTEXITCODE -ne 0){throw 'Native compile failed; do not run test or overwrite evidence'}
$taskTestError=$taskTestLog+'.stderr.log'
if(Test-Path -LiteralPath $taskTestError){throw 'Existing stderr evidence'}
$taskTestProc=Start-Process -FilePath $taskJava -ArgumentList @('-cp',('"'+$taskJar+';'+$taskStdlib+'"'),'com.moolsocial.app.WorkDocumentFrameRegression') -WindowStyle Hidden -PassThru -RedirectStandardOutput $taskTestLog -RedirectStandardError $taskTestError
if(-not $taskTestProc.WaitForExit(60000)){ $taskTestProc.Kill(); throw 'Native transport test exceeded60seconds; exact process stopped and evidence retained' }
$taskTestProc.Refresh()
Get-Content -LiteralPath $taskTestLog
Get-Content -LiteralPath $taskTestError
if($taskTestProc.ExitCode -ne 0){throw 'Native transport regression failed'}
foreach($taskFile in @($taskJar,$taskCompileLog,$taskTestLog)){Get-Item -LiteralPath $taskFile|Select-Object Name,Length; (Get-FileHash -LiteralPath $taskFile).Hash}

```
