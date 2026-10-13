# r66.5 OPPO review

## Audit continuation — 7/8 September 2026, captures 93–148

Installed r66.5/source91d9a9b8 is unchanged. This checkpoint preserves the second reachable-journey audit before the founder-authorised correction/build/retest round. Backend authority, consumer integration and founder appearance acceptance are not claimed.

- Workspace: pending case return, Speciality and Wholesaler same-page previews, Daily work tab, Close and Back were exercised without choosing another profile over the submitted case (93–98).
- Physical large text: normal Android Display/Font UI selected Very large, with readback `font_scale=1.6`. Wholesaler preview, pending summary, Chat inbox/discovery/thread and unsent composer were exercised (104–113). The pending email row adapted to stacked full-width content; primary preview action remained reachable by scrolling. Chat hint/subtitle truncation and oversized composer extend AUDIT-R665-07. This was 160%, not 200%; no broad accessibility pass is inferred.
- Font restoration: only the size slider was changed, then restored through Settings to Default; readback `font_scale=1.0` confirmed before continuing (114–117). Roboto, default weight, adaptive-weight Off and security permissions were untouched.
- Chat: Conversation info, honest media empty state, Pause -> blocked composer -> Resume, message search and exact result return all worked (118–126). No message, attachment, call or voice recording was sent. The explicitly labelled QA unsent draft was discarded; no other draft was deleted.
- Normal app process restart used force-stop/start without data clearing. Entered contact/business strings restored; in-memory ReviewWorkGateway case and standalone confirmations did not persist. Reconfirmed the three test contacts with the known review code, then reached Documents through the ordinary UI (127–143). This is not evidence of production data loss or real OTP delivery.
- Native PDF: selected the labelled two-page QA PDF via the system file picker; the exact filename and attachment state returned (144–146). View showed only metadata/instructions and no document/open-file action (147); Back retained the attachment (148). AUDIT-R665-06 is now native-confirmed for PDF inspection. The PDF was not submitted as identity evidence.

### Evidence qualification and recovery

114 additional files: 58 PNG (56 native captures plus two PDF renders), 55 XML and one PDF; 8,783,142 bytes. Native127 has PNG only: UIAutomator returned null root node during startup, and the success-message guard correctly rejected XML. Fresh128 recovered readiness; 127 is not a paired capture or product failure. An oversized tool response around112/113 was unavailable; files were independently recovered,113 XML confirmed the draft was discarded and112 PNG was subsequently inspected. No missing output was reconstructed.

Direct PNG visual inspection in this continuation:102,104,105,109,111,112,115,118,124,147 plus both QA PDF renders. Other captures were reviewed through hierarchy/navigation outcome, not all certified visually. These device stills do not qualify frame pacing, all screen sizes or TalkBack.

PDF fixture: `MoolSocial-QA-NOT-A-REAL-DOCUMENT-r665.pdf`, 3201 bytes, SHA-256 `334BFE9F8E952DC688DC6C552F610A9DA258BE7733A2424CABB06B23F4521EDA`. Created with the PDF skill, rendered and inspected before selection; both pages clearly say QA ONLY / not an identity or bank document. Its device copy remains in Downloads; no personal PDF/photo was opened.

### Corrected finding boundary and next scope

AUDIT-R665-08's earlier description was too broad: Submitted information already reads `session.submittedProfile`, and submission copies proof references. Do not replace this working summary or claim its business/contact values mutate with the draft. The remaining risk is a selected-profile/header and active review-case mismatch because `selectProfile` can change profile and draft proof entries while an existing case remains. Prove and fix only that root cause with focused tests; durable multi-case backend recovery remains BE-01/02.

Founder subsequently authorised autonomous completion of reachable audit, deduplicated Codex-owned fixes, local regression/visual checks, Git sealing, successor APK installation and OPPO retest. Do not expand into Cursor-owned Buy/Redmi work, production approval/collection bypasses, real messages or backend implementation. Existing OPPO-R66.5-REVIEW-ENTRY-01 remains open: the installed review gateway has no approved/scenario entry. A separate QA-only scenario-selector question has not yet received a direct answer; no selector or approval fixture was injected in this checkpoint.

Shutdown is conditional on all work/testing complete and positive confirmation that Cursor has stopped. Lack of activity is not confirmation. Otherwise leave the laptop running.

### Additional immutable evidence inventory

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| MoolSocial-QA-NOT-A-REAL-DOCUMENT-r665.pdf | 3201 | 334BFE9F8E952DC688DC6C552F610A9DA258BE7733A2424CABB06B23F4521EDA |
| r665-audit-100-display-lower.png | 79239 | 73FCE2DA4CC37C6880C08FD12B83A929C48A37DE11DC736B039089E94F5FD977 |
| r665-audit-100-display-lower.xml | 24484 | D68C30296FD67FD8B6C3589D1C9F434139A0CB2475C9069927B83DED69900C8D |
| r665-audit-101-font-settings-original.png | 85276 | 4D687869BBF9C6F3279EF222DAADAC4015C9B44ACA4FB7332DA42B759DFD3CC8 |
| r665-audit-101-font-settings-original.xml | 2872 | EADC04BC4DC3188FCFF09160750E8E54E97BC11796CFDD704E7B7163133CE508 |
| r665-audit-102-font-controls.png | 83910 | 5F40226B83380E0568432C7583FE12B58A208F28C67CD1BEE5B324357CEC859C |
| r665-audit-102-font-controls.xml | 23267 | E8E366872E69A47948132F0389683E5382505129EC7A6CD01D048776F1DE6275 |
| r665-audit-103-font-largest-preview.png | 82988 | AB4DE30F55EE4511172E6C09BD5FD8E3A491D7A70B91F2BB0D643955D75A7D6C |
| r665-audit-103-font-largest-preview.xml | 23270 | D4C6C9E5DCBB2CFFB584B9812A6B1089DD9D2B50C4108AE85959E66EF0CC4E33 |
| r665-audit-104-wholesaler-font160.png | 133874 | 05AB0CF86A43FE48FB68EAD278543CB51D1BCF0A8FFCD30C4FBC973134D75DC0 |
| r665-audit-104-wholesaler-font160.xml | 12446 | 628421CFF436B40F2B247076FFC73829A7CE87FD677BB5159D5E4A6C05C2545C |
| r665-audit-105-pending-font160.png | 164125 | 36775C4E7833C1590747119CE33210C83868A31CCEDC626390CC85DF7DFED018 |
| r665-audit-105-pending-font160.xml | 11446 | 0DC108925AD4D252FEF721204E38AD3D977F7D13EFF9E159A68ECC84F6D41F37 |
| r665-audit-106-pending-lower-font160.png | 140184 | 3007A09739E03B8269BEEDD3CABCDCF38C3841589EA107C5C6D29F9DCA6927B6 |
| r665-audit-106-pending-lower-font160.xml | 12099 | E68DB87EAE4C8A512D23613F74C1A8887A6C9A62D3247556E4567079092F8065 |
| r665-audit-107-selector-font160.png | 133490 | 2FE7E26A71322A98E44BE59790929185D82CA6237FA8871B5769A76B95970478 |
| r665-audit-107-selector-font160.xml | 12446 | 628421CFF436B40F2B247076FFC73829A7CE87FD677BB5159D5E4A6C05C2545C |
| r665-audit-108-chat-font160.png | 123301 | 9EB9864A411070692F99F45D4530FA0E419BFF9132ABD492B7A2A19691064612 |
| r665-audit-108-chat-font160.xml | 12000 | 888FDFE27F9DE50E8A88614E70402841629CB5DFCE880B3B9D4E8F2FEE589765 |
| r665-audit-109-new-chat-font160.png | 152596 | 5686935D4083FBC6951DEE9E9240B7191F2833AC7790B219430DC64FE99DE52E |
| r665-audit-109-new-chat-font160.xml | 9681 | F600904C6B0BDC5CDCC1CD3E2E7D5D4AB12660C2BC1D4114604D674786D59966 |
| r665-audit-110-chat-list-font160.png | 123274 | A97BF88B7DFAA4D4B17603A7E03F33B479FC199CDE1739961129A2F9687D425A |
| r665-audit-110-chat-list-font160.xml | 12000 | 888FDFE27F9DE50E8A88614E70402841629CB5DFCE880B3B9D4E8F2FEE589765 |
| r665-audit-111-thread-font160.png | 110869 | 1B0187928F2DA43C7824EFE445DF5064D2CA36E084B5F7F5963B049B8451A367 |
| r665-audit-111-thread-font160.xml | 7716 | 69C6329DA403243597EED57006A4F882A8F1175D9B16C16B922AD995BEB557FF |
| r665-audit-112-composer-font160.png | 178249 | 1FF80EBDB6145917B5CB20C853A3D0373967AA0209D440B54D11B7D3C291C49B |
| r665-audit-112-composer-font160.xml | 8108 | BA615539332166F18224EDD5A280AF4BB9D85DAA8336118F87D4A3BF1AA3EA60 |
| r665-audit-113-draft-discard-font160.png | 178440 | EBF3754698A8068F531D98F8CF102941404438E7BF7AB67D08AC7A952658906D |
| r665-audit-113-draft-discard-font160.xml | 7710 | 9CC493633E64AFDC164B13524BC03F71F42440AA24BB64A6347A01487486BBFB |
| r665-audit-114-restore-display.png | 93176 | 9F3777DE0D55E73A85503A91B5D73D7EE87DB0407FFD98D9A7501646E29016FC |
| r665-audit-114-restore-display.xml | 22727 | 478F3279AD39084BAAFB4375D9C7598496600C3316FEE13B9787F116E7D6004C |
| r665-audit-115-restore-font-controls.png | 87165 | CD20FB3EAF8B7B9676466DAF10A71D86CD75E32FA2921E5E04F6EF2599F5B396 |
| r665-audit-115-restore-font-controls.xml | 22510 | 90F852DEF5AC73C1A90525159A245D050238155DE0E231CD171AAE9D27209BA8 |
| r665-audit-116-default-font-preview.png | 85315 | D3D979D660A55ED0CC3CC8427E6340915B4EA05BFB937FBF216E774744FBF4EC |
| r665-audit-116-default-font-preview.xml | 24312 | F2C6C5EBCA7F20BC9F8235509DFDA1C53EAA93C7A982BCEAD930211A81B32B44 |
| r665-audit-117-font-restored-chat.png | 80946 | 7A98B5F17A5AF55B65B1C7B418EDD1594B8654A1CF1D94A28FDC9DE3EE72F50E |
| r665-audit-117-font-restored-chat.xml | 7717 | E07E07F52A90A33BC53F4D86B621E4757F7E6F90CBA92EE5685C96D92BC0F35E |
| r665-audit-118-chat-info.png | 184410 | 0E013F652C5A95EFC7B710AE471E97469B96AF4B7111F8B49E9AA58FB61E28A0 |
| r665-audit-118-chat-info.xml | 8692 | 1730AADE180F97F37174450546BB292646337F8BEAE954840A1060C40860E2A5 |
| r665-audit-119-chat-media.png | 74776 | 6A6030B97ACDE09CB7C04F2541A2AC97C9DDC988AE945F11B0E6B3EDC411144E |
| r665-audit-119-chat-media.xml | 8547 | F95E938E3BAC551AED7C0605D349CD1621DED4C0D70D873A6CEFD82DC1DDB416 |
| r665-audit-120-chat-info-return.png | 184409 | 0839EE109FB21718BFCC78235F0F84F3F46C72F6BD00817FE8967C76F7644D2F |
| r665-audit-120-chat-info-return.xml | 8692 | 1730AADE180F97F37174450546BB292646337F8BEAE954840A1060C40860E2A5 |
| r665-audit-121-chat-pause.png | 186376 | 7D3636635E079BB6888661583D55E4823FEE5ECE9327243E8D998361FC46FDAF |
| r665-audit-121-chat-pause.xml | 9763 | 604AA3EEC496C41CCE4A15F8C95D7B78D71FD7DD66111688264BE5781767E752 |
| r665-audit-122-chat-paused-thread.png | 82875 | 240495176892CA03E937E8834D75C9C77E944E62296A4A485619C023DE513D9A |
| r665-audit-122-chat-paused-thread.xml | 7055 | EFF9FC5880C40A76C594387442153E107AF6D31A796B428F8D531ED0C872E9C8 |
| r665-audit-123-chat-resumed.png | 80718 | 5685D3140A38B1D161C1E9EC4D898BD20BB394369AD58F5B2D6E72F6406DBBD2 |
| r665-audit-123-chat-resumed.xml | 7718 | ADD239FDBA6AB3DBEE1C8E9810410204BDC4865D2DF4AC526D11A769B1FCF705 |
| r665-audit-124-message-search.png | 131799 | 789DDFDE6D434AC22E74824F127FE82B2B16C905C49116EB301926DC42F711A1 |
| r665-audit-124-message-search.xml | 5893 | D1778B6973154514DCA1DB3EAD188F20205FEF7CC0A6041AA311B0395619B169 |
| r665-audit-125-chat-search-result.png | 126973 | D3C46E9B04F43C90435C374CF5D55F623642CAD84CE6D0557521735E52962ECC |
| r665-audit-125-chat-search-result.xml | 6651 | EAE034CF6A249AAC9BC857307D1FBBE91A99C032703126EF56907320C1A50F50 |
| r665-audit-126-message-result-return.png | 85011 | F2D8EF157F68063D57E80E5E7F25CC26EFBCA9F06DB58198A2D5A5A67DA3CEB7 |
| r665-audit-126-message-result-return.xml | 7717 | F4210EADC5554D8FA153B9440E5BF991F8453179F43388FDF18BD5F2F4D20DD8 |
| r665-audit-127-cold-pdf-journey.png | 72572 | 7D731D26D4EF7D7AF11D00EC8F27418C7C2A366600DF579B3EBFDF52109502FD |
| r665-audit-128-cold-ready.png | 415801 | 4CE761AF1A1114A879EDE8A5AB97E804B82BE1BE70C84BC632291108F09A11D3 |
| r665-audit-128-cold-ready.xml | 24491 | 6400967F59679BBB5287E435EA70E5B9E43E28CE317C88AF5C232E95134B957F |
| r665-audit-129-mool-return.png | 362155 | B0DE0FAF34F2FCA6BF7A74DB938601AB1200D61FCABC9A71A1826BDA3E9BD4F6 |
| r665-audit-129-mool-return.xml | 28181 | 7D0123414D61A8640FAD4269398B6551969449E9FE0B52DB956088C1B09857A0 |
| r665-audit-130-work-entry.png | 215427 | F97672F57D04E268BE13B9C626446AD5C12C74875C7B800F6F6581A4AF4F906B |
| r665-audit-130-work-entry.xml | 12056 | 130F16C31085DA72D07B833642C48E1992B632813D32BB064B4B4080A1BE96F7 |
| r665-audit-131-workspace-restart.png | 178025 | A2F69AEA9ACB4BE2A5ED05F3515E922E9996C554ED71E69D9ABA37CE5AD49591 |
| r665-audit-131-workspace-restart.xml | 10399 | 04465DFE282146F400DE671AD1CA55C443E2B424EC22A219289D74497FA5AC41 |
| r665-audit-132-grocery-restart-preview.png | 143542 | ABAE311BC27E77F7E856CD6A2E0203E044C12359CCD4FD2C8DE5EE6880CB2C32 |
| r665-audit-132-grocery-restart-preview.xml | 13249 | C0F9C25443A900A054A1686799C4A2A67288AD28D8C27E6B97AAA7D2F5B01528 |
| r665-audit-133-documents-ready-restart.png | 164923 | 31A18C05610E217037A5492B51045A16DC5C232A8945A48141A69E325E256BAE |
| r665-audit-133-documents-ready-restart.xml | 10066 | 888A59AC7ED0C89AED7A74D83B6C3B345B4435634C8AE6CCB81A01FC211A8962 |
| r665-audit-134-contacts-restored.png | 117148 | 29CCFF8269035AC7A6B64126A8B14D91B369B8A650BAD84423AB0BC7F6A671CF |
| r665-audit-134-contacts-restored.xml | 12023 | E42B10ECF64AFBF791FFF7AB620259981CFC7F7AC24CB51A607D0F4750D4D6C5 |
| r665-audit-135-primary-code.png | 129566 | 7946C7D5F052F2F96DDCC68FB917A1EFA789DC13BAF55F303176303E2DDE2A23 |
| r665-audit-135-primary-code.xml | 9591 | DDDE6221E554E5ECC12BED5B5D7771272359DB113B3D25D887C57960ECFDBD46 |
| r665-audit-136-primary-code-entry.png | 130704 | 0065759632FAD67952B7F1FF4A64A294BBDD560BB8ACA389F79F1E2C5EEB669C |
| r665-audit-136-primary-code-entry.xml | 9597 | DFAE4AC1A17694519613F4D73FCAAA88CACF35370E465A96F491EBEFE629FDD6 |
| r665-audit-137-primary-confirmed.png | 123397 | 78B169C22C2537BD0675AF6898B80FD83F74B3FE4F726DD717AEFDFE0EBAF54A |
| r665-audit-137-primary-confirmed.xml | 11687 | F3728C5AA03D463108B32986ACD0E00A60BAE95C2937D88C7CB4979B8837D1FD |
| r665-audit-138-email-code.png | 135729 | 73EE87BE3A9A2A6BFD5FCEB831B906DA62ADBB23655EE7FE3C4CAD17CAA6949B |
| r665-audit-138-email-code.xml | 9904 | 7ABD259F8C22F5CB94D3250BEFB0972FA25FCD42592724140330AFBE905F17FC |
| r665-audit-139-email-confirmed.png | 121116 | C992F32B783ED5BC9299B4FF7CD15C2A95C0910836ECD1287447470243B3CAFB |
| r665-audit-139-email-confirmed.xml | 11659 | 33E606A0583A5E330ACDEBA931749B258774368214307E4CEDD83E63E631B2E3 |
| r665-audit-140-backup-code.png | 135297 | E316E7690C1D3B29F3B638C4189FC2CFB5FAD668F1A5EBCF008429BA4FABCC55 |
| r665-audit-140-backup-code.xml | 9230 | 4C13E9F7104558C94F4286AB8170FE5F28168448CB8CD7E0140982CD7FED5FC7 |
| r665-audit-141-contacts-confirmed.png | 129571 | BD11411913DC49F838349BFF8DA917FA0E75A898D7D60E2282AA18189A816877 |
| r665-audit-141-contacts-confirmed.xml | 11327 | ED0AE83316EDDB7949542D39D7058F4B500DD8A052CECBA47BABD8B03292267F |
| r665-audit-142-details-restored.png | 141337 | 377F6CD4F6D4F2980B00921583CAD0E57017C190B9C6011437D073A50028AD71 |
| r665-audit-142-details-restored.xml | 9848 | 5D5D67019E3FF7CF0DFEA4348489E5CD3F916F5D457F6644558860DA541EA412 |
| r665-audit-143-documents-empty.png | 160790 | A2BF5C14A89D0E402BC2885FB3E661C451CF188120C98BFE2912EB46CD0472D4 |
| r665-audit-143-documents-empty.xml | 11035 | F95E99A2B3B0398305C0DA8C50D92433A92EAB490417886B3342606464B90BCA |
| r665-audit-144-pdf-source.png | 142786 | DF953B39C4420C90A5ACF7BD356BD85D121035109EA3F1EAFA36889C4B18D368 |
| r665-audit-144-pdf-source.xml | 5888 | F7C3CDD51276C12550760730EC229EFB0792AB11E1B4F4C94A5C494ACAA97024 |
| r665-audit-145-pdf-picker.png | 190460 | 5B27EC5BDB03A709150D0844F17ADBF4179AEFF49C829A4BB6D4648A714BA8E6 |
| r665-audit-145-pdf-picker.xml | 49176 | E52EE1184C4DA6546ACAC04EA2B1FDF33605F38ACABF9574E6490AB0ACFC52CF |
| r665-audit-146-pdf-attached.png | 156874 | D4272514372940CE0A6497F6CF73E0ADF7B9F08D28E391CAA3BC78DAFE9ABD0D |
| r665-audit-146-pdf-attached.xml | 11730 | 10942B70625E170E5B24BA53C0523819C76744D5DEE6491D3028F61797D1D4D0 |
| r665-audit-147-pdf-view-gap.png | 143287 | 2113CC73BDEDF93C84860448DF81F7D355E2830C40DBC5244DF273622BE174B1 |
| r665-audit-147-pdf-view-gap.xml | 6233 | F65D2FC7F9A1D889DED7E4049DDE52F693557CBB4081F33F7ECD0D83CC04228E |
| r665-audit-148-pdf-view-return.png | 149061 | 4DD2B710A70A365BA8B8E720101D30828B59589BBF90878BAAA22BC8FE283892 |
| r665-audit-148-pdf-view-return.xml | 11730 | 10942B70625E170E5B24BA53C0523819C76744D5DEE6491D3028F61797D1D4D0 |
| r665-audit-93-pending-resume.png | 141692 | 6B3C76A93250EB6FC910EBFAF9CBA4A12BB936D3BD9DC9AF0D3F5A9B22EE1D1A |
| r665-audit-93-pending-resume.xml | 13882 | A7D8C96E2F351F7C35355D739DA5568A38111DB105FD25EB648D7CAE71A3074D |
| r665-audit-94-workspace-return.png | 174563 | 6E32D926D7FCA351D7033A0DF28503C7438E8B79FC7CFD6A374D308FE22843F2 |
| r665-audit-94-workspace-return.xml | 10646 | 3DD1EC0EEA8BEE8541E8A0F80062561CDF4205F9FFDA730E35D73330ED8C64B0 |
| r665-audit-95-speciality-preview.png | 145845 | 01E2C1764E393EABB6E36571DAE52814463021881E944C11651717150A096B21 |
| r665-audit-95-speciality-preview.xml | 13265 | 420741FAD1A9F8D0C8F59F081D022C90CCEE07A8817CC6188182753BD41B9F68 |
| r665-audit-96-speciality-daily-work.png | 147284 | BB762A3D50CC04664624DB6CDAD630DC8DA38AF2B386C4DDB47D70125942D69B |
| r665-audit-96-speciality-daily-work.xml | 13259 | 49B26DC6115B1D8C59031EC0CF6AFE0554967F68A7EFC199AB34E0A34E09772B |
| r665-audit-97-speciality-close.png | 175236 | 2EB869889090E5621325358E9AE18B3E681AD7F11CAA99B0C1A2A390CC3FDCE8 |
| r665-audit-97-speciality-close.xml | 10646 | 3DD1EC0EEA8BEE8541E8A0F80062561CDF4205F9FFDA730E35D73330ED8C64B0 |
| r665-audit-98-wholesaler-preview.png | 146914 | 6D69E5477134F84926875F9BCE216F2F9ACAF14DCBBAEDE9594D35D221BC26C6 |
| r665-audit-98-wholesaler-preview.xml | 13262 | 2828F0B1FD1979B38DCF30753CA5728C8FDC623DEAA510484A325137530EB7C0 |
| r665-audit-99-display-settings.png | 74906 | 1FEC5A5753765BCA4FDB3D6C89009188983A1324FC6426F37449FCDCEA1C47E0 |
| r665-audit-99-display-settings.xml | 21270 | BAF3385F544E6BC9F6241F870F809B39FEC7A96CAFDA618E7CDBD12A470D19CF |
| r665-qa-pdf-page-1.png | 73516 | 59AE494DA5B253027FF360E183C1BF5CDF22C7D3D029315B52CCCDA69E43F8B8 |
| r665-qa-pdf-page-2.png | 73784 | 247BA015B816B94ADF189C42300EC7439E4BC651EA9BA11C67CC81752466FFA3 |



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
