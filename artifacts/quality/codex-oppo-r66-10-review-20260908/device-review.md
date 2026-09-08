# r66.10 OPPO review

## Founder-paced screen 5 — Business details — 9 September 2026

Founder approved Contact details subject to OPPO checks and explicitly instructed that genuine issues be registered before moving ahead. Its single OPPO-S03-02 validation-guidance continuation remains open; approval does not close it. Capture 115 preserves Contact before Continue; 116 opens Business details directly, with the optional backup contact left blank. Current OPPO screen: Business details, Step 1 of 3, capture 132, awaiting founder review. No additional screen review or implementation is implied by the forward/Back boundary check.

Only isolated review draft values were entered: OPPO Review Store / 302001 / Grocery retail / Authorized representative. These are fixture entries for UI testing, not a legal identity, real business relationship, approved store or authenticated global-profile change. No application was submitted.

| Check | Actual result/evidence |
| --- | --- |
| First view and selected context | 116: Complete your Workspace, Grocery / Kirana Shop or Speciality Retail Shop, Step 1 of 3; business PAN-name, operating city/PIN, primary activity and relationship fields. Continue remains above Android navigation. |
| Empty validation | 117: Continue stays at Details, focuses the empty business name and shows field-specific instructions. No navigation or submission occurs. |
| Keyboard Next/Done | 118–121: Next moves name → city/PIN → activity; text goes into the expected fields. Done at 122 dismisses the keyboard, without submitting or changing the step. |
| Invalid postal PIN and error fit | 119/123: five-digit postal PIN is rejected; Continue stays at Details and focuses the location field. Its entire two-line correction message is visible above the keyboard. Existing R669-S04-VALIDATION-FIT did not reproduce at OPPO 100% in this sequence; physical 200% remains unqualified. This is not an OTP test. |
| Corrected input | 124: six-digit test PIN clears the corresponding error without clearing the name or activity. Local format acceptance does not verify a postal address or service coverage. |
| Relationship menu | 125/127: Owner, Partner or director and Authorized representative are visible above native navigation. Android Back at 126 dismisses the menu without selecting a value or reopening the keyboard. Selection at 128 returns the chosen value to the same form. |
| Unsaved draft Back/re-entry | 129: Android Back returns to Contact. 130: Continue reopens Details with all three draft fields and relationship unchanged. No stale validation is shown. This does not qualify process death or cross-account persistence. |
| Forward/Back boundary | 131: valid Details open the top of Documents, Step 2 of 3. No file is selected or submitted. Header Back at 132 restores Details, Step 1 of 3, with the same draft. Documents review waits for the next founder decision. |
| Visual check | Actual images 116/117/119/121/125/132 inspected. At 100%, the active fields, correction text, menu choices and principal action are readable/reachable in the exercised states. No new visual defect was confirmed. |

No new confirmed Business-details defect in these bounded controls. Existing OPPO-S04-01/03/04 and R669-S04-VALIDATION-FIT receive successful replay evidence only for the exercised in-session/100% paths, not blanket ticket closure. Source, tests, registry, policy and installed APK are unchanged. Physical 200%/TalkBack, process-death/account-switch recovery, actual business verification and production services remain separate qualifications.

### Founder clarification — postal PIN and server-authoritative OTP are separate

Founder requested that a wrong server-verified OTP show the precise corresponding issue in the UI, then acknowledged that the five-digit input above concerned postal PIN rather than OTP. Attach this as an acceptance/dependency clarification to existing OPPO-S03-01 contact-verification scope, not a duplicate postal-PIN defect.

Required production behavior: server verification determines success; an incorrect code, expired code, throttling and unavailable verification each need accurate, concise customer-facing feedback at the relevant field. A transport failure must not be presented as an incorrect code, and no local input/fixture may imply confirmed contact. Preserve exact account/contact/channel/revision checks; changed contacts require appropriate fresh verification. Server diagnostics or sensitive internal details must not be displayed verbatim merely to satisfy “exact issue.”

Read-only implementation evidence:

- AuthenticatedWorkGateway.sendContactOtp / verifyContactOtp call sendWorkspaceContactOtp / verifyWorkspaceContactOtp with channel, value and code (work_services.dart around 692–708).
- WorkSession._verifyWorkspaceContactOtp awaits gateway success and checks contact revision, account scope and exact current value before onVerified (work_session.dart around 4021–4059).
- AuthenticatedWorkGateway._invoke consumes the ok/error envelope and forwards error.message in WorkGatewayException; _runBool places that message into errorMessage (work_services.dart around 911–951; work_session.dart around 5395–5418).
- This confirms the existing success-wait/error-message plumbing, not the complete live OTP contract. The live server's safe response taxonomy, expiry/throttle cases and transport exception normalization still need qualification. _runBool catches WorkGatewayException only; non-WorkGateway transport/credential exceptions require a focused failure-path check before that dependency can be declared ready. This is a source-contract verification item, not a reproduced OPPO wrong-code/network defect.

The installed APK uses the review gateway. No real OTP was requested or verified in this screen review, and no backend/authentication owner was edited. Do not use fixture success as production OTP acceptance. Keep this server-outcome requirement in the Git ledger for the later authorized frontend/backend qualification stage.

### Screen 5 capture hashes

36 new PNG/XML rows, 115–132. Full 001–132 inventory: 264 rows; canonical UTF-8/no-BOM LF-terminated SHA-256 E0CB6E8C4D2629F0426BF3372E9424B06E8D56415C454E6B22FE989AA64126A3.

```text
B87A07642B8185EB0636AC26A4EF4C806833F0FCF6A2B79C7B76E6E146A9E27C  r6610-native-115-contact-founder-approved.png
02A79D16A5AE23646A3B9A11366781C1F097769E4705225F2F1DB5842A7C13C6  r6610-native-115-contact-founder-approved.xml
955591601A4000EEAA23802D57C9035F3AF78B18F4C5C82D999482BB88E1C2D6  r6610-native-116-business-details-first-view.png
5B090E01E868711E5539041AE14A81547F3D3532D8694F9E495564554E22AFCD  r6610-native-116-business-details-first-view.xml
CAFBF042AE7870E73A6AC5A5E4BDD2EF151F673D0B7740A2CC1F724D08541124  r6610-native-117-business-empty-validation.png
D874905235E201FCCF825FA91FE125CA4426607174A8A0C1072422B437D7A12B  r6610-native-117-business-empty-validation.xml
B852D044F2FDE87C23400F4762B8C231A71D07775B39895D723C639BCD0E7867  r6610-native-118-business-keyboard-next-city.png
E265658096AB0C302D274924D3D54DC5C070869573977C8FE30EB273E5F52E70  r6610-native-118-business-keyboard-next-city.xml
1E22CA64AE3E5BD2AFACE7FC001F44411D380C78285B88E5ED7BFD74EA61E854  r6610-native-119-business-five-digit-pin-error.png
0D8C868D4DEA854C0B9FF21271F3DBA7BCC1D5EBA4794D3079C7D8D4363CDB04  r6610-native-119-business-five-digit-pin-error.xml
F21C763E866600E57247153012347A80FF0FC2B693AF95E05AD79F8999E85AD1  r6610-native-120-business-keyboard-next-activity.png
5F5DC2CDA1F0606AE913F7F91D41EC3752EF93D2985F63D0E9B7875835AEB3F3  r6610-native-120-business-keyboard-next-activity.xml
DF073CFCBB7E3A7934B6DAA7230DFD4B71CA9FCADF752AC5AFE292365D750E50  r6610-native-121-business-activity-keyboard.png
A0CC7D8874060AA4A1FAC23626BF3A3BCFCD1D7FF259D289FA12140ABED0FA43  r6610-native-121-business-activity-keyboard.xml
910307262543FD4C60F0B96D845C7EF749D1DCF585794EF76AEFD9D5FBACD305  r6610-native-122-business-done-no-submit.png
6EBA4FEC47A902F58934271DA40A5E3CA27E1D198A739BEF1DE0C26A3FBF24BE  r6610-native-122-business-done-no-submit.xml
8B3DB5575A4962BA74B400D580358A8BA8C6F9989F2E6411A0FD66C0527CB315  r6610-native-123-business-invalid-pin-blocked.png
F471BA644F95699F000306285E5C490A0EDB2A1B2799CBCEEC7DD6DF7841FD4A  r6610-native-123-business-invalid-pin-blocked.xml
FE3ED5C1BD3FB0B16BD413157CD505BF71A59329CD015F45F8F537C97BB7008C  r6610-native-124-business-pin-corrected.png
33E11DD9F36ECBB45D2AAD5261652D6B4A369E6FFBF3AD2157A0727AE5F9FBD2  r6610-native-124-business-pin-corrected.xml
F1DAA83B4F741717A06BFF781446D05F70164F19F08EF03D7E8619CA81C6040E  r6610-native-125-business-relationship-selector.png
2C1649F98483C1E1AAED9E26F037CAE3B52C57EB7EB72F4057DA6E77581A083C  r6610-native-125-business-relationship-selector.xml
EA3893A2BE58F5572B10009CF729C4EF8EDC105E829C0EA32B8B72BFA1FB1A93  r6610-native-126-relationship-cancel-retains-draft.png
891A9E4DB3F4C9740D2F50A4C01D6211303DE2B33B3BA4F16EC81FA60DD37635  r6610-native-126-relationship-cancel-retains-draft.xml
6F848D02A73AA9D3C672869CD086C9411D910622903735F5436EB488464B8888  r6610-native-127-relationship-selector-reopened.png
2C1649F98483C1E1AAED9E26F037CAE3B52C57EB7EB72F4057DA6E77581A083C  r6610-native-127-relationship-selector-reopened.xml
937370C6BCE40CF5B55976EEABBD0511CF685FE680233E35023179C8ACB7FA01  r6610-native-128-business-relationship-selected.png
F61EFF8BEB946DC991A02C172C083C22802CCDC94CE2CE927EBB14D77E936747  r6610-native-128-business-relationship-selected.xml
1214F0419A6B54012709DF14C13A6BA40AA2506BC54BD0A013F2A79129007F82  r6610-native-129-business-back-contacts.png
02A79D16A5AE23646A3B9A11366781C1F097769E4705225F2F1DB5842A7C13C6  r6610-native-129-business-back-contacts.xml
ABF3105FA35E79C4C00CC9A2152592F1617EF1C857D93EB2730A9348EDE0011F  r6610-native-130-business-draft-retained.png
C2F051CA5BCEC76C3F9DC95ACE5B8207DCF197C5062EDE343D027BE8DC1632AC  r6610-native-130-business-draft-retained.xml
3587E6689362549356CC1639D942A00EACB550726E8C9839DB3E1E66EFB6FFD6  r6610-native-131-business-to-documents-boundary.png
DFD86AE6A8A6E50700D70A01F063C787A3178E5F917F310B55976ADF37120F35  r6610-native-131-business-to-documents-boundary.xml
56D652D865B9CB81152D96D50D65C4DBF246D288D15D472E979F29FE9B7D78C6  r6610-native-132-business-details-founder-review.png
C2F051CA5BCEC76C3F9DC95ACE5B8207DCF197C5062EDE343D027BE8DC1632AC  r6610-native-132-business-details-founder-review.xml
```

## Founder-paced screen 4 — Contact details — 9 September 2026

Founder approved Screen 3 (Documents to keep ready), subject to Codex finding no defect in OPPO checks. The bounded readiness checks passed as recorded below; production verification, other business types and physical accessibility are not waived. Capture 099 preserves that approved readiness view; 100 enters Contact. The current screen is Contact details first view at 114, awaiting founder review. Do not advance to the Business details review or implement fixes during this screen-by-screen defect-collection phase.

### Confirmed finding — OPPO-S03-02 / r66.10 validation-guidance continuation

Status: OPEN, frontend correction required; one issue covering phone and email, attached to the existing contact-validation ticket rather than duplicated. Priority: P2 customer correction guidance. Exact reviewed user: Grocery/Kirana applicant editing their contact details. Existing ticket's actionable field-level validation requirement also covers this inconsistency; earlier layout fixes are not being reported as failed.

- Phone reproduction, 101–105: Change the confirmed contact, enter incomplete draft 123, dismiss the keyboard and tap Continue. It blocks progression but says “Confirm the phone number customers can reach you on before continuing.” Send code then says “Enter a valid 10-digit phone number.”
- Email reproduction, 107–110: Change the confirmed email, enter malformed draft invalid, dismiss the keyboard and tap Continue. It blocks progression but says “Confirm your email address before continuing.” Send code then says “Enter a valid email address.”
- Impact: the first action gives the wrong next-step guidance for malformed input. The customer must use another action to discover the format error. Both handlers reject the invalid values; no OTP-entry state or real send occurred. This does not establish an authentication bypass or backend security defect.
- Read-only cause: apps/mobile/lib/features/work/work_session.dart continueToProof checks confirmation flags before classifying contact format (around 4074–4093), while send-code validation classifies malformed input separately (around 3897). No owner was edited.
- Required correction: Continue and Send code must give the same concise format-specific instruction for malformed input; only well-formed unconfirmed values should ask for verification. Preserve changed-value invalidation, independently verified phone/email, optional backup-number semantics, field-local errors, keyboard safety and Cancel restoration.
- Future qualification: focused tests for empty/malformed/well-formed-unconfirmed/confirmed and changed-contact cases across phone/email, with optional backup coverage; local normal/200% visual checks and matching successor-APK OPPO replay. Do not mark fixed from this registration or from existing pre-APK tests.

| Check | Actual result/evidence |
| --- | --- |
| Prefill and correct context | 100/114 show the retained name and exact contacts, existing review confirmations, approved Grocery/Kirana-or-Speciality subtitle and authorised-person helper. No new verification request occurs simply on re-entry. |
| Edit and keyboard | 101/107 enter their respective keyboard/edit states; 103/108 dismiss the keyboard without leaving Contact. Screenshots 107/109/112/114 inspected; the active email field and Cancel remain above the keyboard, and validation/actions remain above Android navigation when dismissed. No physical 200%/TalkBack pass is claimed. |
| Changed-contact safeguards | 102–105 and 108–110 no longer show the edited invalid contact as confirmed, block Continue and reject Send code before OTP entry. Real OTP delivery/verification is not tested by these review fixtures. |
| Cancel restoration | 106 and 111 restore the original contact values and review confirmation display; their native XML equals 100. No invalid test draft remains. |
| Optional backup number | 112 reaches the empty “Backup number · optional” field and helper by scrolling while Continue stays visible. Blank-backup forward completion was not newly exercised here. |
| Back and re-entry | 113 returns to the correct Documents to keep ready screen; 114 re-enters Contact with the same name, contacts and confirmation display, and no stale validation. This is in-session navigation, not process-death/account-switch persistence qualification. |

No product/test/policy/registry edits, real SMS/email, external messages, document submission, payment or admin approval were performed. Cursor and Redmi remain untouched. Backend qualification, physical accessibility and other unplayed interruption cases remain separate. This screen is not defect-free: the validation-guidance continuation remains open.

The interrupted/truncated capture-106 result was recovered by inspecting the existing PNG/XML and current foreground; Cancel was not blindly repeated and no unavailable output was counted as a pass. A later read-only source search included a nonexistent ui_v2/work directory and exited 1; only the independent, directly read work_session.dart content supports the cause above. Existing bounded-output/discovery prevention remains applicable; neither event is a product-test pass.

### Screen 4 capture hashes

32 new PNG/XML rows, 099–114. Full 001–114 inventory: 228 rows; canonical UTF-8/no-BOM LF-terminated SHA-256 263491E3DDD1B79AB4EF8F06BF5EAE821E002CF69D162A5E0BCFE9CB2A1DF221.

```text
F621BFE7258E343BABACB4C1461523CB1FC579F2F3AD932FACEC95E182E2E4B1  r6610-native-099-readiness-approved-checkpoint.png
8EF7326C0A3F351ADC6BF34BD36CFA3BBEB4680EF36ABB59001E458EF1E02F26  r6610-native-099-readiness-approved-checkpoint.xml
DAD91BD4B38D72FFE10CFD6503C2D547DD04BE2F0BEB70C990879655D067A60F  r6610-native-100-contact-review-first-view.png
02A79D16A5AE23646A3B9A11366781C1F097769E4705225F2F1DB5842A7C13C6  r6610-native-100-contact-review-first-view.xml
A6F16CAE6022DA8319F4B3A706CE3FEEA562D875798D46266E8821C38C18AE85  r6610-native-101-contact-change-editing.png
27C0F3784C3A169D7B201F8BFE6ECF535281935DDC3A4526F1BD5272DB47676F  r6610-native-101-contact-change-editing.xml
1643DC7DFDE5BC28EE3914B2FFAC4DA9EA22D5206A18FC39E9BE8735DC1DBD52  r6610-native-102-contact-invalid-draft.png
41D48AB076A9F697241FBE1ECDFA7FF21A8FBC980F29CDB11737AB07B52D39BF  r6610-native-102-contact-invalid-draft.xml
5A93C189857F253B777E5649CD0D53229CAEC9E3A503BD176B41A8DD4940B708  r6610-native-103-contact-invalid-keyboard-dismissed.png
E28564CB0619F26C48FB7D261EF53DC76D29A0EC58F8BFE55E9E7AD6A7D15C68  r6610-native-103-contact-invalid-keyboard-dismissed.xml
4F3B9FE3FE2C181BE4C750319BAE6592C2D761E404971D2F6F8EB195DF208F57  r6610-native-104-invalid-contact-blocked.png
B2F6CA9C7D7B4ABDF8E28E1A85C005BBCBFB7209F209CFA9EA9360679603C4DB  r6610-native-104-invalid-contact-blocked.xml
17B2E969996A4D4C3816D756FD89085435CE22DA901DD2E8E3D9B825C3BD9B44  r6610-native-105-invalid-phone-send-code.png
2B08666A131944F1812C0B3702409381C2C22236FD2E99B30FDFE1CA3F2F2A84  r6610-native-105-invalid-phone-send-code.xml
416A8B0E34B31A6CD66AEBFB054DC4205B5D656FEDAF3B60F0DA78DB6C929379  r6610-native-106-phone-cancel-restores-confirmation.png
02A79D16A5AE23646A3B9A11366781C1F097769E4705225F2F1DB5842A7C13C6  r6610-native-106-phone-cancel-restores-confirmation.xml
70FB3DC324ABD640E7C3CD17AF96B602F2633C821EC39B05555A872F3505960E  r6610-native-107-email-change-keyboard.png
12EB5892567B9352193C07126DDB764DAFA381CE34F61F6643C0B20718C7D4CB  r6610-native-107-email-change-keyboard.xml
41BE591084F9B0F28542FFE87DBC84ED716A9F921259A971CBB5225F99C0BDEB  r6610-native-108-invalid-email-keyboard-dismissed.png
6634FD79A87B560E83719C074DCDDA4D2C1C8CFB73221822A3F3E52071ADD8B2  r6610-native-108-invalid-email-keyboard-dismissed.xml
3CA79345114AD95536006B9E9E8F0D031D2D730DD0C0E84D93658D8688843F9A  r6610-native-109-invalid-email-continue-message.png
BDA427C87D15022D836A5A2FB50B5AF923B88C7EA61A05181FDB95E63F2477E2  r6610-native-109-invalid-email-continue-message.xml
903DD58E144EAC7F8870C43C0B975995C0D2572B0698A03A3F9245F75AFE45A7  r6610-native-110-invalid-email-send-message.png
BB431009A033CFCE7D2F2B208D84B01AF89E94E4A8268A46B44701C531031834  r6610-native-110-invalid-email-send-message.xml
2CE0985453389784316B5889744197ACEC993D4F6CEBED911759AC24F0C2F5BB  r6610-native-111-email-cancel-restores-confirmation.png
02A79D16A5AE23646A3B9A11366781C1F097769E4705225F2F1DB5842A7C13C6  r6610-native-111-email-cancel-restores-confirmation.xml
0368F05FFD76FF74ECD2E8010647B192EF9BD909457DABD5C3DF955250833546  r6610-native-112-contact-alternate-reachable.png
B44BD5EC7693265EA5395DC2CDFE3778D08BC987571FDD56798E581D9B95CCA9  r6610-native-112-contact-alternate-reachable.xml
E65FD01DB9B4D47147763ACEDD1D5E519AF8239D70DC60B73EDEE7DF4DC37029  r6610-native-113-contact-back-document-readiness.png
8EF7326C0A3F351ADC6BF34BD36CFA3BBEB4680EF36ABB59001E458EF1E02F26  r6610-native-113-contact-back-document-readiness.xml
A12B11ECF1146E875FE9214A8E5D8F4DA1A614BB4298D515B182B0F8E9BF7498  r6610-native-114-contact-reentry-retains-confirmations.png
02A79D16A5AE23646A3B9A11366781C1F097769E4705225F2F1DB5842A7C13C6  r6610-native-114-contact-reentry-retains-confirmations.xml
```

## Founder-paced screen 3 — Documents to keep ready — 9 September 2026

Current OPPO foreground: Documents to keep ready, Grocery / Kirana Shop, first view, capture 098. Screen 3 awaits founder review. Continue setup has not been activated in this screen's current review; contact entry is the next stop after approval.

The forward transition from the preview was not inferred from the first attempts: 090 still showed the preview, and 091 showed the selector. Those captures do not qualify a forward pass. The founder's explanation of their own Back tap applies to 069 only; do not assume it explains 090/091. The actual route/source was inspected without edits. Fresh controlled Choose this Workspace at 093 reached the correct readiness screen; Android Back at 094 returned to its preview; a repeated centred button tap at 095 reached the correct readiness screen again. Preserve the earlier attempts as inconclusive, with no confirmed reproducible route defect. If this recurs with exclusive phone control, reproduce and register its root cause before closure.

| Check | Result/evidence |
| --- | --- |
| Selected business and destination | 093/095: Grocery / Kirana Shop has the matching Documents to keep ready title. It does not borrow the old approved store's name or send the user to its dashboard. |
| Correct Back/forward | 094 returns to the originating preview; 095 returns to the correct readiness screen. No new application is approved or submitted by these transitions. |
| Complete scrollable list | 095–096 expose identity proof, shop address proof, food-business licence where applicable, owner's permission where applicable, bank proof and conditional GST guidance. The bank row explains cancelled cheque or recent statement and account holder/account/IFSC fields. |
| Layout/visibility | Actual screenshots 095 and 096 inspected at OPPO 100%. Text wraps, bank/GST content is reachable, and Continue setup remains above Android navigation. 097 was only a partial scroll return; 098 confirms the complete first view restored. |
| Backend boundary | This is document guidance, not verification. Actual document validation, approved/clarification/rejected status and Chat/WhatsApp/email/call updates need their production integrations; none was executed or qualified here. |

No new confirmed functional/visual defect in the controls exercised. No fresh legal-compliance audit, every-business document audit, physical 200%/TalkBack qualification or backend pass is claimed. The existing accessibility pending items remain. Founder approval applies only after their response to this screen; do not advance to Contact yet.

### Additional capture hashes

18 new PNG/XML rows, 090–098. Full 001–098 inventory: 196 rows; canonical UTF-8/no-BOM LF-terminated SHA-256 F7A4F31D44C3CB07E9E8D015BB546D78706C5C50F93EF9AA0F8A959719854254.

```text
8B5B84226E34C23767F44FA48E609B45BC23F34FD62C24609761EC12E997B480  r6610-native-090-documents-ready-entry.png
687AE00253F60AA8AE3565290302D2A9EC457949335EB15562C02771858A0F56  r6610-native-090-documents-ready-entry.xml
3DC7F611A07E9130E234DF9DA9AF06EEC45EC443F402F3AEBBC619B35E24AFE2  r6610-native-091-workspace-forward-retry.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-091-workspace-forward-retry.xml
81E5B2DCF24D7FF4490207A1C9EAC13625DD8084F806F4DC36FAA0F5B36EB36E  r6610-native-092-forward-boundary-preview.png
6B484BBF33E12338D3D50866DC5B009A53A4A40CC019B104448BF83A33F75273  r6610-native-092-forward-boundary-preview.xml
DA4A6E268316C6F3F0D45BD6EDB19FCB038E952C8734B4DEF86A63C16F7E3708  r6610-native-093-forward-controlled-result.png
8EF7326C0A3F351ADC6BF34BD36CFA3BBEB4680EF36ABB59001E458EF1E02F26  r6610-native-093-forward-controlled-result.xml
7A81341BC0866338682884F2287431828C2E2FCDFDE57CEC325CEBAE2A966255  r6610-native-094-requirements-back-preview.png
6B484BBF33E12338D3D50866DC5B009A53A4A40CC019B104448BF83A33F75273  r6610-native-094-requirements-back-preview.xml
906F04D9CC9EBCF95CE6BFF050EC6EAC0F18E5CB55A714A1681480044739D9A5  r6610-native-095-requirements-forward-repeat.png
8EF7326C0A3F351ADC6BF34BD36CFA3BBEB4680EF36ABB59001E458EF1E02F26  r6610-native-095-requirements-forward-repeat.xml
8E268C3A1ECB73BD41053875E6F11C2F6C44D5270D65818C6CFC11BA8A4AA7CF  r6610-native-096-requirements-bank-and-gst.png
81208F67BA33A8F3F0B40F52B6FDF54310A2650D6559869D581E3C7902B73A45  r6610-native-096-requirements-bank-and-gst.xml
2D1F387DF857E5597E3B1FCB8D339B7098A277EEE9098A6C6184BFC50A87EE30  r6610-native-097-documents-ready-founder-review.png
D48E55D155A97C0CED139E6E47E27B7A4F5C19C6656A2C67A3F6CC4F6462837A  r6610-native-097-documents-ready-founder-review.xml
488BFE43FA66B58B3E5C073848D3CA236E274BBF1D178EAFBFA61CB781DC9235  r6610-native-098-document-readiness-first-view.png
8EF7326C0A3F351ADC6BF34BD36CFA3BBEB4680EF36ABB59001E458EF1E02F26  r6610-native-098-document-readiness-first-view.xml
```

## Founder-paced screen 2 — Grocery/Kirana preview — 9 September 2026

At this checkpoint OPPO shows the Grocery / Kirana Shop expanded preview, Customers first page, capture 089. Founder approved screen 2 subject to Codex finding no defect in OPPO testing. No confirmed defect was found in the exercised controls below; this conditional approval does not waive physical accessibility, other business types or backend qualification. Choose this Workspace has not yet been activated in this review; its forward transition to document-readiness is the next check.

Boundary clarification: capture 069 is an observed dashboard, despite its intended-preview filename. Founder explicitly explained they had tapped Back. It is not a product defect. Captures 070–072 repeat the controlled request-new → Grocery preview route successfully. No implementation workaround or speculative navigation ticket was created.

| Check | Actual evidence and result |
| --- | --- |
| Topics in the same preview | 072–076, 079–082: Customers, Stock, Money and Daily work switch the local content, without leaving for the advertised operational feature. |
| Complete headline pagination | Customer counts 1–3/4–6/7–8 of 8 (072/084/085); Stock 1–3/4–6 of 6 (080/081); Money 1–3/4–5 of 5 (074/075); Daily work 1–3/4–6 of 6 (076/079). These cover all 25 displayed headlines, not every expanded description or the features' execution flows. |
| Last-page limits | Native XML for 075/079/081/085 reports More points enabled=false and clickable=false; page controls do not advertise a nonexistent next page. |
| Expansion | 082–083: selecting Collect at store collapses the previous description and displays its own short explanation in this preview. No payment/order/collection action is performed. |
| Layout and persistent next action | Screenshots 072/074/079/081/085 were visually inspected; text wraps, selected tab is visible, and Choose this Workspace remains above native navigation. This is OPPO at 100%, not a new 200%/TalkBack pass. |
| Back and close | 086: Android Back collapses the preview into the selector, not the approved dashboard. 087 reopens the first Customers page. 088 Close details returns to the selector; 089 reopens the clean first preview. |

Ineffective-coordinate attempts are preserved honestly: captures 077 and 078 still showed Daily work 1–3 of 6, so their filenames do not establish successful paging or Stock selection. The panel was at a different scroll offset; the next action was re-aimed using freshly observed bounds. Actual page/tab changes are shown in 079 and 080. Do not turn these unqualified taps into successful tests or assume an app defect from them.

No new confirmed functional or visual defect in the interactions exercised. Screen 2's founder approval is conditional on those technical checks and is now recorded; there is no blanket defect-free release claim. Physical accessibility, other business previews and the advertised services' actual journeys remain separate qualifications. Live deliveries, invoices, reminders, tax assistance, procurement, credit, payments and collection cannot be considered connected or production-ready because this explanatory preview renders.

No source/test/policy changes, external messages, real payment, production contact verification or backend writes occurred. Save only the evidence update and remain at 089 for founder review.

### Screen 2 capture hashes

42 new PNG/XML rows, 069–089. The full 001–089 inventory has 178 rows and canonical UTF-8/no-BOM LF-terminated SHA-256 3C0147C3DFD681E48625844A396513666CE8AC3489567D1B32AD04B01CE089FE. Previous capture hashes are retained in the preceding sections.

```text
E7373AB9218C638249CA1EBA582097A4627734E549490DFF169D80EF8B24B93E  r6610-native-069-grocery-preview-review.png
F55D50C5507F06D0EFC9BBA7463C27191B9392F87FC14067B7020494EC549A0C  r6610-native-069-grocery-preview-review.xml
DA772FE21C8AB33222B3FADEEDB5436CF2D1E014FA0326148F9B686040C09948  r6610-native-070-repeat-new-workspace-entry.png
8271705974EDFCC7E8284C047B24992AFDBF83CB358C30BE780EB2114F9BD068  r6610-native-070-repeat-new-workspace-entry.xml
7AF49BA9D37DCFCD33ED402EECCFE0A64EDB4FEA5A59AFFF96B192EA5ECB87A5  r6610-native-071-new-request-before-preview.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-071-new-request-before-preview.xml
473B41779C42D9EC8A50BDDBD7D68F4DC71941FC30A3540CB2FD63C3316DFA9F  r6610-native-072-preview-controlled-replay.png
687AE00253F60AA8AE3565290302D2A9EC457949335EB15562C02771858A0F56  r6610-native-072-preview-controlled-replay.xml
C291DF6A7EE50885577B013D8B44D485E93E0F76325200A89F6EC52B8DDE66FA  r6610-native-073-preview-stock.png
2DF8F9B638339028CFB4BBAA02AB1B6F54754A40FA76C7204607885A39AA818C  r6610-native-073-preview-stock.xml
A9D9559E65F209BCFBDC65425D874692A0C78073B94F8769DAA00144AF480F5D  r6610-native-074-preview-money.png
279C5493D5BB28CAEF0B3807F21112D0B820E4F1AA10180947ED997CF2C88D7A  r6610-native-074-preview-money.xml
64F7BB1F019D77B4777D2B12AD01EFB839F32ED9628B1ABAD3FEA3E93F62EDEF  r6610-native-075-preview-money-last-page.png
BA90BDE2A5E721AF3F011348448EB870FE1AE95CF2A45E5DA0C044B575F1B94C  r6610-native-075-preview-money-last-page.xml
7555B3FCB423A5ACC34534929B05731DC90C305A2D79D3FE4D8A4C744651A559  r6610-native-076-preview-daily-work.png
B4FFC797F83A9B59DAA6DB52C517B200C8EF593D53B4C619524A056C5B344B60  r6610-native-076-preview-daily-work.xml
EC8DA50EB544691CB71AA440EE56664EE1FB27F7C130E6B862A50C506928F04B  r6610-native-077-preview-daily-work-last-page.png
11DBE65AED28FE7A1772C7F1713B8AFEE48D270229690224CC19614D1E269423  r6610-native-077-preview-daily-work-last-page.xml
EC8DA50EB544691CB71AA440EE56664EE1FB27F7C130E6B862A50C506928F04B  r6610-native-078-preview-stock-reset.png
11DBE65AED28FE7A1772C7F1713B8AFEE48D270229690224CC19614D1E269423  r6610-native-078-preview-stock-reset.xml
FDE7F9C14A23B17FAB4D41470DB2A08E7F419D974FB889B30EFBF82AAEEC8115  r6610-native-079-daily-work-paging-confirmed.png
04B9F31E33E42F03DDA8CAF081F24C5A501AE7339C2885976008A79FABEDAD64  r6610-native-079-daily-work-paging-confirmed.xml
76AA0F3B3C6330F47735901F9EA35B607A55A2B4A0D2515032F178E3FAF6E2CB  r6610-native-080-stock-tab-confirmed.png
254CFD7694126A493878CE8E4DD1608A47AF5880C98D9DC57423FD1E352C1755  r6610-native-080-stock-tab-confirmed.xml
C99F32C8B87F6F423D555421BAF3D3023C6D8CA0C86023BBFE8071613B4D07A0  r6610-native-081-stock-last-page.png
108A472C44CA2D5FE8B065B1D18B77DC4B8963A411DCA7924406E403C0D04865  r6610-native-081-stock-last-page.xml
1148E31F96C8CD987F4436F7658EA0B6A4719523FCE703729EBC98271067EED5  r6610-native-082-customers-first-page.png
DCCD185221DEAADD76ED1BFE91684B17E8C7FB267A225839061779D0F83B285B  r6610-native-082-customers-first-page.xml
71EAFCD89AF44D69D94089DA810DCBDDB82A509552BF4DF3018FEF416D6E8B39  r6610-native-083-collection-explanation.png
610149F6109D061E4398147BAE26FFA29F3D9C29E0563CA606E4340D452CD5E8  r6610-native-083-collection-explanation.xml
1D5DC956C49EC4C66F1402EC12022EAE0F967445DD0645202B68A258B3EAB881  r6610-native-084-customers-second-page.png
BD2B9736C9C07A95D6A9343C1504CFA0820662DD5F4BA8FC3B4680DD0AF9213A  r6610-native-084-customers-second-page.xml
1278A39F20E9B3566F8E0C0CAD96674E321C94EC3FE2F340ECA361D3F4A03177  r6610-native-085-customers-last-page.png
4D176B8F1FB1D7C492614B6C3322218B1FC062E1AEB4F29C9210B1C4D61DED98  r6610-native-085-customers-last-page.xml
F4CC8D90666FC100BF71289788E2776DA0C3502B174F4972F36757B3BD60CE82  r6610-native-086-preview-back-to-selector.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-086-preview-back-to-selector.xml
0A4AC095733707555FA7396F271F4C484DC3348BFAAA9E19B1D519B26A128698  r6610-native-087-preview-reopened.png
687AE00253F60AA8AE3565290302D2A9EC457949335EB15562C02771858A0F56  r6610-native-087-preview-reopened.xml
3457945AF205FF7D4FEC19C644F8C9613DD2553DE98A42A2E378554DCA1FE287  r6610-native-088-preview-close-control.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-088-preview-close-control.xml
ABE39D7A1A56AF7338CE057AB7031F362C4FCE5D057AA64A74DE034C2A2B9BEE  r6610-native-089-preview-founder-ready.png
687AE00253F60AA8AE3565290302D2A9EC457949335EB15562C02771858A0F56  r6610-native-089-preview-founder-ready.xml
```

## Founder-paced screen 1 — Grow with MoolSocial — 9 September 2026

Founder asked whether all screens had been replayed and requested one-screen-at-a-time review. Answer: no blanket production qualification. The preceding 001–054 sequence is one bounded Grocery journey, not every business type, failure mode or Dashboard destination. Resume per-screen testing, then pause for founder approval/additional inputs; do not advance the review or implement speculative defects.

At the screen 1 checkpoint, OPPO showed Grow with MoolSocial, clean initial selector, capture 068. It was reached from the approved test store through Change Workspace → Request another Workspace (055–057). This is the new-Workspace journey; an existing approved Workspace normally opens its dashboard. No real application or account was changed. The later screen 2 checkpoint above is the current foreground.

| Check | Evidence/result |
| --- | --- |
| Inline search and keyboard | 057–058: grocery filters to Grocery / Kirana; input and result are visible above the keyboard. |
| Category menu while typing | 059–060: menu opens after keyboard dismissal; Android Back closes only the menu; query/result remain and the keyboard does not reopen. |
| Clear and no-match recovery | 061–062: Clear restores all choices; a nonsense query produces an honest no-match explanation plus the existing Tell us what you do action. That separate screen was not opened in this review. |
| Category filtering/reset | 063–066: Food Business shows Restaurant / Café and Cloud Kitchen / Tiffin; All businesses restores the initial list without changing the selected application's identity. |
| Scrolling | 067–068: list scroll reaches the Manufacturer and Food sections, with header/navigation retained; return to top restores the initial first view. |
| Back to approved store | Already captured in 053–054: a new-Workspace request can be left without losing the approved dashboard. Not falsely counted as a new independent retest. |

Disposition: no new confirmed functional or visible defect in the controls exercised on this screen at OPPO's current 100% setting. Existing founder-approved first-view geometry was not redesigned. This is not closure of all R669-S01 cases or a production-accessibility verdict. Preview panels, Tell us what you do, other business-type journeys, physical 200% and TalkBack remain separate checks.

Accessibility observation S01-A11Y-SEARCH-OBS (unconfirmed, not a duplicate product defect): the native empty search EditText in 057/061 has empty text/content-desc and NAF=true, whereas the actual screen visibly renders Search. Source uses InputDecoration(hintText: 'Search'). Because this hierarchy dump does not establish what TalkBack announces from hints, do not claim a missing-label defect or an accessibility pass. Verify the spoken name/hint with an appropriate accessibility replay before release; preserve the screen-reader pending item already recorded.

Backend distinction: the local selector/search/filter controls were exercised. Real account approval, permissioned Workspace access, server availability and persisted multi-application reconciliation were not qualified by review fixtures. No live SMS, email, WhatsApp, support message, payment or admin action was performed.

Founder visual decision for screen 1: approved with “I TOO APPROVE”. The screen-reader pending item is not closed by visual approval. The founder then confirmed that the dashboard return observed in capture 069 resulted from their own Back tap. Do not register it as an app navigation defect. Controlled request-new replay 070–072 opened the preview correctly. No subsequent document-readiness destination is included in screen 1's verdict.

### Additional capture hashes

Append these 28 rows to the prior 108-row capture inventory. The combined sorted 136-row UTF-8/no-BOM LF-terminated inventory SHA-256 is 7795A2CDE6D80366E74EBFE59D51AA6AC322CB2F3DFC42FCAB39A0BF674626A0.

```text
5FA1F5AF358EB01E09DCED343D550E055B5EC5B5D5F33C63450D26B11E698B64  r6610-native-055-founder-review-start.png
F55D50C5507F06D0EFC9BBA7463C27191B9392F87FC14067B7020494EC549A0C  r6610-native-055-founder-review-start.xml
382737F8162392F16A36A2AF207C8C29977DAD5F121CC7D383DE1B12F6AEDE16  r6610-native-056-review-entry-chooser.png
8271705974EDFCC7E8284C047B24992AFDBF83CB358C30BE780EB2114F9BD068  r6610-native-056-review-entry-chooser.xml
BB31A9726DCF52BBB24A80608DD6AAA91585DB1015722C70310475AAA1004EB2  r6610-native-057-grow-first-view.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-057-grow-first-view.xml
0DE20B105A3C7B35E316F006B57BBF67F7DAF2BDC04E8DB943244B623EE14427  r6610-native-058-selector-search-keyboard.png
4A927F7880A03D46A9167CB42E04FA1E1CA8AF89A8A6E5DF167A7B2D9C32D35F  r6610-native-058-selector-search-keyboard.xml
001F81931B1F5EEF644C554BF099385E545DD642725121685CE0EA501376B638  r6610-native-059-categories-keyboard-dismissed.png
B2CDA4CD4E2C4C75D3405BBBFA7C491973DD7837A0A837B28D37030C7403B7C5  r6610-native-059-categories-keyboard-dismissed.xml
132DB3388B7674046B75693E13B895C4AA38817C91DD9BEAE0482587A189FFD8  r6610-native-060-category-cancel-return.png
8531C01233500BF34D4A44727777ABC3E3D7F11DB354C2726CE710906414049D  r6610-native-060-category-cancel-return.xml
2B216DF343937C0CAEF73BC54C45C67A5DDA30747F4C10226D62C1D8EF1CF6DB  r6610-native-061-search-clear-restores-list.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-061-search-clear-restores-list.xml
22C3FC993E3FF332F019E1D96B3319B4096A9AA5704AA7C174EA0F76EBAFD2D6  r6610-native-062-search-no-result-recovery.png
2D9D2BB84AAB3ECED6C81CB91F962768A93E606381DF73F1DBD69262ED4BD778  r6610-native-062-search-no-result-recovery.xml
816E87B075C6AA11300183F6B0AE1381B7F53FE3E5326EBA6CF31FB77F149FA4  r6610-native-063-category-selection-menu.png
B2CDA4CD4E2C4C75D3405BBBFA7C491973DD7837A0A837B28D37030C7403B7C5  r6610-native-063-category-selection-menu.xml
1112345383C2E0D085E118963FD7D0FB0F5C334591B7A05A4DBE34F17ECB476D  r6610-native-064-food-category-results.png
887035C3D7F4FABDADA12C301568F72B481A6F82EABEF2BC768A7168287496CD  r6610-native-064-food-category-results.xml
A5D5D90C9EE29E60A94CEDF395BFF1CAB170434C5CFDE478743E0ED27AD54789  r6610-native-065-reset-category-menu.png
B2CDA4CD4E2C4C75D3405BBBFA7C491973DD7837A0A837B28D37030C7403B7C5  r6610-native-065-reset-category-menu.xml
BA04DFABAF84BFB669E46B802F33E11F84F16DEF91E7FEDF1EB6E6DAFD785ED2  r6610-native-066-category-reset-first-view.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-066-category-reset-first-view.xml
B0F179279810B7ACA94459204477533CBD8170DC72ABC7A52495906A08A2CEBF  r6610-native-067-selector-scroll.png
BC4291A4C6958ED6FD8669E267BF8B49B2A7B5D71DEBD0049F851F78F15D4F11  r6610-native-067-selector-scroll.xml
0E2FD8F2BA66F2658EE75E3D64EF45B5C5AB9DA33CC5569273E72377304F65BC  r6610-native-068-screen-one-founder-ready.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-068-screen-one-founder-ready.xml
```

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
