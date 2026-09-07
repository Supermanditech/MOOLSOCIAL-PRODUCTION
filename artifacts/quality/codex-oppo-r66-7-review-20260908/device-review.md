# r66.7 OPPO child replay

## Installed candidate

- Candidate: UAW-CODEX-OPPO-R66.7-REVIEW-20260908; source commit b2adfe02e26740a4364da6ddd9b4f288d1d9acc9.
- Package com.moolsocial.app.runtime; version 1.0.0-r66.7-runtime; code 2026090802; OPPO CPH2375 / 2b3e0f71, 720 x 1612, font scale 1.0.
- APK: 209721825 bytes; SHA-256 E13BBB3AFFF76DDA8168DA5CF25C03CBF98EDA8178E0DBCC2B9FE01D11823749. Installed base.apk independently returned this same checksum; lastUpdateTime 2026-09-08 04:15:20 IST.
- Streamed install -r succeeded without clearing app data or uninstalling. Install log SHA-256 C4AA470ACAFCF8576C15B0F0B5AE7E852D1EC5413372D0E6A9272E788E1306D3. Cold launch succeeded (8081 ms total / 8102 ms wait).
- This is an isolated, non-promotable UI-review debug candidate, not production/backend qualification.

## Native replay and result

Capture root: artifacts/device/codex-oppo-r66-7-review-20260908. All numbered captures have a PNG and XML. Screenshot 01 preserves the previous r66.6 state; 02-34 are r66.7. No prior capture was overwritten.

| Captures | Journey / observed result |
| --- | --- |
| 02-07 | Cold launch, Mool -> Work -> Workspace -> Grocery preview -> prerequisites. Reachable; no Buy implementation or fixture changed. |
| 08-17 | Retained contact text, phone/email/backup review-code verification, progression to business details. Review-only 123456 verification is not real OTP authority. The next unconfirmed channel is revealed without forcing text edits. |
| 18-21 | Documents -> compact source chooser -> Android files -> labelled QA image attachment. No personal identity document selected; no live upload claim. |
| 22-23 | Fit image -> button zoom 2x. Image remains centred: horizontal bounds 223..497 become 86..634 about x=360, rather than moving to the right edge. |
| 24-27 | Pan, then 3x and 4x button zoom. Same working focal area remains visible; another tap at 4x causes no further growth. Fixed controls remain visible. |
| 28-30 | Fit restores original 223..497 / 781..1394 preview bounds. Close returns to the same attached image; View reopens it at Fit. |
| 31-34 | Replace opens compact source controls; Cancel retains the original attachment. Reopen and Android Back close only the viewer and retain the same document step/file. |

AUDIT-R666-01: closed for the viewport-centred button-zoom correction after local regression and native OPPO 100% replay. No additional reproducible child defect was found in this corrected sequence. Direct PNG review includes zoom, pan, cap, Fit and replacement controls; XML and actual taps establish retention/navigation. This is not a claim that every screen is visually approved.

Capture 09 spans an IME transition; its settled layout subsequently reveals Confirm above the keyboard. Do not report a transient frame as a persistent keyboard defect. The first capture-20 guard stopped before writing because Android was still transitioning to the file picker; after checking its real foreground activity, the still-unused capture name was recorded. No application defect or overwritten evidence resulted.

## Qualification and explicit boundaries

- Focused zoom/image/error/retention cases: 6 passed. Two identical serialized 38-file cycles each: 1339 passed, 83 unchanged exclusions, 0 failed. Full Flutter analysis: zero issues. Exact commands, raw-output hashes, exclusions and source376 manifest are in local-validation.md and prebuild-validation.md.
- Normal, compact 140% and 200% checks are local widget/layout evidence only. Native font remains 100%; physical 200% and TalkBack are unqualified. No device security or display setting was changed.
- The earlier r66.6 65-step / 129-file reachable audit remains preserved. Its Pending, request-validation, review, Chat and alternative-workspace findings are not falsely relabelled as r66.7 full replays.
- Admin-approved dashboard and first-tap native journeys remain blocked by the Pending-only review gateway. No test-only approval selector, local approved flag or bypass was introduced. A QA provisioning decision or authoritative backend state is required.
- BE-01 authenticated case/verification recovery remains pending: the review gateway loses server-like case/verification state on cold start; retained text is not proof of persisted verification. This was observed again after the update, without clearing app data.
- BE-02 admin status, BE-03 secure document references/recovery, BE-04 unsupported-workspace service/receipt and BE-05 admin communications remain pending. No real message, payment or approval was generated.
- Actual PDF-content rendering remains open; existing File details / PDF preview unavailable copy is not a PDF viewer.
- Consumer-integrated collection and live payment/readiness/replay enforcement remain pending. Cursor source and Redmi were untouched.
- OPPO left at the Documents step with the clearly labelled QA image retained. Laptop left running because Cursor inactivity was not positively confirmed; no shutdown or Redmi action.

## Native evidence hash inventory

68 files. Canonical digest: SHA-256 01417679035B0F321FA5BC08920358727FE5BC2C32AD03FA755B2DC1E431DCBD.
Canonical bytes are UTF-8, name-sorted rows of filename TAB byte-count TAB uppercase SHA-256, LF between rows and one final LF. APK and install log are separately bound above.

```text
r667-native-01-before-update.png	122643	6EE9899356A4AE308CDF53FDAE3063E62F3E2AD43CB8A8646745199D3994EAB8
r667-native-01-before-update.xml	7545	BC7CBD903489975F690D529DD3C5140DD6FB4C204EB7A3C7E59A760033CFC2B1
r667-native-02-cold-launch.png	417810	8EF201ACA4ED7DE9F98AECEC48E66215A49B1EA772FBB4F79C121A94EFF09EF7
r667-native-02-cold-launch.xml	24491	6400967F59679BBB5287E435EA70E5B9E43E28CE317C88AF5C232E95134B957F
r667-native-03-mool-menu.png	363874	664362414C78D51BA53636D1116BDBD4C69247C76E000051643F78A801547B2F
r667-native-03-mool-menu.xml	28181	7D0123414D61A8640FAD4269398B6551969449E9FE0B52DB956088C1B09857A0
r667-native-04-work-entry.png	216155	8F83BE6A645627ADC38D3EAD437C0701113C8CA579CD1102FF7E1D315A19A897
r667-native-04-work-entry.xml	12056	130F16C31085DA72D07B833642C48E1992B632813D32BB064B4B4080A1BE96F7
r667-native-05-workspace-entry.png	179130	82E5E9F68A56FA275EE58654A361F3CFCCD80D469B33477653C24100CB283051
r667-native-05-workspace-entry.xml	10399	04465DFE282146F400DE671AD1CA55C443E2B424EC22A219289D74497FA5AC41
r667-native-06-grocery-preview.png	144788	E9D3095D2AFB4BD3332A08DBC8F9497B38AD09D24C0BD183380B74107363C6BC
r667-native-06-grocery-preview.xml	13249	C0F9C25443A900A054A1686799C4A2A67288AD28D8C27E6B97AAA7D2F5B01528
r667-native-07-prerequisites.png	166708	84EB21D1C05CF5FDB08C5FBEDBB53BDC34FF6ED49B0A48CEE031321A2297BE5D
r667-native-07-prerequisites.xml	10066	888A59AC7ED0C89AED7A74D83B6C3B345B4435634C8AE6CCB81A01FC211A8962
r667-native-08-contact.png	119101	357352E624B46F21AE6218FEDDC6A85B4C3A1463F1464FAD2050D5BD7FB63FA5
r667-native-08-contact.xml	12023	E42B10ECF64AFBF791FFF7AB620259981CFC7F7AC24CB51A607D0F4750D4D6C5
r667-native-09-review-phone-code.png	134786	90D7327C5586F2D13AE10AEA1523321414CAB7737E5958E3DB35E5765E5335FE
r667-native-09-review-phone-code.xml	10257	4AF8D8B117B43F322D857587CACC32C12643B4B70D25AD39E6339F38217202FB
r667-native-10-phone-code-filled.png	128515	EDB622BBD39BAACE842A2E44F9F25A638106EBD0B72B0D064121AE6A893AD148
r667-native-10-phone-code-filled.xml	13390	5D29FFCF598218AF7EF3DBE839EDEAEBC5FE48177BB370D888DBD0717A6EF19F
r667-native-11-email-reveal.png	127333	ACFE7C4A6BB213B86499CCFAA8524902015620BD1019A84F1945913CAB158A19
r667-native-11-email-reveal.xml	12700	1316C25ABB1441DE71FB701A98CBC5169F25269A28FCDA824E71730803606868
r667-native-12-review-email-code.png	137220	1216B50D8D495E13CA7D070F48DA4CD19851900F406E3EFF700052C95D72131B
r667-native-12-review-email-code.xml	9904	7ABD259F8C22F5CB94D3250BEFB0972FA25FCD42592724140330AFBE905F17FC
r667-native-13-email-code-filled.png	133499	B4F47E50039D48E75A9D4CB6A636F72C26CE15DAC7BA4871B8E4AB8E4F17C6E4
r667-native-13-email-code-filled.xml	13043	0530E2791A472454F8CC8BE7FC478FE6F27048F3ED0877EDC2F6D1415855CDE9
r667-native-14-backup-reveal.png	136406	1B7B977B1440B5D8A26081A94487922B3A2E0B071E4E014CC8A1139492CF83A6
r667-native-14-backup-reveal.xml	12720	DBF71E410ECFEB630361488E678A72F28CEFA0E0B35929C697902B6701DA8000
r667-native-15-review-backup-code.png	136330	4E5E5B53CAC1F31D665E6CA406135A4D2E5A404237B69EEC25BBBD81C2135750
r667-native-15-review-backup-code.xml	9230	94DF6ED0987060B86A118D73AA54BF1311BBB30273917FB948CDF2C750E1C02B
r667-native-16-backup-code-filled.png	123951	E4BAACD3C882FC5099FFDACD00E5C385FBCBA76865B9A35E670BEB9E9E0EB4A0
r667-native-16-backup-code-filled.xml	12670	C5EA78800969A9752B12733A1F3CFFB4B1005A16BEA3137960F283BC324C520A
r667-native-17-business-details.png	142698	76CEC51DD372E99779D9618432F7604CBE650934BF19782FD540294A0BFDC306
r667-native-17-business-details.xml	9854	98BC8343ADF04C71D4367EA34730736AF1A80D3CB7EA4560040B242DEB52CF9B
r667-native-18-documents.png	162881	7362D0FAB68B84B98DD92C5C7B79A468F2DC4C9738004A280C24C2392B0665A7
r667-native-18-documents.xml	11035	F95E99A2B3B0398305C0DA8C50D92433A92EAB490417886B3342606464B90BCA
r667-native-19-document-sources.png	144978	094A2CA60851BF997790D25AA2A8D2CAF68182856F1D9ABD5D6F3C67A434D2B7
r667-native-19-document-sources.xml	5888	F7C3CDD51276C12550760730EC229EFB0792AB11E1B4F4C94A5C494ACAA97024
r667-native-20-qa-picker.png	193252	B0C5F4D821DBDC1906E8C66055BA0AB2C885429598707F949422A0909C127423
r667-native-20-qa-picker.xml	51299	9E4DB1125B7B2DD16A944252F2D9085C13868EF7CC11F2B30B07563483AF4AE2
r667-native-21-image-attached.png	159393	EF7A3C2198937E179CCEFB438D0E77CCA9188D5C09137B2D7E53FD06D0497F76
r667-native-21-image-attached.xml	11730	CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5
r667-native-22-image-fit.png	144392	6D2BA6EDBA322252D0CAFBCF1FF8A1AFD3E2A971BF0F99EF7C226FDC344B2EED
r667-native-22-image-fit.xml	7189	33CD959E9D3126EADF87F857899E7070E6FE30806AD423B141A360DC221E1BA6
r667-native-23-centred-zoom2.png	172909	847D30D7BD77FED38FA0C5AB9A0BA3E8F3475C8AA14D00E951D8F2EDBF27A4C1
r667-native-23-centred-zoom2.xml	7188	61558D573ACA40029BE4C7156DF0F518DE35FC4F168B1D6707FF4765D02FF41B
r667-native-24-image-pan.png	170316	2317A571ECD1901EEE56A36D1480F9F5C210A1844E404361FBF2F59A00E01268
r667-native-24-image-pan.xml	7188	6E94BFF73F8F6BBE74816AC7357AD12B2C352AFB93397611A9E7E5E69544CC3D
r667-native-25-zoom-after-pan.png	177169	88EFE2740076D5940D01CE2E250FBFAEEE0906250CD9C76EC5951223EE6EF943
r667-native-25-zoom-after-pan.xml	7188	460D4E67154AE4040C8170FB035CE4C275FF43FD826B213F2DE4AC9635203F6D
r667-native-26-zoom4.png	163784	7E8812FC6FE15C01E06215E35F1A7A707C20A5B01848BC6E4B2ABB09422ED5A5
r667-native-26-zoom4.xml	7188	460D4E67154AE4040C8170FB035CE4C275FF43FD826B213F2DE4AC9635203F6D
r667-native-27-zoom-cap.png	164047	0013F876294617E69BD049323D88CD67E82B9F5D4658A0061461F5A84788CCE9
r667-native-27-zoom-cap.xml	7188	460D4E67154AE4040C8170FB035CE4C275FF43FD826B213F2DE4AC9635203F6D
r667-native-28-fit-restored.png	144124	A216CC09A4AD51E6DA178501511150DEE0DF1B322B2E1697A2751CE89514BF12
r667-native-28-fit-restored.xml	7189	33CD959E9D3126EADF87F857899E7070E6FE30806AD423B141A360DC221E1BA6
r667-native-29-close-retained.png	152563	DFDA2F53C6BA9C41D29CD9073A1BE2BBD4465A23145522A73151A82D659E96F5
r667-native-29-close-retained.xml	11730	CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5
r667-native-30-reopen.png	144157	A776D1C27CF116A0500FD82DA432C370BE23CB11F486E3C386DB9BD04EF3581F
r667-native-30-reopen.xml	7189	33CD959E9D3126EADF87F857899E7070E6FE30806AD423B141A360DC221E1BA6
r667-native-31-replace-options.png	140777	AF28E794BF1B2A99217B4D8A6E0D4E62973A9D120AC28057F389BF0985BE59CC
r667-native-31-replace-options.xml	5889	DFDC41C580A46723374D9C6A3D01951A8F80744562CDF7DFE6D031F7801F9448
r667-native-32-replace-cancel-retained.png	152701	3239CEAA823E531F6CD204F5C65BAF82CA5F89B53BC8634848988FCF957CFB98
r667-native-32-replace-cancel-retained.xml	11730	CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5
r667-native-33-back-check-open.png	144059	6831068B9D4E42BA8B39EA1BF20EE65166D5CDEA9209AF532FCED15E79B27C2E
r667-native-33-back-check-open.xml	7189	33CD959E9D3126EADF87F857899E7070E6FE30806AD423B141A360DC221E1BA6
r667-native-34-android-back-retained.png	152719	78E9546A642B8A488364C1450467D37EA40A524C79601C4FC5648A7E4F519202
r667-native-34-android-back-retained.xml	11730	CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5
```
