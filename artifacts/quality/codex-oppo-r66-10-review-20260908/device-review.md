# r66.10 OPPO review

## Native continuation checkpoint — 9 September 2026

This section supersedes the earlier Work-entry-only checkpoint. The same installed r66.10 APK was used throughout; no app rebuild, reinstall, data clearance, production mutation, Cursor/Redmi operation or integration occurred. Native serial: 2b3e0f71; font scale 1.0. Current foreground is the approved test Workspace dashboard, capture 054.

### Scope and truthful results

| Captures | Native action and observed result |
| --- | --- |
| 004–008 | Workspace entry, Grocery preview, prerequisite documents, bank/GST note and contact entry. The obsolete linked-business hero is absent. These are a single Grocery journey, not proof of every business type. |
| 009–012 | Retained contact fields are present. Name focus opens the keyboard and compact Contact details header. Android Back dismisses the keyboard without leaving the form. Continue blocks an unconfirmed phone with inline wording. |
| 013–018 | Local review OTP simulator only: wrong six-digit code rejected inline; correct fixture code succeeds on retry for phone and email. The numeric keyboard remains usable. No SMS/email was sent, intercepted or read. This does not qualify real OTP delivery, autofill or production authentication. |
| 019–022 | Continue reaches Details. Android Back returns to Contact with confirmation retained within this session; forward restores the same business fields. Continue reaches Documents. |
| 023–028 | Native PDF/image chooser returns a clearly marked two-page QA PDF to the correct identity slot. View displays the PDF inside the app; Next shows page 2 of 2; the visible Close action returns to the same attached-document row. No actual identity/bank document was opened or sent. |
| 029–033 | Review shows business/contact sections, inline edit controls, attached filename/type/size and declaration. Unchecked declaration blocks submission. Checked declaration submits only to the local review gateway and lands on Application received; no automatic approval/dashboard access. |
| 034–043 | Explicitly labelled review-only control selects Clarification requested. Update details opens the correct application with its reason. Appending a temporary Draft suffix, then Back, leaves the submitted name unchanged and shows Changes not submitted. Reopening retains the unsent edit. Removing only that suffix restores the original name and removes the unsent-change warning. |
| 044–048 | Test-only Rejected shows a reason and support action, not approval/setup completion. Support opens the exact application identity and business name in an unsent draft. Android Back restores that rejected application. No message was sent. |
| 049–051 | Test-only Approved goes directly to its dashboard without a separate approved screen. A newly approved store correctly remains off/private with catalogue/fulfilment setup outstanding. There is one Store status control; opening/dismissing it changes neither availability nor visibility. |
| 052–054 | The approved Workspace appears in its chooser. Request another Workspace opens the selector without the obsolete linked-business card. Android Back returns to the already approved dashboard, preserving access. A second submitted same-type application has not yet been replayed here. |

The review-only boundary was verified before local code/submission actions: main.dart selects _runUiReviewOnlyApp before Firebase initialization; that app uses the default WorkSession with ReviewWorkGateway. Its sendContactOtp has no external transport; verifyContactOtp uses the existing local fixture. The APK is explicitly non-promotable. Review controls visibly state that no real application, payment or approval is changed. Fixture approval is not evidence of live backend authorization.

### Remaining checks — do not close all children

No new product defect was confirmed by this bounded pass. It does not establish that every implemented screen or journey is defect-free. Continue independent multi-application/same-business-type submissions and switching, relaunch/account-scope recovery, native picker cancellation/replacement/error and other document providers, targeted 200% error replay, and Dashboard's separate first-tap destinations. Real backend/admin/OTP/document storage/collection/payment contracts remain pending as already recorded. The separate historical Journey01 failures remain unresolved; this device pass does not waive them.

Native screenshot 026 shows the PDF footer fully visible above Android navigation and its Close action worked at the rendered location. Android hierarchy bounds for some bottom actions end at y=1442 even though pixels extend lower. Keep this as an accessibility observation for further investigation, not a proven clipping defect or a TalkBack pass. Physical 200%/TalkBack remains unqualified.

A read-only source-discovery command rejected an invalid wildcard path. It changed no files and provided no qualification evidence. The actual source paths and review gateway were then read successfully. No gate or owner expansion was made.

### Immutable native capture inventory

Directory: artifacts/device/codex-oppo-r66-10-review-20260908/.
54 PNG/XML pairs (108 files), names 001–054. Individual SHA-256 rows below are sorted by filename. Canonical inventory hash is SHA-256 of UTF-8 (no BOM), rows joined by LF with a final LF:
1CE07DFD799E66D551FAAEFF36BE36A9884916165885E79F82D7044DF7CC105D

```text
8BD6F455FC38D0F9EC8F44F3C1791E835DB729EFAAF418701F868BD78D3FDF0F  r6610-native-001-retained-launch.png
FCD7A2DA85FAC66A9226433D53B7C51A6FC5163726990982381AC1F12A9872D5  r6610-native-001-retained-launch.xml
765520406EB54F0522990182D5E2E0D83F8B98F73B6DC49C74794D5D275A5D24  r6610-native-002-mool-menu.png
5BF00520CBC1B807C959D2C38891DC1FA0D4020639A3B326EE168D0ED4E89823  r6610-native-002-mool-menu.xml
65C76EF14F28DB98A5745DED5B8D95D20A0C0BE087D22F4A021C48B9B4AF53AD  r6610-native-003-work-entry.png
45185CFCF5968D6A8FB10FF7A74C0EF77B44EFFCAB4999D56DFB010B3C3A628C  r6610-native-003-work-entry.xml
121A78ED1C028E549C84277196CEF0F35039C5CA0FB675968D1861FEC38C7545  r6610-native-004-workspace-entry.png
E39457EEE266701D62275049CBB3726CE6242525CA28211ECBA0C2F24C272753  r6610-native-004-workspace-entry.xml
474A1565670BE894DB5D5703C63845D00D654A1C14A2E97B66D64A1CA0D161DF  r6610-native-005-grocery-preview.png
A5EC466AFFF46810232160D996741D9B1ED0F6C9AE17882C829D205B09C8077B  r6610-native-005-grocery-preview.xml
002B6C0D7A30F39982CF83359C806922A1E3ECBFBA6DF9A953FFD6768AEAAC5D  r6610-native-006-documents-ready.png
FAF309D9DDDFB4BCCD2F5D37530A262093051B8DA99166714B114D29AD68C4B7  r6610-native-006-documents-ready.xml
9AD7BE12680CDA8C0ACE2C9B46E030F4658373C89E20FB619B245920EEB44377  r6610-native-007-documents-bank-gst.png
F0A67BA61B6EFA8188DF262CF05ED4249F6773A23F5EBDFA87B61301D4B4AD80  r6610-native-007-documents-bank-gst.xml
E8D1080D71E8C6ADAFDBC4423B8C0B3D19F9E7F19D69C6EF60D697EFAA717974  r6610-native-008-contact-entry.png
49A4881AA297740BD848FA89CED0F832FB55209C64BFD21E03958391F2518AAA  r6610-native-008-contact-entry.xml
039D4F7E0E2BD701886B759A12978E0F74E30B83D4423754BAAE837DD4BBD8F3  r6610-native-009-contact-resume.png
743112C07271C530F2CF52F1B88187F336D4C7A5B54A1F78CB6B15D0A427D0CF  r6610-native-009-contact-resume.xml
C41AA949953F821E2C7A94066F4D2DD99BDA2CFCBAD37CA4AC3A235DBE28F969  r6610-native-010-contact-keyboard.png
E786C976953E1B1C5EF76EC9A4B667573565B6A3A1F23B921DEA858A71366F74  r6610-native-010-contact-keyboard.xml
44349B80CE8F1846FB4191BA2CE815481941778CB43D98191522DAE64C7FDE98  r6610-native-011-contact-keyboard-back.png
14B7230D4669DA33B31880DBE64319DE154BCF9025FD1E0EC626C7E646FCF2B2  r6610-native-011-contact-keyboard-back.xml
8841FDFE3A7027E0584AC2A7EA1362C6ABBEA000FEC0BD3B5D90939475271553  r6610-native-012-unconfirmed-contact-block.png
DF08D8CC24C9ACD5055E6562EF360471F1086383AC94D0C2E6C06B0D8275F00E  r6610-native-012-unconfirmed-contact-block.xml
4E0D886C20664B8DCD6C9294A4C94CD7E2589722F42DB2159816885E19C9ABF5  r6610-native-013-local-phone-code.png
8C9D0EE1D3FDA059AA58E9C709BA1E461D3334BC71E20EB47069D09B2EDFEE95  r6610-native-013-local-phone-code.xml
34CFD857542723C5FB881798AD6873287181BBDA29B5288CFC787AF3CF9F0605  r6610-native-014-local-code-rejected.png
A13FDDC31F970E99B90070C95C39E0ADD6D1DEF56E937534F7D815599D054FC5  r6610-native-014-local-code-rejected.xml
27F7D55B200FBDA3E5A2594D0D03BEFB704A2AE5652988C4BAF6E05BFD88E80A  r6610-native-015-local-code-retry.png
383F999A2EF49B1EA6E483032302C48A680C26C68BE8B5269B19362E1C52B258  r6610-native-015-local-code-retry.xml
C4DE0531716270ED3068153A0A68088292C38183542088E49DD5F1F1F6B66A14  r6610-native-016-local-phone-confirmed.png
647ACCAC9429B15BAA56747E5DE72E218141353775BFBA8DA2BAF7C4A6327CB5  r6610-native-016-local-phone-confirmed.xml
7437A916A0B9A612C6E9472BED375F5A1D224D0EA178FB40914E3A64DDD45B15  r6610-native-017-local-email-code.png
F2EE9A1FE493D9FDBE8201981831C0A32840C775537529EE39DA3812F8DC3AD7  r6610-native-017-local-email-code.xml
FB389423264E4B14709FD13E8FC10579E0599D6C303AE8EBDB9316DAB7273E8D  r6610-native-018-local-contacts-confirmed.png
E9205945B13A1E52DFE48C2FB862394234C38BB4E681CD08335F7282B8C4D63D  r6610-native-018-local-contacts-confirmed.xml
4A6169EFC9255A4FB369D4B950B0A1378E13030A19606E697BE5D27AD73A5A18  r6610-native-019-details-entry.png
7DE3F485EE62918749BE17CE572DBD53A49FABE2FD3D5273A978854A70FD13D2  r6610-native-019-details-entry.xml
26F5E390E5B01B08D7BC2D3E2A13C64B4B4C4B1B18D1E385D5F945098179FEA9  r6610-native-020-details-back-contacts.png
E9205945B13A1E52DFE48C2FB862394234C38BB4E681CD08335F7282B8C4D63D  r6610-native-020-details-back-contacts.xml
ECBFE57BE422ACFCDDCE85CF1D72D5361C2D9A806F4292DAAA17030A827F64B7  r6610-native-021-details-restored.png
7DE3F485EE62918749BE17CE572DBD53A49FABE2FD3D5273A978854A70FD13D2  r6610-native-021-details-restored.xml
8F8137DF66E4F718923566A9D0F275816783329A2EF7C92A5343CAFE09CF093D  r6610-native-022-documents-entry.png
DFD86AE6A8A6E50700D70A01F063C787A3178E5F917F310B55976ADF37120F35  r6610-native-022-documents-entry.xml
F0386A9057E6E3D4B192E4AE0AAF8EF068C72062956F341D8E568FE7184340D6  r6610-native-023-document-sources.png
8F4730612C03412610D7A0D3095B40DD99C730ECFA6B4CA7067A5D6D7FD1D0CF  r6610-native-023-document-sources.xml
C8FF5ADB24C2E1F2F867DC0C4200DE276B48B1A8DE8D8C195D62959C0E8C6B9F  r6610-native-024-native-file-picker.png
98611B0C24415298E6C8EA766D68293B8B1F9E431755AE7282FEB72D641A3371  r6610-native-024-native-file-picker.xml
DE931118293E092A31DCF4D5F601328BA8002C98142B9CB3C1557014022F19CE  r6610-native-025-test-pdf-added.png
46D01BE8C2DCA1584423CAEE55CD9F5593CBCA0A00A6A306BD2BECD47D609668  r6610-native-025-test-pdf-added.xml
20C523BDEDD7E603CAF0C646FED90086A7152D584A8916FDF80C60F7376683AC  r6610-native-026-pdf-inline-preview.png
40D0103EC17973E988C3C6899D09C82E6101CF88C1DD34F65C73964C1F326038  r6610-native-026-pdf-inline-preview.xml
D1ADF0B7AEBAF5933C11152B1655DB68280C3693D5DD49E0299C49B738011D49  r6610-native-027-pdf-page-two.png
AEEBDA55ED8D90067971A3FBAB83884CAFF392C382B77543D2AF94209587E64F  r6610-native-027-pdf-page-two.xml
4D08167CFC0BEA2DF71E43CEF6FF54F19734C0FCF76E2C0DE3C9CD83D9B475CF  r6610-native-028-pdf-close-return.png
46D01BE8C2DCA1584423CAEE55CD9F5593CBCA0A00A6A306BD2BECD47D609668  r6610-native-028-pdf-close-return.xml
B3164A01C049083388B10E53FF3AF2B465CC3458DBB79306B3807A76B4205928  r6610-native-029-review-summary.png
6288A6726DAC867097FC7AC7EB645FF399E4DAD94AF0FB784EF6AAEAAA4D10BB  r6610-native-029-review-summary.xml
E4ED3863AE776C3FB6E6BD9AD763BD1CC3088B93B100B0BCF1C92566E07273FB  r6610-native-030-review-documents-declaration.png
58C1D89BB2018A0BA0ECF0900F7B590DEDCD14F9926E40CC379B94209D1862C3  r6610-native-030-review-documents-declaration.xml
3E205D5C0B0A8DA2D7811D168FB14EB3D435F518965357A8ECDD54B978DD828A  r6610-native-031-submit-declaration-block.png
09646274D7B1D7588A824BDE9C0213D9344EB803364F9746F0FADC1BD02ADEE3  r6610-native-031-submit-declaration-block.xml
A7569CCF62B8CAFA1EF23EAAA931D085E646CD3935F13FE9E1827175CA958543  r6610-native-032-test-declaration-checked.png
76AEE87C851C5027A494A15BBDD60F55991219350A95E4DAD533A7336421802A  r6610-native-032-test-declaration-checked.xml
B43E7FE31C0F400B7C98CEB66141738A57A40A2203D17858B30EAD5FC635D45C  r6610-native-033-local-application-received.png
7B52668CDAE9F0E7677672642E30AE2067D783AD624F4D1FB9659A40AC61D1EB  r6610-native-033-local-application-received.xml
C9B73D6885572E6391439760CAC5044CA5A71CAF03FB2B743DEFF8F1484476B7  r6610-native-034-review-only-case-control.png
37032F10F90AB3D6FD7A7138B66934EF422E615ED19B78E770BA457D4C20261C  r6610-native-034-review-only-case-control.xml
C669A70E53F537C2DFEDA7811398D04B25C42B813E4B9645558153FAA1C54D31  r6610-native-035-clarification-state.png
88C95751A28519A832ACDE4CCD6606D9754CB732A33E4808A29E3156E8C1C28D  r6610-native-035-clarification-state.xml
82F0D55EB6FB466616757DEE3E45B336B75620907CC63AEE34EBFA8CB7F27ADA  r6610-native-036-clarification-details.png
F065C6DE1606AA9BF7CA16D9CDBAE7650321D34E400EAB83FDA125BBBF4E8D3F  r6610-native-036-clarification-details.xml
6C857D49DF476C83DE7895BB5F3CA599C507DBDFBDBA97DC83BF3963DEA08C18  r6610-native-037-clarification-unsent-edit.png
74BDB5466BFAA34C52B0449E80028136276BBC6CBEF06316EA77BA9355076489  r6610-native-037-clarification-unsent-edit.xml
B166AEC8C0C448B08C24D02B929EC7A76D92435C7D5C1234FEA2F80F98CD3E48  r6610-native-038-clarification-keyboard-back.png
0D3310D217A80DA006B42140510C327309EAD84A499B4E4FD4C47F7F153E55BC  r6610-native-038-clarification-keyboard-back.xml
92C4263C711070C43E72BBEC3E75DE6A9A2ADA721A9EABA444FC1D564BEC6040  r6610-native-039-submitted-snapshot-unchanged.png
CCF46C6F5B871788E740AF99669C02AC67E533EBFB562046A2C840D810C07C52  r6610-native-039-submitted-snapshot-unchanged.xml
8F0CE59521675E1370D5E811C832157AA668F9F383EE685C7FB7FD662454C00E  r6610-native-040-clarification-draft-retained.png
59F7536171DD4A7AE5740DB62EDB7BE7778215E387841E9A59741DEA87566E0D  r6610-native-040-clarification-draft-retained.xml
86EBF27DC3551678291AF996FF8074CDAFB9BC2A23E8F1D46F3127ABC917C77D  r6610-native-041-test-name-restored.png
202FBD4A6E0CD20E9AF77DFF3B752B47285C2FC2D77DE14E09B525733BEB7DC6  r6610-native-041-test-name-restored.xml
A387E426FD5AAFDCE5BCB5E0486D704D82CD033CAE967E21FE9C955E00DDDBB6  r6610-native-042-clarification-restored-status.png
868BD2021036ABD63C83B9EA52B6D47D2D8F3831E1A10AE64ACE2B7DE6F93A9B  r6610-native-042-clarification-restored-status.xml
8D1BA213A18E4CB2BBA7766A0C0EBA821198A054CB82DB911BD73693B475749E  r6610-native-043-clarification-footer.png
8C705DB789D040DED92D71BFEFD310269B4A017650014764C12D20BED0B96DA2  r6610-native-043-clarification-footer.xml
3A575D6301D3986113DCC6C5B4EF902D70F54823C45C3C21BA390CEFF176FCF8  r6610-native-044-test-rejection-choice.png
BA390DDED0610F870A21FB58DCAF859689818852CC019097AF722E8E3F7578A9  r6610-native-044-test-rejection-choice.xml
22702F63EBB6255E3F92B014D4ABBA2475EFBE109C2712B837221EC2474BEFEE  r6610-native-045-rejected-state.png
CF46A8CD50094196265A9715BD3993B87467DCEC9758C84ABE7B34E80F2BA900  r6610-native-045-rejected-state.xml
9618D01EAFBC62CF592C9151A8D45F48F3252AB4A60523BAE7E50389767F7940  r6610-native-046-rejection-support-context.png
ABA9E23BA6D4A1BD03A26CCBE9E371269DBF92F68D371267919679FB0B2578B1  r6610-native-046-rejection-support-context.xml
755AAEC892E34910E6F85C4F6E8966B3B424B477ACD1D63E5D6EFD328170CFDA  r6610-native-047-support-exact-return.png
CF46A8CD50094196265A9715BD3993B87467DCEC9758C84ABE7B34E80F2BA900  r6610-native-047-support-exact-return.xml
5E09EDCE252C447D97BEED8C1461FA4CC1232C9414FDBC8523F492CF427232DA  r6610-native-048-test-approval-choice.png
BA390DDED0610F870A21FB58DCAF859689818852CC019097AF722E8E3F7578A9  r6610-native-048-test-approval-choice.xml
D96EC2C070512092EDA1EE79D520E345C88D0D89A9654376D5D17AACE0606593  r6610-native-049-approved-dashboard.png
2FB5B44E09BE725B9EB2ABB92DB53D34AF383BC1047C9D9DD6E5AD5493362049  r6610-native-049-approved-dashboard.xml
78F54CA60B58B16621911E1A5ABD3E32F99ECF0B09486123DA7CD0EA6BB7C739  r6610-native-050-store-status-popover.png
54ADE9420B19AA8E3F89C1872F3F8A8ED6244FDE06A141193AB0251561EB8FF7  r6610-native-050-store-status-popover.xml
B1ABC6D0564E643BC13F99724BC4A08053BE145EF95336DD354B4F30CB2AF5DB  r6610-native-051-status-dismissed-unchanged.png
F55D50C5507F06D0EFC9BBA7463C27191B9392F87FC14067B7020494EC549A0C  r6610-native-051-status-dismissed-unchanged.xml
965D679C898D4CA1618F827549F02C385E51C94A9A63D683AECF9AEE5E54528E  r6610-native-052-approved-workspace-chooser.png
8271705974EDFCC7E8284C047B24992AFDBF83CB358C30BE780EB2114F9BD068  r6610-native-052-approved-workspace-chooser.xml
ACCDF0BBE1CDE27553550F27D46CD96789D2BB075E0C54548B7A54DDB85D86E7  r6610-native-053-request-new-workspace.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-053-request-new-workspace.xml
E0B7DCE47A6824F9DDC3813B5B231E1A4B2FFA2130058AEBC3C2958E75356909  r6610-native-054-new-request-back.png
F55D50C5507F06D0EFC9BBA7463C27191B9392F87FC14067B7020494EC549A0C  r6610-native-054-new-request-back.xml
```

## Installed and checksum verified

r66.10 is installed on OPPO 2b3e0f71, package com.moolsocial.app.runtime, versionCode 2026090805, versionName 1.0.0-r66.10-runtime. The installed base.apk SHA-256 equals the saved review APK: 8973A2655DD26DD7F9DC7B373B264DDD84638164EC2EEF58812037841773CAE7. Independent checksum/launch transcript SHA-256 94B0FD4F444273F2B24D0CC20C681E75DBC374AB75DDB10D6B0F277194B0C95D at C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-oppo-checksum-launch-20260909.log. Cold launch returned Status ok. No reinstall or data clearance was needed.

Captures 001 retained launch, 002 Mool menu and 003 Work entry are saved in the r66.10 device directory. These establish launch/navigation only, not complete Workspace or Dashboard child closure. OPPO remains at Work entry for continuation.

## Future installed-APK path prevention

Verification complete: 3 valid-path cases and 12 rejection cases passed, followed by a live read-only OPPO path/checksum check using this retained helper. All passed, exit 0. Exact command/helper/results: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-installed-path-prevention-20260909.log; SHA-256 EE23818CA5D71ABEDD1BB1945C87ADA091CD3ADC6E6814AFC2AECA4DB98B7D45. The actual installed checksum still equals the qualified APK. No reinstallation, app edit or rebuild.

Founder requires this correction in future APK checks. Always obtain the path from adb -s <exact serial> shell pm path <exact candidate package>, require native exit 0, and use the validated helper below. Do not hard-code Android-generated directory names or assume the ~~ prefix is absent. Never switch device/package, reinstall or clear data merely because a verification parser stopped.

The helper accepts current Android ~~ directories and older package directories, binds the requested MoolSocial package and requires exactly one base APK. Malformed/traversal/wrong-package/multiple-path output must stop verification. Split APK/AAB installs require their own artifact manifest and checksums; comparing an AAB hash with an installed base APK is not valid.

After resolving the path, run sha256sum on that exact path, require native exit 0 and one 64-hex hash, and compare it with Get-FileHash -Algorithm SHA256 of the exact locally qualified APK. The new regex is not a waiver of checksum, version, signer, source, package or release checks.

<!-- installed-base-apk-path-helper:start -->
```powershell
function Resolve-InstalledBaseApkPath {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Lines,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^com\.moolsocial\.app(?:\.(?:runtime|cursorreview))?$')]
    [string]$PackageId
  )
  if ($Lines.Count -ne 1) {
    throw 'Expected one installed base APK. Split or ambiguous packages require separate qualification.'
  }
  $packagePattern = [regex]::Escape($PackageId)
  $pattern = '^package:(/data/app/(?:~~[A-Za-z0-9_+=-]+/)?' +
    $packagePattern + '-[A-Za-z0-9_+=-]+/base\.apk)$'
  $match = [regex]::Match($Lines[0], $pattern)
  if (-not $match.Success) {
    throw 'Installed path is malformed or does not belong to the requested package.'
  }
  return $match.Groups[1].Value
}
```
<!-- installed-base-apk-path-helper:end -->

Historical reservation: build/install/native replay had not occurred when this file was created. Current installation and smoke status are recorded above. Re-test the corrected Workspace entry, new application/approved Store switching, contact/details keyboard, documents, correction drafts, support return and approved Dashboard before further founder first-tap review. Use only labelled review fixtures; no live submission, OTP, payment, WhatsApp or admin approval. Store statement remains the next separate founder-review destination.
# Installation verification continuation

9 September 2026: adb install -r succeeded on OPPO 2b3e0f71; package com.moolsocial.app.runtime reports versionCode 2026090805 and versionName 1.0.0-r66.10-runtime, lastUpdateTime 2026-09-09 01:00:41. App data was not cleared.

The combined install/verification command then exited 1 because its package-path regex omitted Android's observed ~~ install-directory prefix. No launch or checksum pass was claimed from that attempt. Exact transcript C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-oppo-install-20260909.log, SHA-256 7127759DB124B2C55D3A7F934111D1DDA6EB1174DF38BD275C8BAF76569F15F4. This is an existing command-reconstruction incident, not an APK failure. The read-only pm path returned exactly one base.apk for the intended package. Continue checksum verification against that exact observed path; do not reinstall, clear data, rebuild or broaden the package target.
