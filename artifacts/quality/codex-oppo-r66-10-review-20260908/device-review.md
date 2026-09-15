# r66.10 OPPO review

## Standing conditional approval — journey through Dashboard and bounded first-tap checks — 9 September 2026

Founder extended the previously given visual approval into standing conditional approval: continue OPPO testing without another per-screen permission, register genuine defects, and do not treat untested states or backend fixtures as defect-free production. This supersedes the earlier awaiting-founder checkpoints below. No approved design was changed.

This continuation adds 74 native actions/captures, 193–266 (148 PNG/XML files). Current OPPO screen is the approved review store's Dashboard at 266, with no keyboard or popup. The application under test is the new OPPO Review Store review application ending -2; the earlier Review Clarification QA2 application ends -1. These are explicit local review fixtures, not live customer applications.

### Actual native results

| Area | Actions and result | Evidence |
| --- | --- | --- |
| Review and local submission | Rechecked the existing summary, scrolled to the declaration, selected it, and submitted once. Application received remains pending rather than automatically approved. | 193–196 |
| Pending reference and ordinary background return | Expanded the exact application reference; HOME and normal foreground return preserved the same pending application and reference. Collapsing it did not change the review state. This is not process-death/relaunch proof. | 197–199 |
| Clarification entry | Explicit review-only scenario selection produced More information needed with the exact supplied business/document reason and correction actions. | 200–203 |
| Targeted document correction | Selected only the named NOT-A-REAL-DOCUMENT QA PDF from native Android Downloads for Shop address. The earlier Authorization letter QA PNG remained attached. No personal document was selected. | 204–206 |
| Unsent versus submitted information | Android Back returned to the clarification state with Changes not submitted. The submitted summary still had one attachment; Review changes showed the draft with two. This exercised correction preserved the acknowledged snapshot rather than claiming an unsent upload had been submitted. | 207–209 |
| Correct attachment previews and return | First View opened the Shop address two-page QA PDF; second View opened the separate Authorization letter QA PNG. Each Back returned to the exact correction review. Legacy UI inside the QA image is attachment content, not a current app defect. | 210–213 |
| Correction declaration and same-application acknowledgement | Verified the correction declaration initially unchecked, selected it, then sent the local correction once. Application received showed two attachments; the expanded reference exactly matched 197 (same application ending -2). No automatic approval or pending edit/upload prompt appeared. | 213–217 |
| Rejection and support | Explicit test rejection showed the supplied reason and Contact MoolSocial, without a dashboard-forward action. Support opened the correct current application's header but restored the previous application's unsent draft: confirmed finding R6610-SUPPORT-DRAFT-SCOPE-01 below. Keyboard dismissal and Android Back returned to the current rejection; nothing was sent or discarded. | 218–223 |
| Approval boundary | Only an explicitly selected review-only Approved scenario opened the correct Dashboard directly. Store remained Off/private with setup incomplete. Approval did not itself publish the store or enable orders. A transient welcome was not captured, so its timing is not qualified here. | 224–225 |
| Inert status popup | Status opened a compact Off/private explanation. Back dismissed it without changing either state. Physical TalkBack semantics remain unqualified. | 226–227 |
| Two same-type approved workspaces | Chooser identified both businesses and the selected workspace. Switching each way opened its correct Dashboard directly, not the onboarding journey. Request another Workspace opened Grow with MoolSocial; Back restored the existing approved Dashboard unchanged. | 228–234 |
| Statement | First tap opened the correct store statement. The compact period menu worked; Financial year remained readable and retained an honest empty result. No financial transaction was created. | 235–237 |
| Dues and settlement | Empty dues distinguished unpaid invoices from paid purchases retained in the statement. Zero-balance settlement showed readable adjustments and a disabled Review payout action (native enabled/clickable false); no payout was requested. | 238–239 |
| Customer orders and Stock | Orders showed zero active orders and reachable state filters/Create bill. Stock opened the empty store catalogue plus shared-catalogue suggestions. These are empty-state entry checks, not populated order execution, simultaneous-order capacity or large-amount qualification. | 240–241 |
| Counter bill and customer phone | Sell opened the blank bill directly. Add customer opened a compact native sheet; entering 123 and confirming kept the full ten-digit correction visible above the numeric keyboard. Close returned to the unchanged zero-item bill without accepting the invalid customer or creating an invoice. | 242–246 |
| Restock store context | Restock opened existing Wholesale/Bulk with Store purchase and the exact store identity, preserving the store perimeter. Android Back actually returned to Dashboard, not Sell. Capture 248's filename describes the attempted origin, not a passing exact-Sell return assertion. No populated bill draft was used; exact draft/origin restoration remains unqualified. Wholesale/Bulk content is provisional pending the separate Cursor lineage and is excluded from the product-content verdict. | 247–248 |
| Buy Direct and Group Bulk Buying | Direct-buy entry retained store context and listed the available manufacturer source data. Group buying showed an honest empty state without invented deadlines/commitments. No product, commitment or payment was selected. | 249–250 |
| Store link and promotion | Private/unconfigured store-link action explained why sharing was unavailable and opened no external app. Promotion exposed no fabricated public product or opted-in audience; Publish remained disabled. No campaign was sent. | 251–252 |
| Post requirement | Compact native selector showed the ten existing categories above Android navigation; Product sourcing opened the relevant form with the saved postal PIN and Not posted state. No requirement fields or publication were submitted. | 253–254 |
| Alerts and setup return | The one setup alert matched the current store. Continue opened this store's setup; Android Back returned to Alerts. No product, fulfilment, price or open/public setting was changed. | 255–257 |
| Profile and store settings | Profile showed the current active workspace. Operations opened Store tools and Store settings. Settings displayed existing Off/private state, capacity and hours; no Save or toggle was used. Android Back from settings actually returned to Dashboard, not Store tools; no assertion of exact intermediate-panel restoration is made. | 258–261 |
| Inline Search and keyboard | Search stayed in the header; focus made room for the keyboard by hiding operating controls. A no-match query showed a clear empty result, Clear restored empty search, and Finish search restored the dashboard controls without changing store data. | 262–265 |
| Final ordinary background return | HOME and normal foreground return preserved the same Dashboard and Off/private, zero-setup state. No force-stop, reinstall, account switch or server refresh is claimed. | 266 |

Images 238, 240 and 263 were re-opened individually after a combined read-only display exceeded the output budget; no device action was repeated. The support and final-dashboard images were also inspected directly. A retained-log read restricted to this runtime PID contained 129 lines and zero matches for the checked fatal/unhandled/RenderFlex/error signatures. That limited log window is not a full-session or absence-of-crashes guarantee; no full raw diagnostic log artifact was created in this evidence-only scope.

### Findings and approval disposition

- **Open frontend finding OPPO-S03-02:** the earlier malformed phone/email Continue guidance still requires its bounded correction. No actual OTP authentication bypass was observed.
- **New open frontend child OPPO-S07-04 / R6610-SUPPORT-DRAFT-SCOPE-01:** old application support draft under the new application's correct header. Detailed reproduction, owner assessment and acceptance criteria immediately follow this checkpoint.
- No additional confirmed defect in the exercised pending/clarification snapshot and local correction, rejection-reason display, direct approved entry, workspace switching, status, empty-state first taps, customer-phone validation or inline-search controls at OPPO font scale 1.0. Do not extend this result to the two open findings, untested populated states or genuine backend behavior.
- Founder visual approval through Dashboard is retained, conditional on technical defects being fixed. First-tap tests above are bounded technical evidence, not blanket founder approval for all destination designs or all subsequent actions.
- Earlier native observations and historical failures remain preserved below. This checkpoint does not silently close pending application re-entry after process death, account isolation, physical 200%/TalkBack, camera/gallery/cloud completion, other business-type journeys, or remaining file/error variants.

### Backend readiness — extend existing tickets, do not create duplicate frameworks

These are registered acceptance extensions to existing parents, not new service implementation and not production passes from a fixture:

| Existing parent / boundary | Required implementation or verification before production acceptance |
| --- | --- |
| OPPO-S03-01 — contact verification | Await authenticated server outcomes; distinguish wrong/expired code, throttling and unavailable transport without inventing success. Preserve changed-value verification invalidation and account-scoped resumable details. No live OTP was requested in this continuation. |
| OPPO-S07-01 — pending application / authoritative review | Bind every refresh to the signed-in account, exact application and monotonic server decision revision. Preserve acknowledged details across stale/out-of-order responses, offline retry, background/relaunch and another active workspace. Publish the 24-working-hour expectation only with an operationally supported review process; no actual SLA was measured here. |
| OPPO-S07-02 / OPPO-S07-03 — clarification draft and resubmission | Native local draft/snapshot separation and same-reference acknowledgement passed. Production is still blocked: work_services.dart AuthenticatedWorkGateway.submitCorrection currently explicitly reports unavailable, and the inline correction controls are review-gateway restricted. A bounded frontend-to-authenticated-service completion must preserve exact application, revision, document ownership, idempotency and the acknowledged snapshot; only a real acknowledgement may return the case to pending. Retry/network uncertainty must not lose corrections or create another application. Fixture success does not close this dependency. |
| OPPO-S07-04 — review communications and contextual support | Real admin status delivery through configured, consented MoolSocial Chat/WhatsApp/email/call channels remains pending. Return the supplied customer-safe reason, not internal risk notes. Bind support draft and attachments to the same account/application; the newly confirmed native draft mismatch is the frontend child below, separate from notification delivery. No notification/message was sent. |
| OPPO-S08-01 — decision and workspace access | Only authoritative approval may unlock the account-scoped workspace. Clarification and rejection must retain exact readable reasons and permitted actions; unavailable reasons must remain honest. Approved entry must go directly to Dashboard while public visibility/order availability remain independently controlled. Verify revoked/stale decisions and cross-workspace authorization; debug scenario selection is not production approval evidence. |
| Existing document-upload boundary | Confirm server-side ownership, allowed size/type/content checks and immutable submitted proof references; retain draft/retry behavior through failed uploads and review corrections. Local PDF/image preview is not proof of secure storage, PAN/business matching or live document review. No additional identity-verification vendor is introduced. |
| Existing Store/Buy/collection dependencies | Live catalogue facts, purchase/order events, payments/settlement authority, public-store link and post-sign-in resumption, delivery/capacity updates, consented invoice sharing/publication and customer collection authorization remain tracked production dependencies. This empty-store first-tap pass cannot qualify them. Preserve the existing versioned collection contract and Cursor-owned consumer work; do not create local-success handover/payment bypasses. |

No backend infrastructure, shared contract, product/test source, registry, policy, build, APK, Cursor or Redmi change was made. No real OTP, admin approval, payment, invoice, public link/share, publication or message was triggered. Existing user-edited support work and all original QA/evidence files were preserved.

### Standing-review capture hashes

148 new PNG/XML rows, 193–266. Full 001–266 inventory: 532 rows; canonical UTF-8/no-BOM LF-terminated SHA-256 27A8C592AA3FF00F2C1C8C2DB23AD64C71FF494A6226A0BD8D4EC9B7901550AF.

```text
06160D97D0A5D113FFC7D63FCF053D12BEBE8B2991496D3F25126802E8716329  r6610-native-193-standing-approval-review-checkpoint.png
3A56BE1C2C5E629A1A74F0F1AB1A348AA625542D268B6923530638F59EC4E8BC  r6610-native-193-standing-approval-review-checkpoint.xml
A1690E3C58128E53C85B7818573C7918DD0401669892E08C1CE047870BF320C0  r6610-native-194-review-declaration-ready.png
0676916943BEDCEBE9BA1C6C8507D7B6BEC793D7C4DAC477F7844AFEDCC1081E  r6610-native-194-review-declaration-ready.xml
250B4B5E561E75704E5ECA87E1749297C6E74F5FDD88D8AA3ACD8DDC597B478E  r6610-native-195-review-local-declaration-confirmed.png
BB59DAE3895CA6D9F131C81BAC3C2D0B536B3C9884789A5C4C9A04EA456F90E7  r6610-native-195-review-local-declaration-confirmed.xml
7BA302B0F426478E64C18428497D4EE76D5E75F1BDEC602FFBECA1A806978A64  r6610-native-196-application-received-standing-review.png
43F8F6CC260ACEF970A965EB5F725F5FC443937CEAF4EEF4A5C2991B8A57720F  r6610-native-196-application-received-standing-review.xml
AAAC633949B3C3AC2955167A6A2D4E478E1745D040B6631445F356520D0094D0  r6610-native-197-pending-reference-expanded.png
9ADBDC6C3DBDD944A1949DB7185214A931AD98844770FACBD339A113647DDB96  r6610-native-197-pending-reference-expanded.xml
20A8DE6AA8BACFAD0CD8916B8035B545487B8B3DFF698D4CE870CF7C7A8AA81E  r6610-native-198-pending-background-return.png
9ADBDC6C3DBDD944A1949DB7185214A931AD98844770FACBD339A113647DDB96  r6610-native-198-pending-background-return.xml
FC1A8FE2D923A53BFA51C6F87636635501137AD010315EBC985C889C5B8923B5  r6610-native-199-pending-reference-collapsed.png
43F8F6CC260ACEF970A965EB5F725F5FC443937CEAF4EEF4A5C2991B8A57720F  r6610-native-199-pending-reference-collapsed.xml
53F7BC50041616A9FF2946DF9A2926C768468D1056E38CCCBFD44987EA85AE83  r6610-native-200-review-only-scenario-chooser.png
BA390DDED0610F870A21FB58DCAF859689818852CC019097AF722E8E3F7578A9  r6610-native-200-review-only-scenario-chooser.xml
D1C77372EDFCD096DF5110EF5B7ED4456DF7CAECAEF6CE60E3B48AA732A6CEE5  r6610-native-201-clarification-standing-review.png
18FA585FEED18084750BFE50D370C2B90134C510E0E8AA29827BB42748F885EC  r6610-native-201-clarification-standing-review.xml
B6B0EEEAA4DDA3316067035FDB1C2FDF3142D4A86C121684697A54DFCC8057A1  r6610-native-202-clarification-document-correction-entry.png
06D7D2215CF4D95FB2AFDADB086A234B2B9B3DE2B433B61ABFDCA63D09F9D28D  r6610-native-202-clarification-document-correction-entry.xml
01461727A625754862FDDBE79BBF8CE696E3F48D7CF915BE8D122698AB39A14F  r6610-native-203-clarification-address-slot.png
558423E06AC128EF770221F25F1E971F4116C85CD94E8D4BEBEEEA83D72E5F0C  r6610-native-203-clarification-address-slot.xml
3F41084A33D23B13C8758DEB3045C0D9D7785628574D6C05DEE55405F2A4C98C  r6610-native-204-clarification-address-source-chooser.png
CA4531DF0905251FB44FD6A56F3C7C35311F8E6BA0DFC90B3A2438AC464616FD  r6610-native-204-clarification-address-source-chooser.xml
C0390CAE3648FB918745D14397CD449B6A9FD0A8F21CC3C6E1C48279B03A9444  r6610-native-205-clarification-native-qa-picker.png
98611B0C24415298E6C8EA766D68293B8B1F9E431755AE7282FEB72D641A3371  r6610-native-205-clarification-native-qa-picker.xml
F112784851F0A67851C24AF83613BFBF4F8E396BDDA3E650704A0DC7D18B6318  r6610-native-206-clarification-address-qa-attached.png
573B9F9B38017DD2D2BFC03C97E14322780CC4269C7B6EF8637ABA5FB7235D76  r6610-native-206-clarification-address-qa-attached.xml
CA7A7AB7433A7B317097EAEDD461A148F5BA5498D5793AFE44C4289D8AF9EA21  r6610-native-207-clarification-unsent-document-return.png
6522048D3FB9F5CB876E29E9372F55E21BC31026B5EFE5A194C9E08EF6EE35B9  r6610-native-207-clarification-unsent-document-return.xml
4F5DC7E3B410D7D2094F919055304A1DC754C421E1F6F512E83EBE05C939D2DB  r6610-native-208-clarification-review-two-attachments.png
BD4DCEB814385CACD6B428D6CECF85322F55D7D8C88EDDB32B32F2AF756E7801  r6610-native-208-clarification-review-two-attachments.xml
6A7BD922AA4C812372FEBF5DAB70A24390B308B871892EA3A9CF44CC9213CD76  r6610-native-209-correction-review-document-details.png
2E968351D936CCA6BA1ABB7136096558409D8359D089DC6187B1164200C84E34  r6610-native-209-correction-review-document-details.xml
3A18B1232B3FE1670807664518512A75186ED96DFAAD3BAFCA7C1DFF1D16B737  r6610-native-210-correction-address-pdf-preview.png
E6DBA6EC785400134BBD86660B9EC2C97FAD28574940D25930D1ED3362A362B7  r6610-native-210-correction-address-pdf-preview.xml
D71DC2B51C750AA5758C473DAF6353A7F1208B042894840B574E873878A9A580  r6610-native-211-correction-pdf-back-review.png
2E968351D936CCA6BA1ABB7136096558409D8359D089DC6187B1164200C84E34  r6610-native-211-correction-pdf-back-review.xml
DE1C8246D32C1E4B3A997F28759DC79D0A61E2830949DD9F6A4BFB976F8DEA42  r6610-native-212-correction-authorisation-image-preview.png
11FEED99342D49DDA2D2F7700315B68913C2EAD99781B7ECE1BB9360E8A8C4A0  r6610-native-212-correction-authorisation-image-preview.xml
1F26122FDA11D160FD40183C14465D81B093AA7D82C29563B7ABB0C2E94ED3B0  r6610-native-213-correction-declaration-before-resubmit.png
3CD58CB5574E17417E258CF142EBA4B25764B7B7FB1D9D3B4095916332DE618A  r6610-native-213-correction-declaration-before-resubmit.xml
65F51C814A8FF8FB9E510057B2E74A9243454E0D8730D82B4EAEC7B946B63E44  r6610-native-214-correction-local-confirmation.png
78137C60B5049A315B4E05775EB72EB258DBA17898D53F97C39DC29FB1C0DCEB  r6610-native-214-correction-local-confirmation.xml
681CB0757132D0FA7C90C65364139E1155E514BF994B7C8F0D96CD907C136705  r6610-native-215-corrections-resubmitted-state.png
09C5F760DAF2816253A5177376BA7601E6A6A1B58FEC61FBE4616B073582F4A9  r6610-native-215-corrections-resubmitted-state.xml
EC4EA7B819313DB77592B8D8ED009F3BFE72C90F0F381EB7DD9B34731095D975  r6610-native-216-correction-same-application-reference.png
BB130C7E188C3101CAF8ADDE6758D5CF266100C1959364466C5D8A7A2C02C496  r6610-native-216-correction-same-application-reference.xml
9BBA04773F6216651801FC9CD1E16E4834F0140AC529C542E233B4EDCD6200FA  r6610-native-217-corrected-pending-status.png
09C5F760DAF2816253A5177376BA7601E6A6A1B58FEC61FBE4616B073582F4A9  r6610-native-217-corrected-pending-status.xml
4D12579BA6B9D3DAA69B6F3B1F51E328A7B8BACB5F1D8F65647E66BA729D4487  r6610-native-218-review-only-rejection-selector.png
37032F10F90AB3D6FD7A7138B66934EF422E615ED19B78E770BA457D4C20261C  r6610-native-218-review-only-rejection-selector.xml
7C4A1F3786774BCAAB1F273A9987074EC706D7CCA5D6BEBD3655F5E8125BA4CE  r6610-native-219-rejection-reason-standing-review.png
7C9A93D0D76AEDC7D22DE2651312EC8FBD2F729E3645591D462FC2F828C88ED5  r6610-native-219-rejection-reason-standing-review.xml
D460C2DB5F191837B466E7EFFF7F3B44466B50D0A01CF2DE05290AFC7CC7641B  r6610-native-220-rejection-support-unsent-context.png
AB10C06549097AE3B392FC62405540A61DDB5F2D7C4B26B02F7677F1DD50E6D4  r6610-native-220-rejection-support-unsent-context.xml
D257B41D17FC85FE7444496585E7AD92B21D81DDF20BD5B8577AA311F4FAE235  r6610-native-221-support-draft-keyboard-context-mismatch.png
38B5E7A7056E8CB07DB75D310B52D5B5D3677BA5F5694C60E9845478BE811AC3  r6610-native-221-support-draft-keyboard-context-mismatch.xml
686A74BC19C9513730246F5B9462EE5FAF760CD8F9E23ADB91C9C16B0972CF6B  r6610-native-222-support-keyboard-dismissed-no-send.png
ED41C84B0039127407C391B8123F79F2E7EAFEAED1BD816A3C6EADF139C18F89  r6610-native-222-support-keyboard-dismissed-no-send.xml
78EF5093DDB641097E7CEE50F138CB29F0F01D1CA01A3ACBE36882DABD3AA6D7  r6610-native-223-support-back-exact-rejected-application.png
42E9E33E74438F081642C14F667BC0F358706A1E026D1497DE0B11D6380BC9D5  r6610-native-223-support-back-exact-rejected-application.xml
A048486C28D8BF42B13BCD0046F8C80A8521F69887DACCBC9EF9ECE7E2E0EECF  r6610-native-224-review-only-approval-selector.png
BA390DDED0610F870A21FB58DCAF859689818852CC019097AF722E8E3F7578A9  r6610-native-224-review-only-approval-selector.xml
52A6ACDC1C0A6173829384D506D7D2A6BB33252EB7D9E873B0097C1E29C90343  r6610-native-225-approved-direct-dashboard.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-225-approved-direct-dashboard.xml
9B3C82361647DE8176717979E3EA762F29213BEF24E62BFA18AD2705627E0596  r6610-native-226-dashboard-inert-status-popover.png
54ADE9420B19AA8E3F89C1872F3F8A8ED6244FDE06A141193AB0251561EB8FF7  r6610-native-226-dashboard-inert-status-popover.xml
6F32F71E1B4F2668C67F40DCEF7813BEB049200750E2559FD994EF484957306C  r6610-native-227-status-dismissal-no-mutation.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-227-status-dismissal-no-mutation.xml
00E32B9A633CB9481D0C5129182BC78A8598F75C75CA7AD0CACAA3EFD2F539D8  r6610-native-228-approved-workspace-switcher.png
7635514BE4B2AF420F089E3CE5DA24DD35C14006A648B0562210681EFF16E2E1  r6610-native-228-approved-workspace-switcher.xml
55E77B068204D165AEBCEB09F890B9948FBE5DF74F60E22759A031296ED934EB  r6610-native-229-switch-existing-approved-store.png
F55D50C5507F06D0EFC9BBA7463C27191B9392F87FC14067B7020494EC549A0C  r6610-native-229-switch-existing-approved-store.xml
190930E9ED692B795E5D0AAAEFA5A2AA1A07B92449A53C84297C23415A2B71B3  r6610-native-230-workspace-switcher-old-selection.png
D0794019417F19D6C5D0188C9F373BC7F90B7FC1A676EA4270539936D8CAE2F3  r6610-native-230-workspace-switcher-old-selection.xml
AA7FDA72D7F071348186437B2FB5BEFDC83E41CBD7BBD879BF441CE8584736CD  r6610-native-231-switch-back-new-approved-store.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-231-switch-back-new-approved-store.xml
6DA5460C49B812EB6E4F7E77B6CE5BE2CC901DA374CA9A58DA514849C2F58832  r6610-native-232-new-workspace-request-entry.png
7635514BE4B2AF420F089E3CE5DA24DD35C14006A648B0562210681EFF16E2E1  r6610-native-232-new-workspace-request-entry.xml
FDFC6257034F4007B10384743456BE6696EEEE68F7833236072F11C9596C58A9  r6610-native-233-new-workspace-selector-no-existing-card.png
1D6EA98AE74086D6EE529F3BB0A0BF8010B04CF40CAFF19976CD9C975E8CC42A  r6610-native-233-new-workspace-selector-no-existing-card.xml
54A7F885274B55DEA0D0F608849168A600C05FF405EB3DF2B15055452124FC38  r6610-native-234-new-workspace-back-approved-dashboard.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-234-new-workspace-back-approved-dashboard.xml
E5A787EB9110209BF03E0A6C99F94052DC109F9CA2B6618BECBE1655D60EBA31  r6610-native-235-dashboard-statement-first-tap.png
08D4E8FD360F439A97D3D2E84ED24771879640776124C21A75183CC7B963A8E1  r6610-native-235-dashboard-statement-first-tap.xml
07C536C2FAEBFA699E394991D7925A623CEA07E7EE64F109F863A8144EE71498  r6610-native-236-statement-period-selector.png
52773F63544CC9D2CB80AE86E1402D56A3F89C87F7CBE5EF88871D974C1B6E3B  r6610-native-236-statement-period-selector.xml
EA730D3965112DDDC77036D9C69688B1701E6EC13F91A4693BC0509C05BCA077  r6610-native-237-statement-financial-year-selected.png
00C4BBCD533D3F36C22B2AFF2C0E19B55A12A1A6B5E7924CEA28E53D072640FE  r6610-native-237-statement-financial-year-selected.xml
81ECC412C041E29D9EFF2E6BF8BDE3DD810A7BDF6211C393513BAE76EF00B0C2  r6610-native-238-dashboard-dues-first-tap.png
B6E87D3FE1E52E54577030A7CE96F289E2232657F87D1311EDF8096281BD848C  r6610-native-238-dashboard-dues-first-tap.xml
B3ABA2D8BE076D9DBA500975E14E7E10913D28A2933784BA709B066B812E578E  r6610-native-239-dashboard-settlement-first-tap.png
BF1FD492C37E786133F7D0244BD20BCACB365FF380E0497073CF67A1316427CC  r6610-native-239-dashboard-settlement-first-tap.xml
2E50FC364B0860328BF3D8B3BFC950ECA8897CA6CA5ADCB781D5A8E7BD6B8B8F  r6610-native-240-dashboard-orders-first-tap.png
CB2775206FA86D6AB9C6EAE255C68FB658FEA1124AA3C0B5EF41279D7F6FF5C7  r6610-native-240-dashboard-orders-first-tap.xml
54537BE0E7F7CA425CA5E82E990B9D93EAFFC32064C553BEC090DA224AFFA8EC  r6610-native-241-dashboard-stock-first-tap.png
E36A73924CF68000FF6359E91C3CE783A31D8CFFEC2F68FAE4068E461B3179A4  r6610-native-241-dashboard-stock-first-tap.xml
F4DAC2190CB1D91E906A24C4C704098A9E1C9C30377707E249655E18351CD790  r6610-native-242-dashboard-sell-first-tap.png
C3A187001909C9D56CE676CDD330EF323236CC5A769252FEFAA6CB0B71D977CD  r6610-native-242-dashboard-sell-first-tap.xml
423F63540F353529EF31F9A1949B102C7DFBEA8BB23D4715EAEA71632AE5C26F  r6610-native-243-sell-customer-sheet.png
C5B6B42560C24FDB805BBA6F76BC64258F3F74DBBBB71FAE69943FCAA2A06E5B  r6610-native-243-sell-customer-sheet.xml
01473CD7D32F9254ABF9DFFE889A2C69BF062EC52162338E5104A5AD601D9EC2  r6610-native-244-customer-phone-keyboard-invalid-input.png
1A33629E10726EC5938D2A77AED80E995E3628A496041A1EA6C7EA77D6AD25EC  r6610-native-244-customer-phone-keyboard-invalid-input.xml
9A7BF2295D40B4284F8DCC920CBBA90DFE964A462995ACDD359D7980108981A9  r6610-native-245-customer-phone-validation-keyboard-safe.png
D88AFAE7F4B35148BB3B364FF23D18595BB7ABB82A96A82DD86B0ABF5FE25119  r6610-native-245-customer-phone-validation-keyboard-safe.xml
400C838938E464D22C69364013A43EC11BB57852EAA468ACE757BBC058824CDD  r6610-native-246-customer-cancel-bill-unchanged.png
C3A187001909C9D56CE676CDD330EF323236CC5A769252FEFAA6CB0B71D977CD  r6610-native-246-customer-cancel-bill-unchanged.xml
AE35F3448218A15CAC06A3D46C95FBCDB3EAA70797676119DC09CDD769EE2DB1  r6610-native-247-store-restock-first-tap.png
6376BB61242DBA59053529277FC8761935004B0681F0362871EB2116BD74DDE0  r6610-native-247-store-restock-first-tap.xml
888B41008173D89A7A5F6B571C60B09582D32B91A31F640C21C30D47677AA0F7  r6610-native-248-restock-back-origin-sell.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-248-restock-back-origin-sell.xml
827640C763385014C7B1029B5BA2B2F676F6D501586E1514113BBD9A2FFEC36E  r6610-native-249-dashboard-buy-direct-first-tap.png
3DAEBE12FA7041DD424108468B55972545E213963C1586819E0FC6F56069701A  r6610-native-249-dashboard-buy-direct-first-tap.xml
62962633859BDFBB975DE096947E703A47E5501CE61D16F2DDB57EFEA238CA9D  r6610-native-250-dashboard-group-bulk-first-tap.png
966F6B71804BB238E3B0860EBE8B10E694BA4CED2690A9D0B25E9DD5E39D42E3  r6610-native-250-dashboard-group-bulk-first-tap.xml
354CBAFB5D72005225752BD35ECBF436CCCD68659A796A3A6C92BEAC4E8921E4  r6610-native-251-private-store-link-first-tap.png
12E849ABDC691D7E5630F6C2C0196C78ACB6FAF206DFE6B699F3A52CA9FA4AA6  r6610-native-251-private-store-link-first-tap.xml
09CBEB4BC47F9EEC43A4E8C0BA421D431E362A6663E07ADFF1560ADC2BA44B9D  r6610-native-252-dashboard-promote-first-tap.png
A1E056D6AF6015228D9B369CD8C6D43DD337323543A3815EDA121EEBB1D7C48A  r6610-native-252-dashboard-promote-first-tap.xml
02FC5E92710B3E7E628F522547130B4DEF63EFE8DB307F7E684558D314218518  r6610-native-253-dashboard-requirement-first-tap.png
BD3E7EC8EC48D874354116187E1AE1A7D5844F0C18B0AB6A47AFFEDDF7935CD1  r6610-native-253-dashboard-requirement-first-tap.xml
EAE4F17E57AA8C669C3EFB3ABC2343DC2E201C08881BFEADC18C357931F29A8F  r6610-native-254-requirement-product-sourcing-form.png
2ED231FFFDB164CCFC2FC1F4841E8F974BA81A9118D97FE11711B972C1C1A852  r6610-native-254-requirement-product-sourcing-form.xml
06C9CDCB20E36F19D45D80C4F16DE050B3905E525517D778C0DF309F37BBFB6A  r6610-native-255-dashboard-alerts-first-tap.png
BE0D379DB38CB3066276622B5137C982E6D418706AC9D6E7693A18D47D703E87  r6610-native-255-dashboard-alerts-first-tap.xml
E487DE47FBBB781CBFC1A929912681FA96213B9012E8945DE8D7E0664BBB3A0C  r6610-native-256-alert-store-setup-destination.png
F275769989D88C983ECC95B6CBFEC981DBE8C5EEAC159754BBAB5B087F9D53E3  r6610-native-256-alert-store-setup-destination.xml
63CB0C658C1962573AC9D48C5BA51BB50A13B8E081A09B0BD456B4565BC0951E  r6610-native-257-setup-back-without-publication.png
BE0D379DB38CB3066276622B5137C982E6D418706AC9D6E7693A18D47D703E87  r6610-native-257-setup-back-without-publication.xml
5E7A932233A6DD59B5AB60694FD0EB27770A43FF05B0370B47AB15336B00C57A  r6610-native-258-dashboard-profile-first-tap.png
D140A53034DF636F2773E51DB537191BD6C03267D82190D298C341DF73E94E2B  r6610-native-258-dashboard-profile-first-tap.xml
71A01084B5D86E089A57F56616180095940C7220A096F63971A48E9157A85B0A  r6610-native-259-profile-operations-destination.png
A0746BA6DD2B1DC398B5C671C7825B3BB992C7C46D4FF2479D5D3A7ECD395BBD  r6610-native-259-profile-operations-destination.xml
92FA2B3216269AB53257AC0DF5752C24C619923D8ED9F144CA357EF598E433D1  r6610-native-260-contextual-store-settings.png
6847ADBCA0B091B99AB43937A8DC7D6B0531ACC6282EF487FFAC996E972B6345  r6610-native-260-contextual-store-settings.xml
C067C530D928FEDA246B787A79F28B7604F9104F0DE5F4628BCC1D79C3F174AD  r6610-native-261-settings-back-no-save.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-261-settings-back-no-save.xml
B9EEEEE945FDA2C224FE1766AF68F4080FF311017440541F8A885CF75062C688  r6610-native-262-dashboard-inline-search-keyboard.png
433E530A39A9AD60544A6A9EA05A9F05A8D037445D030F81665537F2FA6AD3F0  r6610-native-262-dashboard-inline-search-keyboard.xml
56ECD0EDC2C6260049FB435DE49A7C46CE374200EB451B5F9AF1ED7677648C9E  r6610-native-263-dashboard-search-empty-result.png
85809D1D9935DF097846F99CBD48B60D047B8A73B409BDC307CFEFA04A3AF3E8  r6610-native-263-dashboard-search-empty-result.xml
4D1C7B449201807164C59A22160E9336FC9C1B49DCF7E5D365AB6AA39A6382DA  r6610-native-264-dashboard-search-clear-recovery.png
433E530A39A9AD60544A6A9EA05A9F05A8D037445D030F81665537F2FA6AD3F0  r6610-native-264-dashboard-search-clear-recovery.xml
77D308A19BFB49BE7B8969DECA7A73AC615C673D1644BA1A3904141B66A8119E  r6610-native-265-dashboard-search-finish-restores-rails.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-265-dashboard-search-finish-restores-rails.xml
F408C998A38933A7EFA83DF328B86C5818DD320064B9696BE090E39063778927  r6610-native-266-dashboard-final-background-return.png
FAA3382B1956A84D9442A60F3E6F01E446988E3C01EC542D870F998CB7E77C35  r6610-native-266-dashboard-final-background-return.xml
```

## OPEN — OPPO-S07-04 / R6610-SUPPORT-DRAFT-SCOPE-01 — stale application in support draft

Status: confirmed native frontend context defect; registered 9 September 2026 before continuing the device journey. Priority P2. Parent is the existing application-support/communication requirement OPPO-S07-04; this is not a duplicate of backend notification delivery.

Reproduction: retain an unsent support draft for the earlier review application ending -1 (business Review Clarification QA2), then open Contact MoolSocial from the newly rejected OPPO Review Store application ending -2. Capture 219 is the correct rejected application. Capture 220 shows current application -2 in the contextual header, while the composer restores text requesting help for application -1 / the previous business. No message was sent, and the old draft was not discarded or edited. Exact full review-only references are retained in the native XML, not treated as real customer identifiers.

Source classification: chat_thread_screen.dart initState restores the thread draft before applying the route's initial draft. _applyInitialDraftIfEmpty refuses to replace nonempty text. _workspaceApplicationContext updates the header independently. chat_session.dart stores drafts by thread ID; both applications use workspace-support. This explains the observed mismatch without proving a sent-message or cross-account leak.

Required bounded correction: preserve intentional unsent work, but bind generated application-support drafts and attachment context to the authenticated session plus exact application identity. Switching applications must not silently present/send the previous application's generated request beneath the new header. Use exact-context restoration or an explicit safe draft-resolution action; do not indiscriminately overwrite user-edited drafts. Keep ordinary Chat, Buy contextual drafts and exact Back URI behavior unchanged.

Acceptance: two different same-type applications and businesses, empty/generated/user-edited drafts, repeat entry, Back/forward, account change, attachments, keyboard/large text and send-confirmation context; no external message required for local qualification. Verify existing Chat draft preservation regressions plus Workspace support routing. Shared Chat owner coordination is required before implementation if the exact owners are claimed elsewhere. This is review collection only; no source/test, backend, registry, policy, APK or Cursor change is made.

## Founder-paced screen 7 — Review and submit — 9 September 2026

Founder approved Documents subject to Codex finding no defect during OPPO real-user checks and directed that genuine issues be registered before advancing. Its bounded native attachment/navigation checks found no new confirmed defect; earlier document, accessibility and backend limitations remain open. Capture 164 preserves the approved Documents view; 165 enters Review, Step 3 of 3. Current OPPO foreground is Review and submit first view at 192, awaiting founder review. No application has been submitted in this screen-7 round.

Safety boundary: all changes were confined to the existing local review-gateway draft and explicitly named QA attachment. The declaration was temporarily selected at 170 solely to test reset after a draft change; Submit was never tapped while it was selected. Its final native checked state is false (175 and 191). The only Submit tap was the unchecked validation test at 167, which stayed on Review. No real identity document, OTP, account edit, external message, payment or admin approval was sent. The retained local contact confirmations do not qualify server OTP verification.

| Check | Actual result/evidence |
| --- | --- |
| Review summary and first view | 165/179/186/192: Step 3 of 3, selected Grocery/Kirana workspace, business/contact summary and section-specific Edit actions. Scrolling at 166 exposes the exact Authorization letter filename, Image/156 KB, View, Documents Edit and declaration. No source or design change was made to founder-approved screens. |
| Unchecked submission | 167: Submit for review does not advance without the declaration; the complete correction message is visible above the action. 169 retains that unresolved validation after attachment preview Back. This is not a server-submission or rejection test. |
| Attachment View/Back | 168 renders the exact QA PNG. Android Back at 169 restores Review, not a wrong step or generic document list. Embedded legacy UI inside the QA image is fixture content, not current product design. |
| Document Edit return | 171 opens Documents in edit mode with Save and return to review. 172 locates the same Authorization letter. Removing the local draft attachment at 173 and saving at 174 changes the summary to No documents added. You can add them later. No original file/evidence was deleted. |
| Declaration invalidation | Native hierarchy shows checked=true at 170 before editing. After removing the attachment and returning, 175 shows checked=false. Old approval is therefore not silently reused for the changed attachment draft in this exercised case. |
| Attachment restoration | 176/177 reopen the edit route and removed row. Restore succeeds at 178; Save and return at 179 restores 1 attached and the original filename in Review. The attachment and original QA file remain available. |
| Business Edit and keyboard | 180 opens the correctly prefilled Details step in edit mode. A temporary QA suffix is entered only in the fixture activity at 181; the focused text is visible above the keyboard. Android Back dismisses the keyboard and exposes Save and return (182), without abandoning the edit. |
| Correction reflected and restored | 183 shows the changed activity in Review; 184 reopens it with the change retained. 185 removes only the temporary suffix; 186 confirms the original Grocery retail activity in Review. Business name, area, relationship and attachment are preserved. |
| Contact Edit and Back | 187 opens the correct prefilled contact page, with the existing locally confirmed phone/email and Save and return. Android Back at 188 restores Review. No phone/email value is changed and no code is requested. |
| Contact Save return | 189 reopens Contact; unchanged Save and return at 190 restores Review, preserving the summary and attachment. This validates this in-session return path, not restart/account-switch persistence or production verification. |
| Final state | 191 confirms declaration unchecked after all edits. It is an intermediate scroll position, not the bottom-of-scroll limit; earlier 166/167 capture the full declaration/validation area. 192 returns to the top for founder review. Application received and decision states have not been entered in this round. |

No new confirmed defect in the exercised Review summary, attachment preview, unchecked-submit validation, edit/return, draft-reflection and document-change declaration-reset checks at OPPO 100%. The existing OPPO-S03-02 Contact validation-guidance continuation remains open; this successful Contact return does not close it. No duplicate defect ticket or blanket production-ready verdict is created.

Submission success/failure, duplicate-submit/retry, process-death/account-isolation recovery, long-data variants, physical 200%/TalkBack and live server-side authorization/document storage/review remain unqualified by this round. Local preview fixtures cannot prove production identity or approval controls. No production application is submitted to advance the founder review.

Capture-178 tool-output truncation was handled by read-only recovery: the existing PNG/XML pair and runtime foreground were verified before any further action; Restore was not repeated and no capture was overwritten. Source, tests, registry, policy, APK, Cursor and Redmi remain untouched.

### Screen 7 capture hashes

58 new PNG/XML rows, 164–192. Full 001–192 inventory: 384 rows; canonical UTF-8/no-BOM LF-terminated SHA-256 CBFC65D7B5718178C3AFEDA553F5830C294268BCF05117576302392FA3C96999.

```text
32DA48E62DBFFB30BB3AC5B2981731402BF75744AC8B41DD77508FA7704524DE  r6610-native-164-documents-founder-approved.png
A35E7092980EE2AAE2509CE928E55C50A0FD267430642AD3169D1953994D0961  r6610-native-164-documents-founder-approved.xml
7D1AD583EB780D84D1427090EF37562CCDCC1FB6C02E35258178CA1E876BA289  r6610-native-165-review-and-submit-first-view.png
A80C3E56A90E48B1EA8C80B4C105D003FFB6442A7D39C16CBFA6552BFB6DCFBF  r6610-native-165-review-and-submit-first-view.xml
DC17988FA7B8A437BF7264FEBD0BA81900208EB046ECDC42AC61156C55445830  r6610-native-166-review-attachment-and-declaration.png
A1999760C8E5511C0AAD2182E1E27754EC3E6443E30B3D28D485C5503D7DDF15  r6610-native-166-review-attachment-and-declaration.xml
A916ADE70681B4BB24267CDDCFAE53EA5F75931CCC193DA851E0F76C569CDCFD  r6610-native-167-review-unchecked-submission-blocked.png
F78E4983A286C5EBC91DA265E54B3649B572B2D53CA3792C3F20C40ADF0607AB  r6610-native-167-review-unchecked-submission-blocked.xml
240A4F4A575F7B388FFD4D15D72A3F8AA110C103D71695D25466CB64D2389F49  r6610-native-168-review-attachment-preview.png
11FEED99342D49DDA2D2F7700315B68913C2EAD99781B7ECE1BB9360E8A8C4A0  r6610-native-168-review-attachment-preview.xml
63ABB08F9D4B5E18A98F045B53C763804D8216DDE4F8BFCD2A78A2601F7A3B9D  r6610-native-169-preview-back-review.png
F78E4983A286C5EBC91DA265E54B3649B572B2D53CA3792C3F20C40ADF0607AB  r6610-native-169-preview-back-review.xml
75261DB9AA3EEDC50FAAA176E3A39FB5736F676FD6B0B567C2A43F41C07636D2  r6610-native-170-review-declaration-selected-no-submit.png
9F1EC1EB63D78AA8768C4AA0B03AEBB7A8E79A0169CA26D32C5195DE57F1AF16  r6610-native-170-review-declaration-selected-no-submit.xml
B318546093E1B3DCD6B59084F66AB3EC1F376A04DF61A153BB17370CC3FA55BC  r6610-native-171-review-edit-documents.png
F8514DE2EE5F1DEA5500AD217AF5CD097A85862FAE689A697FFCD98411DE8812  r6610-native-171-review-edit-documents.xml
E1369B4D4532CBDC2ACB7DE92D5380885512CF0D74089814019FE82DEDFA3D03  r6610-native-172-review-edit-attached-row.png
A6D6C5850808E2864F025EDF111D1BD50621EAE4D24BAA1B06D1973D4D141C5E  r6610-native-172-review-edit-attached-row.xml
42891BC05C2E4E7715FB74BD460CC1BD58F9852FDD83E1E08C5982F84A030A95  r6610-native-173-review-edit-document-removed.png
3CD1A0C3A9AE68775C152BD09CA0837DA3B83B88ACD8C85CA8055763468AABC3  r6610-native-173-review-edit-document-removed.xml
F62C695DE76CF4C4D0F23A0C765DA35547869ADE6DFF336EFA0CE1831DE52181  r6610-native-174-review-reflects-document-removal.png
5FA68B8AF9E39CD7A1BD35D31E87D2861FB496FB7A083F0AB9289879F31ACEA8  r6610-native-174-review-reflects-document-removal.xml
B6A423B3EA35DD28EC8373E8FC51DA09265DBDB6692850E87AB446AB4B4F1832  r6610-native-175-review-declaration-reset-after-edit.png
31BAF6AC2682D5775A06F2DB320FBE393163FFA8B8FA203B4E766E20B762285A  r6610-native-175-review-declaration-reset-after-edit.xml
150BEEAE66A43F45768C487BA313A89304449AE9DE086419F5A0616D3E945E3A  r6610-native-176-review-document-edit-return.png
F8514DE2EE5F1DEA5500AD217AF5CD097A85862FAE689A697FFCD98411DE8812  r6610-native-176-review-document-edit-return.xml
64F9D6A1C31B9B0908B410D007C9537BA7DF14DEB62CDD9DC4359043D68BEF74  r6610-native-177-review-restore-row.png
3CD1A0C3A9AE68775C152BD09CA0837DA3B83B88ACD8C85CA8055763468AABC3  r6610-native-177-review-restore-row.xml
427645F1D2DF6F4037043119B36C7CA6B862BA31A903045EB45DBC3714455F9B  r6610-native-178-review-test-attachment-restored.png
A6D6C5850808E2864F025EDF111D1BD50621EAE4D24BAA1B06D1973D4D141C5E  r6610-native-178-review-test-attachment-restored.xml
B8479F675D5D275C5FF8369B463E3E4AE39E32D369B78A2AB32CB70EDF5F664B  r6610-native-179-review-restored-attachment-summary.png
A80C3E56A90E48B1EA8C80B4C105D003FFB6442A7D39C16CBFA6552BFB6DCFBF  r6610-native-179-review-restored-attachment-summary.xml
8E4467A755A36EDA5972BF89FEE73829FD975F3EDD10E83F0B4ADDEC1C82B2F7  r6610-native-180-review-business-edit-prefill.png
35797432D80B94DD7A9469CFDEB0E52208AD57069F5D06AAF6E65414B0E065C3  r6610-native-180-review-business-edit-prefill.xml
565191968EC34A54DE96A778C0EC63EE4955757BD5BCCD2397AF950B07BD93ED  r6610-native-181-review-business-edit-keyboard.png
1704F3B9A0DC149302B4F3A8258D405C83AA82CDB6032717418322A9959E7B5B  r6610-native-181-review-business-edit-keyboard.xml
7329869FF58D9DD723CC955CA9E16D19AC700FE998DFA9F917911D776A3487C3  r6610-native-182-review-business-edit-keyboard-dismissed.png
F5EFF429607584EBC19993B19618EC3FE3F7843D9EBAF6C8AB3BDAC39877CB9E  r6610-native-182-review-business-edit-keyboard-dismissed.xml
0B52CDB454F42AC2C13951AB5E56C200F64E813557FBAE06A3A78DFD3A6EFBA6  r6610-native-183-review-business-correction-visible.png
9AF84B6EF098C7AE9A79E59AB0040A559AA3B2497D4DD4DF3D6EDA9516FA169F  r6610-native-183-review-business-correction-visible.xml
B3D009017ED45706FFC3742EF597DE46E1FD6D39BBECC4E38AC033A081026B25  r6610-native-184-review-business-correction-retained.png
3F5CA80BF95C585EBAA5D5FB4D47B401476B5400A573AF722D42C01C31309EBC  r6610-native-184-review-business-correction-retained.xml
84F28CEDA4A6BBFC87F507E9CAA321CE9D8B99AB9DD0B982852A601B1D455C3D  r6610-native-185-review-business-fixture-restored.png
F20B31427C629E5EFAE6CBE46E0ACD05A57A0BDABEA008FC955E75ABB21D5C64  r6610-native-185-review-business-fixture-restored.xml
763199B7AAE9D3E1CC8AA3D5E0C97D1AF90705E45A5D54FD265FE85E44CF6853  r6610-native-186-review-restored-business-summary.png
3A56BE1C2C5E629A1A74F0F1AB1A348AA625542D268B6923530638F59EC4E8BC  r6610-native-186-review-restored-business-summary.xml
58DD49BBE33F71984F4712DE297F78994F333FAE16B90E4B360849DEB172B053  r6610-native-187-review-contact-edit-return-contract.png
957BB8BC7E0D756E27FA0C11396A830DCD86F1EA11140BE18601AE32AF36340F  r6610-native-187-review-contact-edit-return-contract.xml
24E8EA986529970256776BA0F3876A731BF796EFB854EE3C563A75F8D6A0160C  r6610-native-188-review-contact-android-back.png
3A56BE1C2C5E629A1A74F0F1AB1A348AA625542D268B6923530638F59EC4E8BC  r6610-native-188-review-contact-android-back.xml
95C02067DCC7D584BCC115FE548D56338BD4E3F4DBC1709864338744CCA75D92  r6610-native-189-review-contact-save-prefill.png
957BB8BC7E0D756E27FA0C11396A830DCD86F1EA11140BE18601AE32AF36340F  r6610-native-189-review-contact-save-prefill.xml
9B5D0D23C9DAC22F23262B3D2B4DBF93B0C7D0681E2E188A7A24048B84C4499C  r6610-native-190-review-contact-save-return.png
3A56BE1C2C5E629A1A74F0F1AB1A348AA625542D268B6923530638F59EC4E8BC  r6610-native-190-review-contact-save-return.xml
81DC5100BD0002ABB8720A1F90D6C773570175AB5814EB87C58E1D1917306156  r6610-native-191-review-final-unchecked-declaration.png
7D6A7D991789F415A7040840A6147B9165EBF3AF9A34C255F1DB8CF437067D6F  r6610-native-191-review-final-unchecked-declaration.xml
F633D03460888AA164651BE0A1BB2E5B4111C0BE94A5BD3926685C932276238B  r6610-native-192-review-founder-first-view.png
3A56BE1C2C5E629A1A74F0F1AB1A348AA625542D268B6923530638F59EC4E8BC  r6610-native-192-review-founder-first-view.xml
```

## Founder-paced screen 6 — Documents — 9 September 2026

Founder approved Business details subject to Codex finding no defect in native testing and directed that genuine issues be registered before moving ahead. The bounded Details checks below found no new confirmed defect; physical/backend dependencies and the separate Contact validation-guidance finding remain open. Capture 133 preserves the approved Details screen, and 134 opens Documents, Step 2 of 3. Current OPPO foreground is Documents first view at 163, awaiting founder review.

Safety boundary: only the existing MoolSocial-QA-NOT-A-REAL-DOCUMENT-r665.pdf and .png fixtures were selected. The PDF explicitly says it is not an identity/bank document; the PNG is an old app screenshot serving as a file fixture. Its embedded legacy UI is not the current app's UI or a regression. No real identity, bank, authority or business document was selected; no application, external message, payment, real OTP or admin approval was submitted. The review gateway's local attachment acknowledgement does not qualify production upload/storage/verification.

| Check | Actual result/evidence |
| --- | --- |
| First view and document scope | 134/136/163: matching business subtitle, Step 2 of 3, concise format/size guidance and Review your information above native navigation. 137/140 expose the food-business, authorization, bank and GST slots by scrolling. |
| Optional attachments and boundary Back | 135: Review is reachable with no documents and states that none are added. No declaration or Submit is activated. Header Back at 136 returns to Documents; this is boundary testing, not founder approval of Review. |
| Source chooser | 138: Camera, Photo gallery, PDF or image, Cloud files and Cancel are visible. Exact slot is Authorization letter; format guidance lists PDF/JPG/JPEG/PNG/WebP and up to 10 MB. Full chooser/Cancel pixels were inspected above Android navigation. |
| Native PDF selection | 139 selects only the named QA PDF from Android DocumentsUI Downloads. 140 attaches it to Authorization letter, with the correct filename, View/Replace/Remove and row-local attached feedback. No oversized persistent success banner appears in the exercised states. |
| PDF content and paging | 141 renders the distinct QA page-1 marker; 142 renders page 2. Native semantics disable Previous on page 1 and Next on page 2. Reopening at 148 starts at page 1 with the same PDF. |
| Zoom/pan/Fit | 143 enlarges page 2; 144 pans it to expose the enlarged top content. 145 restores the fitted whole-page bounds. These observed touch interactions work without closing the document or switching attachment. |
| Preview Replace and cancellation | 146 opens the source chooser from the preview; Cancel at 147 returns to the same attached PDF row. Reopen/View at 148 and Close at 149 work. |
| Remove/Restore | 150 removes only the review-draft attachment and immediately offers Restore; 151 restores the same PDF and its actions. The original QA file and retained evidence are untouched. |
| Image replacement via Cloud files | 152–154: Cloud files opens Android DocumentsUI; only the named QA PNG in local Downloads is selected. It replaces the same Authorization letter slot. This proves the native provider-picker wiring/local selection, not a Google/Microsoft cloud download or account connection. |
| Image content and Back | 155 renders the selected QA image; Android Back at 156 returns to the correct row with the filename/actions retained. Actual pixels were inspected, with no attempt to interpret the embedded old screenshot as current UI. |
| Gallery cancellation | From chooser 157, Photo gallery opens com.google.android.photopicker/com.android.photopicker.PhotopickerGetContentActivity, confirmed by dumpsys foreground readback. No gallery photo is selected or inspected and no gallery-content screenshot is retained. Android Back returns to the source chooser at 158, not directly to the row; chooser Cancel at 159 returns to the unchanged PNG attachment. The 158 filename describes the test intent; its actual captured screen is the source chooser. |
| Draft retention and restored first view | 160 returns to Details with the business draft intact; 161 re-enters Documents at its top; 162 confirms the PNG remains in Authorization letter. 163 restores the first view. These are in-session checks, not process-death or account-isolation qualification. |

No new confirmed product defect in the PDF/image/chooser/cancellation/navigation interactions exercised at OPPO 100%. Existing R669-S05-FEEDBACK gains successful row-local-feedback replay; no duplicate defect or blanket document-ticket closure is created. A failed-upload or oversized/corrupt-document path was not exercised by these successful attachments.

Existing OPPO-S03-03 accessibility observation is retained, not duplicated: PDF/image footer controls appear fully above native navigation and respond to actual taps (Zoom/Fit/Close/Replace), but compressed hierarchy reports only y1412–1442 for those controls. This is not proof of a visually clipped or untappable button and not a TalkBack pass. Physical spoken focus/bounds and 200% testing remain pending.

Other pending document qualifications: camera capture; actual Gallery selection/return; remote cloud-provider download; all advertised format variants; oversized/corrupt/password-protected document recovery; actual upload/network failure and service recovery; relaunch/account-change isolation; production file authorization, content validation, storage and review status. Existing local source/tests may cover subsets, but this native round does not reclassify those cases as device-passed. No settings/security permission was changed and no account was opened for those deferred paths.

Picker timing was handled safely: immediate post-tap foreground remained MoolSocial for PDF/Cloud/Gallery; separate read-only foreground checks confirmed the native picker before interacting. No repeated launch tap or failed picker verdict was inferred from that transition. Source, tests, registry, policy, APK, Cursor and Redmi are untouched.

### Screen 6 capture hashes

62 new PNG/XML rows, 133–163. Full 001–163 inventory: 326 rows; canonical UTF-8/no-BOM LF-terminated SHA-256 11BA7E443F75EC196EB00880100FE4F16700A7C6EDFB9BA80D282BA0CD660B66.

```text
DE260FAB3A89C9ED287A5782FFA3745CCFB652FB41FEA523C93229E79AB297DA  r6610-native-133-business-founder-approved.png
A35D098FF7C8498FE8699FB456564425C81A537E6FA9BF02847CE42087D5B6D1  r6610-native-133-business-founder-approved.xml
2BAD88AA4C18B4786918B521A2E12B27FEB6EF2D2240AFB208D829DEC7816BD8  r6610-native-134-documents-first-view.png
DFD86AE6A8A6E50700D70A01F063C787A3178E5F917F310B55976ADF37120F35  r6610-native-134-documents-first-view.xml
FD4D53FF559132DF8C79D9B21C59C6E9DC699A89B5580F458A184DC64C067BEB  r6610-native-135-documents-optional-review-boundary.png
E4778D0FD97682F07688763BA9F80A27B2D0A5102FF05E87688CBB5A3780D3D5  r6610-native-135-documents-optional-review-boundary.xml
D69B4840AE40CD6AE01FA40FC858571B68CFA15BABE4D8037401323D56046F67  r6610-native-136-empty-review-back-documents.png
DFD86AE6A8A6E50700D70A01F063C787A3178E5F917F310B55976ADF37120F35  r6610-native-136-empty-review-back-documents.xml
3E256F262F5FEAF4CDBD2D311D66B1502A3083F11FE6AE889034E05761E8986A  r6610-native-137-document-list-authorisation-bank.png
02B2149E8F398A461610E12DCDB34465CD51C4D6FFEB39E93BAB430F4B68A2E6  r6610-native-137-document-list-authorisation-bank.xml
A7FF35964A93C40CEC9C62EC65ACEDE91D0D190F6F1F105EFF6F00DD89050112  r6610-native-138-document-source-chooser.png
0E0200CC26522CEBF059895096E62F540B940203E33239506713B17D8B3E9782  r6610-native-138-document-source-chooser.xml
BCE692D5C1EA63E5C7C5C4A97CEC0D555C802BD12C001450BA49B3C73F082485  r6610-native-139-android-pdf-picker.png
98611B0C24415298E6C8EA766D68293B8B1F9E431755AE7282FEB72D641A3371  r6610-native-139-android-pdf-picker.xml
1BD5FAAA315D6318EB1D2849CD40D7382525F8F1B51B2F58EF1BE7E37858A115  r6610-native-140-qa-pdf-attached.png
0F8A8ECB336CD5AE0F89FC458831A4080F978C45F912CD6FBE4B6BB5E5E607B9  r6610-native-140-qa-pdf-attached.xml
9D9C200E03F74F85BC852F10A886155445BFE92085851873CED316683A664CC8  r6610-native-141-pdf-first-page.png
490D12F52C551D4BD24A1255CB1B7B6A1274A50BBB15D97BC8523712C19B85E3  r6610-native-141-pdf-first-page.xml
378E8588A7E852E490ACE2625FF787A73BB59055BB7341C7FC01E2ACC01700DF  r6610-native-142-pdf-second-page.png
9AD0393290BB1E39FCC91224C752F5FC904736DBD973DFEAFCFE6EB97C1CB217  r6610-native-142-pdf-second-page.xml
ABCA8CDE1CCFBCDAA00C07927C2B01FCEB7F39A19FCA5F7E7A25EA15CFC61415  r6610-native-143-pdf-zoom.png
84BB5E13E8EC93400CA923B0B58D31D7376380BB1D697372181F41DDF185B2DA  r6610-native-143-pdf-zoom.xml
6621354ACA9F505D66A01D1764119E0DAB9ECA6E15912F75B12B64D0B0C9576F  r6610-native-144-pdf-zoomed-pan.png
84BB5E13E8EC93400CA923B0B58D31D7376380BB1D697372181F41DDF185B2DA  r6610-native-144-pdf-zoomed-pan.xml
A3C8EEAB94785757401A7D61D26B86F8A3293FD8D06AECCFAD333C15084DBF82  r6610-native-145-pdf-fit-restored.png
9AD0393290BB1E39FCC91224C752F5FC904736DBD973DFEAFCFE6EB97C1CB217  r6610-native-145-pdf-fit-restored.xml
FF24F72B794976BA1E0B1363E4B8D3D400ECE5B3ED3E093E099AB4D18FACE142  r6610-native-146-preview-replace-source-chooser.png
66DB888A24A2CFA23988A67FE7D7C576601B01CB71C6999D338D4E6F0E9B273F  r6610-native-146-preview-replace-source-chooser.xml
0E7C729AEC9D078B128B601D0E3F756A8413793CC261FE6724DFD7D91F981F90  r6610-native-147-replacement-cancel-preserves-pdf.png
0F8A8ECB336CD5AE0F89FC458831A4080F978C45F912CD6FBE4B6BB5E5E607B9  r6610-native-147-replacement-cancel-preserves-pdf.xml
04DF39E2B198ECB130D65D9A147818754EDC18F21C70013A05F045BAC24C5B0B  r6610-native-148-pdf-reopen-after-cancel.png
490D12F52C551D4BD24A1255CB1B7B6A1274A50BBB15D97BC8523712C19B85E3  r6610-native-148-pdf-reopen-after-cancel.xml
483CE735D9E77CE6B963B0EE2A1A94E93D9E1E35B1737BC99FACEAA5E8FF5482  r6610-native-149-pdf-close-same-document-row.png
0F8A8ECB336CD5AE0F89FC458831A4080F978C45F912CD6FBE4B6BB5E5E607B9  r6610-native-149-pdf-close-same-document-row.xml
A822E33917123D89619256ECEE25CC50F0F58E421F19E66CBF6554F65ED7DF11  r6610-native-150-pdf-removed-restore-available.png
CAA73982474038DE12BC19C773595B86B9BB49FB48F421855919C0E6D2B67ADE  r6610-native-150-pdf-removed-restore-available.xml
B715992FDF7B74888C9F1C2CE01A2E94A71E1F9390910E639EB2D51C668B02F0  r6610-native-151-pdf-restored.png
0F8A8ECB336CD5AE0F89FC458831A4080F978C45F912CD6FBE4B6BB5E5E607B9  r6610-native-151-pdf-restored.xml
DF181254FEC8BCB0333F5BBE2AD21ED594F0C8A703003A735D0F01088D9D363B  r6610-native-152-row-replace-source-chooser.png
66DB888A24A2CFA23988A67FE7D7C576601B01CB71C6999D338D4E6F0E9B273F  r6610-native-152-row-replace-source-chooser.xml
298A4A7F25ACF1728D4D0363E551802B21D2F9EB5FE19D973636986896DCCE41  r6610-native-153-cloud-files-native-picker.png
98611B0C24415298E6C8EA766D68293B8B1F9E431755AE7282FEB72D641A3371  r6610-native-153-cloud-files-native-picker.xml
D41B95C568C6A553C31E52FC58FE54C07A5D701554251915C52193394D33E608  r6610-native-154-qa-image-replaces-pdf.png
23B9E6D3E90852D332EC1C9BDA97F19156FF202F956B185559ADFB288AE07B9D  r6610-native-154-qa-image-replaces-pdf.xml
AC65D888D333B3C59070616B3677E86631A2A630728A2FC31FC704CBD4E05588  r6610-native-155-image-preview.png
11FEED99342D49DDA2D2F7700315B68913C2EAD99781B7ECE1BB9360E8A8C4A0  r6610-native-155-image-preview.xml
6C426A5640680AAE3A9D590290B30A933F217FE1496E1CD9F8EA8E7B5C69ACE7  r6610-native-156-image-back-same-row.png
23B9E6D3E90852D332EC1C9BDA97F19156FF202F956B185559ADFB288AE07B9D  r6610-native-156-image-back-same-row.xml
970CFBA2666CAD5C1A55A5C0903AAC83D5BC2017BFEA73A9FA44909EC4110594  r6610-native-157-image-replacement-chooser.png
66DB888A24A2CFA23988A67FE7D7C576601B01CB71C6999D338D4E6F0E9B273F  r6610-native-157-image-replacement-chooser.xml
46B393F7C565DE7B1E3EFB8FE0728E5288555837DF70C70D820F7C1341801208  r6610-native-158-gallery-cancel-preserves-image.png
66DB888A24A2CFA23988A67FE7D7C576601B01CB71C6999D338D4E6F0E9B273F  r6610-native-158-gallery-cancel-preserves-image.xml
F6E1988E47B2969579C5BED25072ED0F1812138ED69C830EE407DBAB9E3AEEB5  r6610-native-159-gallery-cancel-same-attachment.png
23B9E6D3E90852D332EC1C9BDA97F19156FF202F956B185559ADFB288AE07B9D  r6610-native-159-gallery-cancel-same-attachment.xml
458F13C9D58FEC3AB908641F6AB226F81D2D50E6F750D0F968C64CD2DE3C8914  r6610-native-160-documents-back-details-with-attachment.png
3BA33AFD9CB15598BF4728E5B6A3840B004EF6B2B9F0781DB60768B53FBFB419  r6610-native-160-documents-back-details-with-attachment.xml
8F78519B99F8FBC8FDFDAF76D27E03ECBB0D06C3ADEFA957B7186887FF046902  r6610-native-161-documents-reentry-top.png
A35E7092980EE2AAE2509CE928E55C50A0FD267430642AD3169D1953994D0961  r6610-native-161-documents-reentry-top.xml
6BF88CB5ED4AE4FC74F8D75F6189302FFA3A8204A51A23F37379CB297B425A16  r6610-native-162-document-attachment-retained-after-back.png
30EC91543B92435AE7527289C39E7AA6D44782E21C7FED26F9DF3DA6B843845F  r6610-native-162-document-attachment-retained-after-back.xml
684B12927DA8296880A2315EA93918AA3545B16B9E3CAD0F30E9EC44C3D3320B  r6610-native-163-documents-founder-review-first-view.png
A35E7092980EE2AAE2509CE928E55C50A0FD267430642AD3169D1953994D0961  r6610-native-163-documents-founder-review-first-view.xml
```

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
