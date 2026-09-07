# r66.5 OPPO review

## Current checkpoint: reachable onboarding audit completed; full journey qualification pending

This section supersedes the earlier limited-entry checkpoint below without deleting it. Installed r66.5/source91d9a9b8 remains unchanged. OPPO CPH2375/2b3e0f71,720x1612,density320,font1.0 was used with foreground checks before interaction. Founder confirmed exclusive phone use. Native camera/photo/file-picker activities were allowed only following the app's specific picker action; unrelated applications were not operated.

### Actual journey and results

| Segment | Exercised result | Boundary |
| --- | --- | --- |
| Pending application -> Back -> Workspace selector -> View | Exact pending case and attachment count returned (01..04) | Pending correctly has no dashboard/forward approval shortcut |
| Inline selector search | Keyboard, matching Grocery result, clear, no match (05..07,18) | Other18 business choices not individually qualified |
| Tell us what you do | Empty-submit guard, category/Other/activity/city input, keyboard, Cancel, reopen draft, valid fixture submit (08..17) |02/03 defects; production request sending not implemented |
| Grocery same-page introduction and prerequisites | Expand, Stock preview, Choose, scroll through bank/GST/document list (19..22,32..33) | Legal/GST authority not established by UI audit |
| Saved contacts and existing pending case | Authorised name/contact/email/backup prefill; keyboard; Continue returns pending case (23..26) | No fake dashboard approval |
| Process restart | Force-stop/start without data clearing; cold launch4734ms; Work re-entry (27..34) | Strings restored; review case/standalone confirmations not restored by this review fixture. Not proof of production data loss |
| Phone and code recovery | Short number rejected, corrected number clears error; invalid code rejected; valid fixture code confirms (35..41) | No actual SMS/email or production verification |
| Email/backup | Code field retained across keyboard Back; confirmation; unconfirmed backup guard; backup fixture confirmation (42..48) |05 focuses keyboard instead of confirmation action; live autofill pending |
| Business details | Prefill, relationship choices, keyboard, Continue, Documents Back (49..55) |04 prompt truncates;54 filename does not assert Documents entry—the captured page was still Details after a tap during keyboard transition;55 confirms actual entry |
| Native file selection and document preview | Selected only the named QA PNG; correct-slot receipt and exact-image View, Back (56..60) | Review gateway acknowledgement only; test file is not an identity document |
| Replacement/cancellation | Cloud/file picker, Photo picker and Camera opened; Back/Cancel retained original attachment (61..68) |62 XML capture failed and was recovered by63; no real cloud/PDF/gallery/photo completion |
| Camera controls | Native camera XML exposes shutter at[282,1276][438,1432] (66); Back returned safely | No camera image/surroundings were captured; this is not a completed photo-upload pass |
| Remove and Restore | Only QA attachment removed, stable Restore action restores exact file (69..70) | No founder source/evidence/document deleted |
| Review and edit | Declaration guard scrolls to correction; document/business Save-and-return and contact Back return to Review (71..78) | All three section routes work; accessibility announcement requires TalkBack verification |
| Workspace Chat | Inbox/thread, unsent draft, keyboard, Back, exact review return, reopen draft, discard only QA draft (79..89) | No message/call/media send; customer-facing copy/space findings07 |
| Submit -> pending | Declaration accepted in isolated fixture, local submission -> Application received (90..92) | No admin approval, real backend upload or outbound notification. Phone left on pending application |

All prior personal field values were kept out of textual findings. The QA PNG was an existing non-personal app screenshot copied as /sdcard/Download/MoolSocial-QA-NOT-A-REAL-DOCUMENT-r665.png (159350bytes); it remains available as a labelled test asset. It was not represented as PAN/Aadhaar/business evidence. The one new isolated submission contains that one test attachment. Only the QA unsent Chat draft was discarded.

### What was visually reviewed versus structurally captured

Directly inspected native PNGs:01,02,05,08,10,12,13,21,23,27,35,39,45,49,53,56,58,59,71,80,81,92. Other paired captures were checked through their native hierarchy and journey outcome, not all individually given a visual pass. The source non-personal screenshot used as the QA document was also inspected; it is not an r66.5 UI result.

Evidence totals:181 files =91 PNG +90 XML,14692225bytes. Sequence27 and62 have PNG only;66 has camera-controls XML only. All other01..92 sequences have paired files. PNG and XML are sequential snapshots and may differ during transient banners/keyboard motion; filenames do not by themselves establish successful actions. No200% capture exists.

### Findings, limitations and next qualified step

- Eight open findings AUDIT-R665-01..08 and five explicit service dependencies BE-01..05 are recorded in ticket-and-screen-coverage.md, with native/source evidence and retest requirements. Existing stale-opportunity and dashboard-review-entry blockers are reused, not duplicated.
- This is an audit/registration commit, not implementation or production qualification. No product/test source, runner/gate behaviour, APK, integration or Cursor/Redmi owner changed.
- Android rejected WRITE_SETTINGS for font_scale2.0; the readback remains1.0. Physical200% testing is pending, not failed or passed. No permission or security change was made.
- Recoverable tool incidents: capture35 files were recovered after prior tool output loss, and fresh36 verified the current phone field before another edit. Optional source searches included one absent legacy directory and a bounded history excerpt that truncated; missing content is not qualification evidence. Capture27 produced null-root XML output;62 produced no successful XML output. PNGs were preserved and new captures28/63 recovered state; no output was fabricated.
- Still untested/blocked: approved Dashboard and all first-tap operations, other business types, actual photo/gallery/PDF/cloud selection completion, physical large text/device matrix/TalkBack/reduced-motion, real contact OTP/autofill, admin clarification/rejection/approval, authoritative document storage and messaging/payment/collection services.
- Dashboard review needs an explicitly isolated approved review fixture or a genuinely authorised approved-Workspace response. Never bypass the pending/approval guard or call a fixture backend acceptance.

### Audit capture SHA-256 inventory

Files below are retained under artifacts/device/codex-oppo-r66-5-review-20260907, Git-ignored and hash-bound in this tracked record.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| r665-audit-01-current.png | 146031 | A12005FE9140AC17C40A41651C99FED11370B01466CB6407260317B67DBF10F2 |
| r665-audit-01-current.xml | 13884 | 84CB008F5AEB5ACC403B8A495120FD4F94B1D6D06E91ACB83E7623B4CF9EE4FA |
| r665-audit-02-status-back.png | 165299 | A63815B12146E515B6A2DC417C7D4DAEBF88C0615742F8879C798E24065AA7CD |
| r665-audit-02-status-back.xml | 11032 | CF149E2C4F0E74F99AB9FFEBEC132966794E9DF0DF76E0A20A607F19A90F5CE2 |
| r665-audit-03-review-return.png | 130205 | F7392F771DB2AAD90E1C0B906C0DA928D96BE89119C1BE7E89C7E37C601B4637 |
| r665-audit-03-review-return.xml | 13149 | 1EA29F04305A0D2F20551DD6D1D26DC1C303BB1A3FF2A42F883943610104414E |
| r665-audit-04-selector.png | 165234 | FFA5AF25FDDB0D730FC865418B86B733AC5948D6FBDD0A888FA6162B6E47C4AE |
| r665-audit-04-selector.xml | 11032 | CF149E2C4F0E74F99AB9FFEBEC132966794E9DF0DF76E0A20A607F19A90F5CE2 |
| r665-audit-05-search-keyboard.png | 155850 | 524BDAA660AC69D2F3A8979F12CCA07E1074C24089B9F1AC97506954D020C9A5 |
| r665-audit-05-search-keyboard.xml | 7745 | 133AD3F757E78670D078E0080754C0DBE3D3192B29869F06FA5EDF3E42B18340 |
| r665-audit-06-search-filtered.png | 157648 | 43211E55AE9F0C6E51B55783A79DD41156621DD8B952AF42436C573DF119F86B |
| r665-audit-06-search-filtered.xml | 8658 | 13CAF3DFC5D712EFC025F612485FDEF30C0A9C962C8CB8A0F66AE363D15C1ADC |
| r665-audit-07-search-empty.png | 151988 | FC13E3917E968CBFE6F02A9E353C41397295E250249D0537C94C827213FC33EB |
| r665-audit-07-search-empty.xml | 7939 | 7DC9B72C65D1B6FE7DD337A062D4DDF60EA60664CB522AAE7FC89C91735F6E09 |
| r665-audit-08-other-form.png | 130904 | F7D05C106CAB9BE17C03C8042EA6F86D5E1CEBFF9971AA2BF7CEDF046BC7B137 |
| r665-audit-08-other-form.xml | 7212 | 7110110A8C674DC45B92DA6BB5233EDA649CE1EA8944FB96367EA1F1FA34D2FB |
| r665-audit-09-other-validation.png | 125106 | 0BEAE21A04AD2418594848626ABC8CAEAB0FD5E012BB15F6D6FD0024F1585480 |
| r665-audit-09-other-validation.xml | 7577 | BC23221DCF0A6F40C28E51C175BB78F3C08B5DF80C3568E7D53B55791DCF1D67 |
| r665-audit-10-other-keyboard.png | 136864 | 294FBCB79D4324F85518FE425602C9D1F50AEE9C7C5BCE109B35EDAF66DD2A1B |
| r665-audit-10-other-keyboard.xml | 7571 | A3B416E2D4D83A2F20D5D02FEC8715CF3B94E943B85E60136D2EA8F1E08603B5 |
| r665-audit-11-other-category.png | 100236 | 3949392B9CD73F78D5C90EA763AC145D8F6E65B3327F327DDD993F5D1BA5BC0F |
| r665-audit-11-other-category.xml | 6187 | 823CA9A29F85A59356988088B7896089523A1B11D95CCE3313FCAE26E14D337A |
| r665-audit-12-other-activity.png | 127965 | EECBEB4B6943F9B928E1589C6F9554E96A01FAEC550AC7CC75DDF3EDA3AEA459 |
| r665-audit-12-other-activity.xml | 8264 | 9A9523AAC727510727BDDF89AB55BDD1F40B6F2428B9330B5E9DD4662100008F |
| r665-audit-13-other-detail-keyboard.png | 133946 | 4E1EF206AA1BFD191590E335FF24E244441BB30072A84513843C60F3DD9AE690 |
| r665-audit-13-other-detail-keyboard.xml | 7582 | EDF8AAA658055EA7BF9D3421FF496B745C867F7D03F0600CB33B5BC1992A48C1 |
| r665-audit-14-other-filled.png | 132974 | 4B2F5071BAD65590497A02C4A03B6B0CEEA3FA71F2D952B4F75B240ACB6EA8ED |
| r665-audit-14-other-filled.xml | 8268 | B5E3AC97F3704C8BFD5347B1395AD287E306A924FDB5EB2A1C3169D6EE1F929E |
| r665-audit-15-other-cancel.png | 146582 | D574EDAE11548BA320B80FA82094321359D4B4735FCB5A1F2FFE57CFB62D622D |
| r665-audit-15-other-cancel.xml | 7939 | 7DC9B72C65D1B6FE7DD337A062D4DDF60EA60664CB522AAE7FC89C91735F6E09 |
| r665-audit-16-other-restored.png | 135389 | BA00E541EB617DD14077FB3813E2118EC37285742A3CDC1AF91CE21143C9F046 |
| r665-audit-16-other-restored.xml | 7898 | 76A7B03D1A30F92EDE6BCB251977A63A89287046AAD312D86EC8D0179C4AE948 |
| r665-audit-17-other-request-result.png | 146324 | 5785D94C31A280B1962B9A647E151939EAEABB72E9CDB51FEECB086C1C1F584E |
| r665-audit-17-other-request-result.xml | 7939 | 7DC9B72C65D1B6FE7DD337A062D4DDF60EA60664CB522AAE7FC89C91735F6E09 |
| r665-audit-18-search-restored.png | 162800 | BF8A0DBC6B06FF57AA90990AB7142393A31EA7E660A9D3EF75BE5D31DDF1E5F5 |
| r665-audit-18-search-restored.xml | 10613 | F12CF0102E2BB8AF85F58603E9824B0BD9EDD2827B2211FEE45813D2A4CAA1F2 |
| r665-audit-19-retailer-preview.png | 152091 | 2CA5713A681D81EFBDAAD987EDFF0740F287DEFE65D4338D904C0BE5AB79B699 |
| r665-audit-19-retailer-preview.xml | 13597 | 86DCDB4DBD5453221EF1184805EBA01D505954DB1345BF842133309D7B246B9A |
| r665-audit-20-retailer-stock.png | 145657 | 383E187B4F6524FFE6E9D20F58AA00539C3B201B690681ABCE2AF5002D1DE0DA |
| r665-audit-20-retailer-stock.xml | 13587 | F058ADAD72117F70AD0A1CA554FDD18921DEC7474202BFA300BE10364B1C6960 |
| r665-audit-21-documents-ready.png | 160511 | 7A2C153E55948E68E847CB0B40C103E46CEC404655ACFC8A7FE5B96BBB7230CF |
| r665-audit-21-documents-ready.xml | 10065 | 70CC73E00FD57B44695FB444EA58F05898BADF8289361BF5FB406805E8C912AA |
| r665-audit-22-documents-ready-lower.png | 172108 | 9AD4A03326872258ABD8302EA62DE32EB8B6870B82CF5D981C697A75A43CD623 |
| r665-audit-22-documents-ready-lower.xml | 10772 | 2CE9DC27477E079906F407D3482065B5190980A46FA85927316D94FA8171EF55 |
| r665-audit-23-contact-prefill.png | 125486 | AD9283BD7B3E574DD79D5CE76DA81E55798D0E9DF40954236AB588E04868A16F |
| r665-audit-23-contact-prefill.xml | 12006 | B5CB974A86F70F5DE02D103FA75AD08EE280BE55C14A949F92254CFCBD19B8D0 |
| r665-audit-24-contact-keyboard.png | 136470 | 8D63BB30C380A787FF50E1076A2D7361DEAF8855B858CBDEF2039B6924723DF4 |
| r665-audit-24-contact-keyboard.xml | 8552 | E294717F19B3A40C33B78E608194F2B879BB0365A386F99FDCAE05150D691ADF |
| r665-audit-25-contact-alternate.png | 125442 | AE726DD0F5EBC6575F7F43AB68D99731CB829A5012906B2436244D1A7069412D |
| r665-audit-25-contact-alternate.xml | 11327 | ED0AE83316EDDB7949542D39D7058F4B500DD8A052CECBA47BABD8B03292267F |
| r665-audit-26-contact-continue.png | 130065 | A19E7251964F3BD6012FDCA6C7F2804824C657B6EB7AA279ACD1D9DA2CE46D6D |
| r665-audit-26-contact-continue.xml | 13148 | DE7EAC2EBC86CD81B48A0A5975965FDE2EB7862EB69FA70C9305D7583933C3C9 |
| r665-audit-27-cold-relaunch.png | 69072 | 727AF9C90980EF9F31ADFE870251AFE6C408B2C90E42E944B17F2DC01B6477AF |
| r665-audit-28-relaunch-settled.png | 419290 | F21B8EA54AFD7AB49CCCE48406CB51913559099CC840919CEA74E3A23D89C78C |
| r665-audit-28-relaunch-settled.xml | 24491 | 6400967F59679BBB5287E435EA70E5B9E43E28CE317C88AF5C232E95134B957F |
| r665-audit-29-mool-return.png | 365305 | 8E7FB5FCB81ED34440F98B02CF5ECAEDAFCE0DF2F60458085B66971FAEC591C7 |
| r665-audit-29-mool-return.xml | 28181 | 7D0123414D61A8640FAD4269398B6551969449E9FE0B52DB956088C1B09857A0 |
| r665-audit-30-work-return.png | 217962 | 9C35C9914DCC00793D35BAAD51AA0FDFCA3DE8E074D7C42C4CBCE5019AC1C5A1 |
| r665-audit-30-work-return.xml | 12056 | 130F16C31085DA72D07B833642C48E1992B632813D32BB064B4B4080A1BE96F7 |
| r665-audit-31-workspace-relaunch.png | 180395 | 08B2FCF21482F85C8C4965DB45A99B7DBCCB9CCC532092E92255AAFFFAF7F8D7 |
| r665-audit-31-workspace-relaunch.xml | 10399 | 04465DFE282146F400DE671AD1CA55C443E2B424EC22A219289D74497FA5AC41 |
| r665-audit-32-restart-preview.png | 146138 | 827CC38791B3384CAD52454CE51D3CFD438DDCD780669D4BCD95BED38FE2FD1A |
| r665-audit-32-restart-preview.xml | 13249 | C0F9C25443A900A054A1686799C4A2A67288AD28D8C27E6B97AAA7D2F5B01528 |
| r665-audit-33-restart-requirements.png | 167747 | C35CA7884D443066B181F2CCF918130D20D86509A191DEBEF5F12F8E0AD41C8C |
| r665-audit-33-restart-requirements.xml | 10066 | 888A59AC7ED0C89AED7A74D83B6C3B345B4435634C8AE6CCB81A01FC211A8962 |
| r665-audit-34-restart-contact.png | 120513 | 2B8C769B31F1A57E66D0F330A06754B1F1DE4F128B61FA13AA2746AAEE1D3E94 |
| r665-audit-34-restart-contact.xml | 12023 | E42B10ECF64AFBF791FFF7AB620259981CFC7F7AC24CB51A607D0F4750D4D6C5 |
| r665-audit-35-contact-short-number.png | 120102 | 7E2E480FF91E24D6330B5630DB00FA9C209E0B5FC4D801F726815AA5F048DBE5 |
| r665-audit-35-contact-short-number.xml | 12014 | 670FF0D64941C7C9EA2538D75906FD1B937BBFFB2A8002A70C97E6723DAD2252 |
| r665-audit-36-resume-current.png | 120098 | 64D2B8EE5B169A1E04E0B291E10882FF1147A265EA4281FC5E4B8D873E80A364 |
| r665-audit-36-resume-current.xml | 12014 | 670FF0D64941C7C9EA2538D75906FD1B937BBFFB2A8002A70C97E6723DAD2252 |
| r665-audit-37-phone-validation.png | 120902 | C3F9543A53877046E432774F4E1340B83AF96D144733FB8272E35540C200698C |
| r665-audit-37-phone-validation.xml | 12684 | F8EDCFAF8158B4D765E925FD42E4800E6F6CE82B58B3C968EA310D3A605735F4 |
| r665-audit-38-phone-corrected.png | 120168 | 81067B56553EC0E29CB9DB531D9434B5FE5DFA0542965FC2C2C04EA77E551686 |
| r665-audit-38-phone-corrected.xml | 12021 | 7C432310B33070D95F736ECB74942A73C0FEE2E05083AD424F55EE5B7BD97D2C |
| r665-audit-39-phone-code.png | 132818 | DD87B38C18E4680245F5CD448313FE185AB53E773172CCBDE4A10A6254CCBF39 |
| r665-audit-39-phone-code.xml | 10257 | 4AF8D8B117B43F322D857587CACC32C12643B4B70D25AD39E6339F38217202FB |
| r665-audit-40-code-invalid.png | 137474 | 6C015905C0B3301447E9224DFDE2CA11021B5BB2138252BB88D1E36D68360B72 |
| r665-audit-40-code-invalid.xml | 10610 | 103C43F0CCC35D9B58CBEAE3845A3F567EE8E127B34659A81F2A4DE589689FE1 |
| r665-audit-41-phone-confirmed.png | 125964 | E5052A87C624E4054A2137B7D9C3243D8516494FECEB58C0794FF83545D2C5B8 |
| r665-audit-41-phone-confirmed.xml | 12354 | 9CB4BCF34B9A862DB6D52EAA77AB3059425AD1152B8503FFA385897648B3B33E |
| r665-audit-42-email-code.png | 139035 | C047AFCC5573FC2D433D385BFCEC89763F70B18C4B4A0CAEB503437993C33DB3 |
| r665-audit-42-email-code.xml | 9904 | 7ABD259F8C22F5CB94D3250BEFB0972FA25FCD42592724140330AFBE905F17FC |
| r665-audit-43-code-back.png | 135486 | F18539331F4FD4BE5DD96CA04E3D9C6872BBCE0241A6019BE443D4321E57A321 |
| r665-audit-43-code-back.xml | 13043 | 0530E2791A472454F8CC8BE7FC478FE6F27048F3ED0877EDC2F6D1415855CDE9 |
| r665-audit-44-backup-contact.png | 124163 | 134747B6CC66D46ABD65716B986689C75BD8A01AC936D2221342AB214FC41BBA |
| r665-audit-44-backup-contact.xml | 11335 | 085BD5FB08F0A1C24048336FD1299041681E2BA4618F5093FC9EAC19FE85E0EF |
| r665-audit-45-backup-guard.png | 157061 | C62A0BB5B851C9526E0E9161760CCB29ECD30A0E14178FDD2D59E741DBEC0507 |
| r665-audit-45-backup-guard.xml | 9245 | 2ED050BBF9B03327CFADC1469EF5248B3FC6BF5EBFC7F6DEA4B01802E2D4C041 |
| r665-audit-46-backup-visible.png | 127429 | 871DDE13F15CBF83CA41F66E2F10CC4F836B2B95BB588C3E12C92AD5E3BC098F |
| r665-audit-46-backup-visible.xml | 11999 | AF800D524D3F6A64BCECACF422CCA20139771A096F42B6C606FD6F685E22CF40 |
| r665-audit-47-backup-code.png | 138483 | 7047E293C3FBC0FD245283D7DED3B6475586FF01314361033B3DFE711F67838F |
| r665-audit-47-backup-code.xml | 9230 | 4C13E9F7104558C94F4286AB8170FE5F28168448CB8CD7E0140982CD7FED5FC7 |
| r665-audit-48-all-contacts-confirmed.png | 132522 | E241426AEE6713315DCD28E8C24323E77E46D5BDD5EC1A24CC04167A6885E9B3 |
| r665-audit-48-all-contacts-confirmed.xml | 11327 | ED0AE83316EDDB7949542D39D7058F4B500DD8A052CECBA47BABD8B03292267F |
| r665-audit-49-business-details.png | 138247 | 66BDDAD467E9DEF0AEE91C6E75027CCF73C4FA20F50C0CB46EE8650E57AE26DE |
| r665-audit-49-business-details.xml | 9818 | C32DCBE510058CCFCB6DD026DF8010C2CE8256DD64F026D5D70A33ACBCB724BE |
| r665-audit-50-relationship-validation.png | 164787 | D32A0E8679AB965FEEC39EE843127A3FAD3F8B4F6ECBA424A88C7645A4FD8B27 |
| r665-audit-50-relationship-validation.xml | 11035 | F95E99A2B3B0398305C0DA8C50D92433A92EAB490417886B3342606464B90BCA |
| r665-audit-51-documents-back-details.png | 138256 | 455AFE1F3963A72251A4E9C39C44D3B023657CE126C3041CFB1CE29206EE73F2 |
| r665-audit-51-documents-back-details.xml | 9818 | C32DCBE510058CCFCB6DD026DF8010C2CE8256DD64F026D5D70A33ACBCB724BE |
| r665-audit-52-business-relationship.png | 139146 | 3BB88B96A8695EF4153CDD14802E2847D474132CB31A3810F68E4BFCC3242657 |
| r665-audit-52-business-relationship.xml | 4482 | FFE201040043D8AF7C37EA24282939D46458725C2A09D155F9BD9731581F0993 |
| r665-audit-53-business-keyboard.png | 158030 | 837CCE0EBA92FCE9CF5609524CBD3D62A2CAD6747F7CE931E84FBEFA96ACC158 |
| r665-audit-53-business-keyboard.xml | 7028 | FF5178958A4A860618801514087C14C187E3B05F7A2FDBA6C087B106A2D03EC2 |
| r665-audit-54-documents.png | 145801 | 2CFBC1A30EE8D1418F0036C4CB6B2FDA1E15DC83954DB1326D8A79C240F23735 |
| r665-audit-54-documents.xml | 9847 | 6EE51F9F8428A099FFE0F0BFBBAC267960F64234ED30B5A5D0F09149BCE3F31A |
| r665-audit-55-documents-entry.png | 165997 | 596E5F2F8953EDAB704933B476D6B15F9D980072D514A83FE28EC6B526E3551B |
| r665-audit-55-documents-entry.xml | 11035 | F95E99A2B3B0398305C0DA8C50D92433A92EAB490417886B3342606464B90BCA |
| r665-audit-56-document-sources.png | 147580 | F5FC73A405C7FD2087E31577FD734C8CE109158E0AE17B3048983940847EBB56 |
| r665-audit-56-document-sources.xml | 5888 | F7C3CDD51276C12550760730EC229EFB0792AB11E1B4F4C94A5C494ACAA97024 |
| r665-audit-57-native-file-picker.png | 329919 | DD48AB8BC0FEFA99BD83414BB70B0F3278D06D430B09552559855B38A336F320 |
| r665-audit-57-native-file-picker.xml | 50892 | 748ABCBD9AB6CBD444FA1DEFC6137C3862A526361F3B71D66760C238F8B5D5A2 |
| r665-audit-58-document-added.png | 162098 | D6E6E3B58E9C028D62EA52D86BE9DC231E07FF9DEB9FB530BD13C55815D8CCD3 |
| r665-audit-58-document-added.xml | 11730 | CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5 |
| r665-audit-59-document-preview.png | 204719 | 03321CB106932AF9240C28A7EC14D1DCEBD11954CA5410DF9FABA66FFBEECA52 |
| r665-audit-59-document-preview.xml | 5487 | 239A2D785AED39FBF324909232C80E6AB0AA6C6FC58780D1EDAB0960A14FC67D |
| r665-audit-60-preview-back.png | 156016 | BDDED809988C1F392835825E6A11517E1C9435CAE7FD407A71A6C495E02069C2 |
| r665-audit-60-preview-back.xml | 11730 | CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5 |
| r665-audit-61-replace-sources.png | 143602 | DEF8DA2E7B79928B907E28BB1143DBC3B8E776817E053060298CC59E6F283228 |
| r665-audit-61-replace-sources.xml | 5889 | DFDC41C580A46723374D9C6A3D01951A8F80744562CDF7DFE6D031F7801F9448 |
| r665-audit-62-cloud-picker.png | 330258 | 4ADD0A48B9916B47F6E26D6543048D15BA7381B3E8B716DF892237638E1127F1 |
| r665-audit-63-cloud-picker-settled.png | 330234 | 09AB9D922551F4C0298C9E6B15EC8F45BE9D5F281625BB54A900243DE096B1C5 |
| r665-audit-63-cloud-picker-settled.xml | 52040 | 60846BDAFD8971BF03C4EF8616AE8DA6599551752602DA514F78DFA9AB459B6A |
| r665-audit-64-replace-cancelled.png | 143739 | 846277BED9FA751691BF9D67139994CA71BC6EC25232E8FBD7BCC6A2511A9A03 |
| r665-audit-64-replace-cancelled.xml | 5889 | DFDC41C580A46723374D9C6A3D01951A8F80744562CDF7DFE6D031F7801F9448 |
| r665-audit-65-gallery-cancel.png | 143729 | E00482B7A8892A40D608658335425622619C0A8279B76262F2203C404BE8B970 |
| r665-audit-65-gallery-cancel.xml | 5889 | DFDC41C580A46723374D9C6A3D01951A8F80744562CDF7DFE6D031F7801F9448 |
| r665-audit-66-camera-controls.xml | 11762 | 60E51CF5C214554F85F32120BB145F56CA3D783874FABDC7B99B71028B186455 |
| r665-audit-67-camera-cancel.png | 143795 | 8493F8A39EDCCD862EE3B0B2871FF5B86B0EB2BBA4B78D5E3069FC17E20DBF90 |
| r665-audit-67-camera-cancel.xml | 5889 | DFDC41C580A46723374D9C6A3D01951A8F80744562CDF7DFE6D031F7801F9448 |
| r665-audit-68-original-proof-retained.png | 156198 | 6786A354678CC5AB6EA1818786700D5F5FA00A84A5CFA4CCEFA0CF59B155B773 |
| r665-audit-68-original-proof-retained.xml | 11730 | CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5 |
| r665-audit-69-document-remove.png | 159252 | 9AC30C2A31CED849469372C05C049CE67F31BEB20FA2295517E87C4AED79E666 |
| r665-audit-69-document-remove.xml | 11382 | F26A572DE1FC8722865A83B4ED7333C84BC3BBD4B674423D60B061323AD47730 |
| r665-audit-70-document-restored.png | 155993 | 978A834753A4A110143A65311CA401AAD6AC3B3BFD7AC6B70DF63C3C25DAB24D |
| r665-audit-70-document-restored.xml | 11730 | CEFCF1E35F95098F436CA9F686EFA32539134FACB73EBCE9C1789F8A10E69CE5 |
| r665-audit-71-review-summary.png | 140495 | 6CD0C8B4FDED4B0B21ECBCD33B9183F4E110BAAE57C55137A62D34949067B70F |
| r665-audit-71-review-summary.xml | 9190 | D1307A804901FDA5B6901FE7A24C601C254539D224E0EB29F16D3DCDC550FF21 |
| r665-audit-72-declaration-guard.png | 134111 | 6D032515F96DBC923D49260592C84537AEB4C143E5A31206CCC1C163452DEDD9 |
| r665-audit-72-declaration-guard.xml | 9246 | B0528CBCC34372969356404897EC15AC129CB22F355ADBE2C3A19FA549DD4DBA |
| r665-audit-73-review-edit-documents.png | 156249 | 8644DBEC9A20A0FF733D4D466BF372353E7A828DD73E803B6DE8813973899046 |
| r665-audit-73-review-edit-documents.xml | 11732 | FFFBAA1B5FC9BC93AD4D0AE54157CB45D62DBD3B092DC0983EB771F1E7C51D08 |
| r665-audit-74-edit-return-review.png | 140898 | AC75F117AF49F4421EA73C13A6544A7DCA735065269203F0E44A7EA273A22920 |
| r665-audit-74-edit-return-review.xml | 9190 | D1307A804901FDA5B6901FE7A24C601C254539D224E0EB29F16D3DCDC550FF21 |
| r665-audit-75-review-edit-contacts.png | 128943 | F0DB94F4D7AF4221A4E25B1BAA9D8C0B4DE1F0FE17A99A34AA11ECA27B826487 |
| r665-audit-75-review-edit-contacts.xml | 12014 | 810AF5BE8076521AB96A45EE7F90D7F27C3B146C03F308525FA29AF06310BB6D |
| r665-audit-76-contact-edit-back.png | 140753 | 220C2FCDC196CF8D6DB30A1F6049C67B7682779A70C9445D328126B7961A3A28 |
| r665-audit-76-contact-edit-back.xml | 9190 | D1307A804901FDA5B6901FE7A24C601C254539D224E0EB29F16D3DCDC550FF21 |
| r665-audit-77-review-edit-business.png | 140504 | 7CCC162B3E19B3AD8FE8FB701D5ED641894848E2AE6D014EDD7F920B68C54619 |
| r665-audit-77-review-edit-business.xml | 9853 | 988B5138D06258615F6F9B60432944A30EA0DAF0A8AA58E1CA461013A581544D |
| r665-audit-78-business-edit-return.png | 140754 | 7B7FFDF46BDA7B5B0418894490AA1794920EEE79695AB08459854EF3C5138599 |
| r665-audit-78-business-edit-return.xml | 9190 | D1307A804901FDA5B6901FE7A24C601C254539D224E0EB29F16D3DCDC550FF21 |
| r665-audit-79-work-chat-entry.png | 111681 | BEBA1D4FA549ABDDDD5E5654A5E58DE73D4CA8ACC5A672201275F34A7A26DA74 |
| r665-audit-79-work-chat-entry.xml | 11999 | 952894E313A58162D5256A1FC35F6ACD75E9B02559A7362DB0CC37692A479C95 |
| r665-audit-80-review-chat-thread.png | 85741 | 1FB676742B5E5BC51ED9E3E1E503C5DC3647B48C8750B18195C35B19F1607FED |
| r665-audit-80-review-chat-thread.xml | 7718 | ADD239FDBA6AB3DBEE1C8E9810410204BDC4865D2DF4AC526D11A769B1FCF705 |
| r665-audit-81-chat-keyboard.png | 135348 | B5A053021EA25720DDE68EE1278B888FE5E885F36123259B07705617D5B3AEF6 |
| r665-audit-81-chat-keyboard.xml | 8053 | 013E7C1E4683F09998BFBB4C87CBD2C1731060ACA20D5E709D6C2445CA61FFDE |
| r665-audit-82-chat-keyboard-back.png | 89075 | C37135B647A1CFED46F734259463B6E06C3768F1D9EB2B7D1015515FCE996A7C |
| r665-audit-82-chat-keyboard-back.xml | 8065 | 8FD15CD090631FDA256E504EE27F8EB92FD117A85C605855E9752AA7516CAF3E |
| r665-audit-83-thread-back.png | 109653 | 1BC99A4AB0438EDAE91C1AAA3BCE80F4C0A2A67FF1BBAA6E04FCAC784B2F3DF8 |
| r665-audit-83-thread-back.xml | 11978 | 137BF55F6316FF7D2EA24A795302D3485AF6EC7E50BE30C04BF1ECDE7A37110E |
| r665-audit-84-chat-return-workspace.png | 139912 | B0D2437E820FB1700BA2D176CBB2069062C9DAEB8B8FBFC059D98FD9B77B7E7C |
| r665-audit-84-chat-return-workspace.xml | 9189 | EE9301188D2BBA371B3E876E0083CDDBE9299F842032D8ADEF94BCDAD247BD85 |
| r665-audit-85-chat-reopen.png | 109690 | F5CE6C4BC3F32CD03B94336400FFB87DF48E5551CE8A0BAB370BA624EDAFB2D1 |
| r665-audit-85-chat-reopen.xml | 11978 | 137BF55F6316FF7D2EA24A795302D3485AF6EC7E50BE30C04BF1ECDE7A37110E |
| r665-audit-86-draft-restored.png | 89111 | 8EE340BD318AEA6AFAA417DF374CFE185E9A74EA9C1E8A5AE287D471BCC48FE7 |
| r665-audit-86-draft-restored.xml | 8066 | C7F17F24019369CD031F46519460D51BDF1262F056812669D1BD480A79C79620 |
| r665-audit-87-discard-test-draft.png | 85165 | 4BAE7EF684CC7C791E076878DD54464E193885B972B5E62407A9B5C375959FF1 |
| r665-audit-87-discard-test-draft.xml | 7717 | 21BB33E8A8F9586B6ED3E2E2955F93585DF0C57952F615D6ABD51653527D94AF |
| r665-audit-88-chat-draft-cleared-list.png | 111186 | C6BF2FC5487EAB230D13B008D6F951EE9996332E82ABFC8D388633CCEC127EEC |
| r665-audit-88-chat-draft-cleared-list.xml | 11998 | 5DEC37CF324056948F0AF8DC96E9CA65DF0163E4F10D9128ED15A2580DA9146E |
| r665-audit-89-review-restored.png | 139945 | C24149ADA348806C5FFC6A48B9C7AC913E8626B57A32631F2FCFEE28A623AB91 |
| r665-audit-89-review-restored.xml | 9189 | EE9301188D2BBA371B3E876E0083CDDBE9299F842032D8ADEF94BCDAD247BD85 |
| r665-audit-90-review-declaration.png | 123494 | 3DA540CBD7130E1CD7E498D06D37D406093D514DE8E861FB5E42375DB9FBFE3A |
| r665-audit-90-review-declaration.xml | 9183 | AA2299679C2DF86F82F4F286A11C3300D845155C4EA0AC6006FEBD7724A486E1 |
| r665-audit-91-review-confirmed.png | 123685 | D75E965CA3C0352215241227C42F3245B88CDC8BC0F55BCBE6BC0931484F5405 |
| r665-audit-91-review-confirmed.xml | 9182 | 352FC93637319D6B3077CAEEDAF1195CF21B145BE3CB8374C6CCA9D013521C38 |
| r665-audit-92-submitted-pending.png | 131031 | A90E24FAC1F87245BFC89CA53826CDCB332AC6DB60C52B5952C28B29746944DD |
| r665-audit-92-submitted-pending.xml | 13148 | 4F9BA442391B195E1692782F20C8FD4C85A0310B2BDA6FCBC5F6C3FA89E8F643 |



## Current checkpoint: installed, limited device review

On 7 September 2026, OPPO CPH2375/2b3e0f71 was connected. Update-install with adb install -r succeeded from r66.4; no clear-data, uninstall, production package or Redmi action occurred. Installed version1.0.0-r66.5-runtime/code2026090604 and device base-APK SHA-25669EEC3287857A634BFDD71E7327BCFAD347DC60526165657499F40E9CBA807AE equal the sealed candidate. The APK and its source/provenance were not rebuilt or changed. MainActivity cold launch returned Status ok/TotalTime7198ms.

- Actually observed: Shop startup, Mool menu, Work/Earn entry, Workspace selector and Grocery/Kirana same-page introduction. PNG01,04,05,06 were directly visually inspected; XML02/03/07 was inspected. Search hint now displays the complete word Search, resolving the earlier r66.4 ellipsis observation in this captured layout. Selector/preview and Choose this Workspace are above Android navigation in the captured viewport.
- OPPO-R66.5-REVIEW-ENTRY-01: Store dashboard/device review remains blocked by review-state provisioning, not by APK installation. ReviewWorkGateway.loadFeed returns an empty list after restart and device review defaults to pending. The prior r66.4 checkpoint also ended at the selector; do not infer lost approved business data. Provide an explicitly isolated approved review fixture for native Store review or an authenticated approved-workspace response; never alter production approval rules or describe a fixture as live approval/payment/collection authority. No review-state injection was performed.
- Existing OPPO-R66.4-OBS-02 remains open, not duplicated: Earn Today still shows the review Quick Delivery Biker HIRING NOW with05Sep2026 deadline on07Sep2026. XML03 is identical to the prior retained sample. This is stale fixture content, not proof of real hiring.
- During the selector observation, a Quick Delivery Biker application banner appeared between captures04/05. Its origin was not established; do not label this a deterministic card-tap defect. Later the foreground guard stopped the attempted system Back before input. Capture07 was made only after a new foreground check again confirmed runtime; its filename does not mean Back executed. Automated interaction stopped pending exclusive screen review. No unrelated app screenshot was taken.
- Native dashboard/first-tap operations, Back, keyboard, large text, real picker, order timers, collection and end-to-end journeys remain pending. No blanket device pass, production backend acceptance or founder approval is claimed.

### Immutable local capture inventory

Directory: artifacts/device/codex-oppo-r66-5-review-20260907. Generated PNG/XML/install log are preserved, Git-ignored and hash-bound here. UI/source/test blobs remain unchanged.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| oppo-install-attempt1.log | 38 | C4AA470ACAFCF8576C15B0F0B5AE7E852D1EC5413372D0E6A9272E788E1306D3 |
| r665-oppo-01-startup.png | 415879 | B394F7D187E77764268753246ABE1F19ABAD1CF31947FB6FAA999EEB55776774 |
| r665-oppo-01-startup.xml | 24491 | 6400967F59679BBB5287E435EA70E5B9E43E28CE317C88AF5C232E95134B957F |
| r665-oppo-02-mool.png | 362223 | EA3D25F2B6960D8601308511F912F292F72F555C8C51FD3487C28524B8F783BA |
| r665-oppo-02-mool.xml | 28181 | 7D0123414D61A8640FAD4269398B6551969449E9FE0B52DB956088C1B09857A0 |
| r665-oppo-03-work.png | 215453 | 04B0D443780D3AEFF66F5A8EB7C0EB147C7EFFC370F3CC6B160C6ABC68177AA5 |
| r665-oppo-03-work.xml | 12056 | 130F16C31085DA72D07B833642C48E1992B632813D32BB064B4B4080A1BE96F7 |
| r665-oppo-04-store.png | 178073 | 4C8C58677C6E930E35EB4DA90AD6B4C05D31D3A346181D65CA3ECB388DE2013E |
| r665-oppo-04-store.xml | 10399 | 04465DFE282146F400DE671AD1CA55C443E2B424EC22A219289D74497FA5AC41 |
| r665-oppo-05-retailer-preview.png | 169720 | DE2D9C9AFE8446C49BB6B3CFF835B658F015EAB801206DB605D3CEFE36583D9F |
| r665-oppo-05-retailer-preview.xml | 10332 | 47092546109426291297A8A01FE85EAFADE85931C2EBFB13DCD30114CF274DAB |
| r665-oppo-06-retailer-expanded.png | 142914 | AE981363AE1E0FD72F5F2F3CD580EBD80E8D714AE6B481F10714BEBED7709696 |
| r665-oppo-06-retailer-expanded.xml | 12951 | 4C0DEBACBD49106C91EF48F6B96FE230F4CC91F39FB34F14BC40A04F3AFBB630 |
| r665-oppo-07-back.png | 143030 | 16DCF3FEC83054CFB5935690FF8C78805CFA5356E01E1EEA1B2D209406F62195 |
| r665-oppo-07-back.xml | 12951 | 4C0DEBACBD49106C91EF48F6B96FE230F4CC91F39FB34F14BC40A04F3AFBB630 |

## Previous connection-only checkpoint (superseded by the current checkpoint)


APK built and independently verified: source91d9a9b8a321946bc26a1c4645b22784ab43f2e3; runtime package1.0.0-r66.5-runtime/code2026090604;209715721bytes;SHA-25669EEC3287857A634BFDD71E7327BCFAD347DC60526165657499F40E9CBA807AE.

Device phase is blocked by connection only. The existing device memory gate passed. ADB reported device2b3e0f71 not found, and adb devices -l reported no attached devices. Founder was asked to reconnect/unlock OPPO and accept USB debugging if prompted. No install, device data clearing, screenshot, tap, Android permission change or device journey was performed in this round. Redmi and other packages remain untouched.

Resume: verify OPPO CPH2375/2b3e0f71, run the current required device checks, update-install only this exact APK with -r, then read installed package/version/base-APK checksum. Launch the isolated runtime package, confirm its foreground identity before captures, and replay the Workspace/Store/dashboard first-tap corrections one screen at a time. Record actual device defects and founder feedback without counting local fixtures as device/backend qualification. Do not send WhatsApp messages or submit real payments.

Local qualification is complete as recorded in local-validation.md: two1315-pass connected cycles,89 native cases and156 captures. Native stills cannot close OPPO smoothness, keyboard, real picker or founder appearance review. Backend and consumer collection integration remain explicitly pending in ticket-and-screen-coverage.md. No new OPPO defect is invented from the missing USB connection.
