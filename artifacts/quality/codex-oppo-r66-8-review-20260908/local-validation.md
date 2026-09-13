# r66.8 local validation

## Focused checkpoint — not APK qualification

External raw evidence root: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905`.

- Default focused run: 22 passed, 0 failed, exit 0. `r668-focused-default5-20260908.log`, SHA256 `87A077D08B3C7424875F0BC7A092A8D4FFCCE86214F2DBEAA5768183FB4899D9`.
- Review flags both enabled: 5 passed, 0 failed, exit 0. `r668-review-controls-both4-20260908.log`, SHA256 `0707EE9DE2F7C10888E5943456C2004A3E3E167971E2FBCC294738FF15A0DA5C`.
- Device flag only: 5 passed, 0 failed, exit 0. `r668-review-controls-device-only-20260908.log`, SHA256 `9CBEBF2EA8C375A95CB20A29AFCD5DB839D5B36A314DDCCBBE68F7BDCB7EA050`.
- UI flag only: 5 passed, 0 failed, exit 0. `r668-review-controls-ui-only-20260908.log`, SHA256 `E580A01167C4B5E0C0ECF4AB29115DA93C039DCC8B3ABD6634D56ED1B281B405`.

Common command: `flutter test --no-pub --concurrency=1 --reporter expanded`. Default files: `test/work_production_gateway_test.dart test/work_vertical_slice_test.dart test/work_workspace_layout_safety_test.dart test/platform_configuration_test.dart --plain-name r66.8`. Flag cases use the first two files and `--plain-name "r66.8 review"`, with exactly the named `--dart-define=MOOLSOCIAL_DEVICE_REVIEW=true` and/or `--dart-define=MOOLSOCIAL_UI_REVIEW_ONLY=true`.

PDF coverage: bounded local input/output, requested page identity, count/dimension validation, protected/invalid/timeout/missing renderer recovery, duplicate render and exact cancellation, 320x568 at 200% and 412x915 at 100%, paging/zoom reset, pinned Retry/Close/Replace, Back during loading and unchanged attachment on replacement cancellation. Host page PNGs are labelled mocked transport fixtures, not native parser qualification. A subsequently added malformed-envelope case and review capture helper require final replay.

Review cases use the actual Work review/dashboard components with injected memory storage to avoid unrelated native plugin setup in host widget tests. Global routing remains covered by existing default-mode suites; native storage/plugin behaviour requires device replay. No real approval is granted and no new test exclusions were added.

## Native compile checkpoint

The exact two new Kotlin owners compiled successfully (exit 0) using cached Kotlin compiler 2.3.20, Java target 17, Android 36 API and Flutter android-arm64 embedding jar. Compiler emitted no diagnostics. `r668-pdf-native-compile2-20260908.log` is intentionally zero bytes, SHA256 `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`; output `r668-pdf-native-classes1.jar`, 21085 bytes, SHA256 `6B3E0B4699F8E6405F7819D678F0BAF1B4A7520F6175064509CA7288CD70C704`.

Command entry: `java -cp <cached compiler dependency jars> org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect -jvm-target 17 -classpath <android.jar;flutter.jar;kotlin-stdlib;annotations> -d <external r668-pdf-native-classes1.jar> apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/WorkDocumentPreviewBridge.kt apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/WorkDocumentRenderService.kt`.

Initial Gradle compile attempt stopped on accepted machine metadata pointing at a retired checkout. No metadata or dependency owner was edited. The normal guarded APK wrapper's existing locked-resolution step and complete app compile remain mandatory. Standalone compile is not package/manifest/device acceptance.

## Latest platform and visual qualification

Final full analysis4: zero issues, 15.3 seconds, exit0; raw SHA256831F4FD7D38322D1B57D6F394C69969510C34A5F4E52147C33BBB1275207CA39. Corrected platform/runtime focused command: flutter test --no-pub --concurrency=1 --reporter expanded test/platform_configuration_test.dart test/release_runtime_configuration_test.dart. All18 passed, exit0; r668-platform-contract1-20260908.log SHA2565B3CCAE6D4DB7A73195821ADC0A4BB7D36402377D54DDF6B73951361B2BF3439.

Source snapshot380 owners, SHA256509823701677650355DC1BA466E360285FBFF181439B01C1B352D3680F4B47D9. The only correction since the preceding snapshot is the stale platform test contract. Runtime/authentication source and Buy owners are unchanged from HEAD.

First combined attempt completed1366passed/83 exclusions/6failures/exit1. Preserve r668-final-connected1-20260908.log SHA256601586813A45426761BB5D09F6C4741F8BE3EFD9C009397D0A9619FA5ADDAE9A. Five R58.8.6 protected-reference capture comparisons ran because this invocation omitted the exact predecessor command's --exclude-tags protected-reference. Restore the established exclusion without modifying any golden, skip or Buy owner. The sixth newly included platform assertion searched retired exception text; it now asserts the existing fail-closed bootstrap and executable validator results. No runtime behavior was changed. This failed run is not qualification.

Latest actual Flutter captures:10 review-state images and10 PDF-panel images at412x915/100percent and320x568/200percent. All10 review images directly inspected. All distinct PDF error layouts directly inspected; eight PDF images are byte-identical to directly inspected visual1 counterparts, including the repeated mocked first-page images. Normal error panels now size to content; 200percent controls remain pinned and reachable. Page PNG bodies are deliberately mocked QA transport fixtures, not proof of Android parser output or physical PDF legibility. Screenshot metrics use actual tester.view size and padding with no debug banner. No immutable historical image was overwritten.

Review visual2:2passed/exit0, raw SHA2564D8EB24442608353ACE914C8DD3A45FD31F5717133B1CB119B43913B21B33453. PDF visual2:8passed/exit0, raw SHA256E4A4AA1F8B0908060D8EBD3BDE6B2D33828C3E70F60BBAD4747269D6C7E83ABD.

Fresh external capture inventory (relative to external evidence root):

```text
r668-review-visual2-20260908/r668-review-approved-1.0.png 49568 CFF2F6BA372FDF61D1825173EC6240225B6BF90222A0B79537E954C3FA7D998E
r668-review-visual2-20260908/r668-review-approved-2.0.png 41161 9EBAE022F091323280529E82E52BAD1A42ADC4B35D1D5EC5D1E0868830FBB659
r668-review-visual2-20260908/r668-review-clarification-1.0.png 47108 53CA3DB998D877E311C40F12CE04D47DD90BC820E8ADC1CBF3774CDE435016A5
r668-review-visual2-20260908/r668-review-clarification-2.0.png 34009 A3E5A26575DE9441C3C9C9365F03874F9F4C4E712E739B0EDC9D09FB22E79887
r668-review-visual2-20260908/r668-review-pending-1.0.png 49821 E09904987DEAB08BE6BAC613D15672296650C3E2315F1913EDDAD928075D6811
r668-review-visual2-20260908/r668-review-pending-2.0.png 37982 EAAFD16F866B0C67398AAE7D1978A40D536342C7DB9060844E311F6BDEE3BBEC
r668-review-visual2-20260908/r668-review-rejected-1.0.png 48345 934F2218CD8780C02C50422A0B1554B3D6BCBEDEB6C1B9DFA7CB519D4D29C401
r668-review-visual2-20260908/r668-review-rejected-2.0.png 36479 8F1B7EF97B574A1A6DD9B7840CCD1EAA42EADD263FC90B167674C1CB24857168
r668-review-visual2-20260908/r668-review-selector-1.0.png 54564 83664633F3265D7611751497AF6678C6769F664DB05E7FE0B5154EC1A5D57FF5
r668-review-visual2-20260908/r668-review-selector-2.0.png 33003 E30D6277DEE5E49CDA6D4B449084458139DD629110C50EE0FB02D2766C814273
r668-pdf-visual2-20260908/r668-pdf-invalid_pdf-1.0.png 56305 16BF63ACCBEBAE097E0F20AA362F225D849A65DC4175610291E858854F2F1073
r668-pdf-visual2-20260908/r668-pdf-invalid_pdf-2.0.png 32107 797F4AE820F396AA612E9740631A0EAF8CE7EB8CED10D2D93158204C71A11348
r668-pdf-visual2-20260908/r668-pdf-page1-invalid_pdf-1.0.png 36367 BB25C0702DDED54D93E3DC2AD6A66D66D59C482698D970F1D1D7420FAC2F8D4C
r668-pdf-visual2-20260908/r668-pdf-page1-invalid_pdf-2.0.png 20085 53DBD1E6529D3063CE6A54EDF7AAE091F704C6367F8288D7976C9A577F547BC8
r668-pdf-visual2-20260908/r668-pdf-page1-pages-1.0.png 36367 BB25C0702DDED54D93E3DC2AD6A66D66D59C482698D970F1D1D7420FAC2F8D4C
r668-pdf-visual2-20260908/r668-pdf-page1-pages-2.0.png 20085 53DBD1E6529D3063CE6A54EDF7AAE091F704C6367F8288D7976C9A577F547BC8
r668-pdf-visual2-20260908/r668-pdf-page1-protected_pdf-1.0.png 36367 BB25C0702DDED54D93E3DC2AD6A66D66D59C482698D970F1D1D7420FAC2F8D4C
r668-pdf-visual2-20260908/r668-pdf-page1-protected_pdf-2.0.png 20085 53DBD1E6529D3063CE6A54EDF7AAE091F704C6367F8288D7976C9A577F547BC8
r668-pdf-visual2-20260908/r668-pdf-protected_pdf-1.0.png 55964 406F223EB144C0C42CCE626ABB1D4560AAAD196DD93F278F071023628D66C379
r668-pdf-visual2-20260908/r668-pdf-protected_pdf-2.0.png 30624 6EB5E72E9E0416AA985CD729F798F7B012F0C9C29F056F895A53A36B12F2A10C
```

## Remaining qualification

Two corrected39-file serialized cycles completed on unchanged source:1367 passed,83 reported skips,0 failures,exit0 EACH. The five historical protected-reference tag exclusions remain separate and unchanged. Cycle1:7m17s, r668-qualified-connected1-20260908.log SHA256F8D18E214FD5F6B8CED4D448C9EADC4AB8E18F8F851EDE3D9B76204C8C762431. Cycle2:7m01s, r668-qualified-connected2-20260908.log SHA2568F08F5CE73A6EB34188DB526061E19CD0240EAD48A032BC6CAC31DEA2A76A961. Both logs retain the exact39-file command, --exclude-tags protected-reference, source-manifest hash, full output and native exit0. All380 source hashes matched after each cycle. No new skip, source change, reference update or parallel device action occurred. This supersedes earlier pending combined notes; source seal, prebuild gates and native replay are separate. No r66.8 APK build or device action has occurred. Backend authority, native PDF parsing and physical accessibility remain separate.
