# r66.16 OPPO review

## Native041 restart finding — latest disposition

Historical native findings now13: one narrowly corrected/retested and twelve open. One new child in r66.16: **R6616-UAT-SUPPORT-DRAFT-13 / REG4549**, also relevant to DASH-LOAD-14 durability. Implementation and another APK are held under the founder's latest testing-only instruction.

Reproduction036–041: save unsent QA-r6616-application-A-retain under the exact application WP-hm77elehz3-11muv1w-1; open synthetic application B through the existing supported Chat route; B's composer is empty, then accepts its own QA-r6616-application-B-retain. Returning to A restores A's exact unsent text (039). Stop only Runtime with am force-stop, without clearing package data; observed PID9448 exited and restarted as10487. The review startup opens its fixed Shop entry (040), so that capture alone is not a draft assertion. Reopen the same exact A route after startup; A's header/application is correct but the composer is empty (041). No draft was sent or discarded. Screenshots040 and041 were inspected directly.

Expected: account/application-scoped unsent support text restores after process recreation until explicitly sent/discarded; no cross-account reuse. Actual: Back/in-session isolation works, but restart loses unsent text. Source chat_session.dart stores drafts only in _draftTextByThread (line272; writes849; reads805), with no durable draft adapter in that owner; this state is shared by review and production constructors. Later child should add bounded account/application-safe local persistence, logout cleanup and migration/recovery tests after ownership review. Do not implement now. Disappearance of delivered mock messages is review-gateway volatility, NOT evidence of lost real server messages. The common workspace-support thread history under both A/B is not classified as cross-account leakage; both test routes are in the same local review session, and no backend access was exercised.

Native application B was an explicit QA route fixture, not a real submitted/authorized application. Warm A/B draft separation is verified; real application authorization and historical retrieval remain backend dependencies. The review's fixed cold-start Shop route is recorded as a fixture boundary, not a newly attributed production deep-link defect.

External manifestv2 binds036–041 (12 PNG/XML files); SHA256 A299E16F20B3132755FDB1C8ABAD768D856CB770EEBD1344FBC5F4F945847CD8. Manifestv1 and001–035 remain unchanged. No product/test/governance source or APK changes were made after the founder's testing-only instruction.

## Completed bounded native continuation — 11 September 2026

r66.16 was built from a8fb9a8a84029ffd4ff11ad1026bd74dcec09875, installed with retained data on OPPO2b3e0f71, and independently read back as version1.0.0-r66.16-runtime/code2026091103. Built and installed base.apk SHA256: 0B39D0EAAC3F0B5A8F811B87EE3486DB462F561471084A41101BBC110A9A49FE. See post-install.json. Redmi and Cursor remain untouched. Predecessor r66.15 evidence remains preserved; the Runtime package was updated, not cleared.

Native evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-16-native-20260911. Manifest native-capture-manifest-v1.json binds35 complete PNG/XML pairs; SHA256 958FA42CD9146EEE378D1AE90D39F908E13BD38248873D1610229E0AF4E52164. Counts are captures, not passed tickets. Capture026's filename describes its intended check; Retry was not yet visible there. Capture027 is the actual fully visible keyboard-open Retry evidence.

### Observed steps and outcomes

-001–006: retained Runtime opens Shop; Mool > Work > Workspace > Grocery entry > documents preparation. Startup foreground guard stopped once during launch transition before capturing anything; independent foreground verification preceded001.
-007–015: QA contact/business values restored. Existing review OTP123456 was entered for mock verification only. Two attachment references remain without their metadata, reproducing already recorded R6615-UAT-DOCUMENT-RESTORE-12; no duplicate child or claim of restored document content. Review/declaration applied to the existing QA application only.
-016–022: submitted through the in-memory ReviewWorkGateway, then selected explicitly labelled review-only Clarification requested and Rejected cases. Source inspection confirmed no backend submission or real approval change. The clarification fixture does not expose Contact MoolSocial; the rejected fixture does. Expanded reference WP-hm77elehz3-11muv1w-1, business OPPO-QA-Cloud-Document.
-023–025: Contact MoolSocial opens that exact application in Workspace Review. The prefilled draft contains the same application/business. Armed the one-shot review failure with keyboard closed; focused the composer; Send message produced the expected not-sent error and preserved the entire draft. No real support transport was used.
-026–027: two swipes in the message region expose the failed row and full Retry target while the keyboard remains open.027 shows Retry bounds[54,556][177,652], clear of composer[26,726][582,930]. No keyboard dismissal or coordinate tap through an obscured target.
-028: one Retry tap clears the error and draft, and the same message becomes Delivered · unread in the review gateway. One copy is visible, not two. This is local simulated completion, not actual backend delivery.
-029–031: typed QA-r6616-unsent-draft; app-header Back returns to the same rejected application's status/reference; Contact MoolSocial reopens the exact application with the unsent text unchanged and the first completed message still present once.
-032–035: explicitly armed a second one-shot failure for that QA draft. Back/reopening preserves the failure, draft and correct application. Scrolled the failed row fully into view, retried once, and observed exactly one completed copy of each of the two distinct QA messages, no error and an empty composer. Failure control returned to its unarmed state.

Actual key PNGs inspected:008,019,023,025–028,031,035; other step assertions use captured semantics and observed navigation, not a blanket visual approval. Default font scale was independently read back as1.0 and enabled accessibility services empty. No settings were changed in this continuation.

### Qualification boundary

The exact-application frontend failure/retry and same-application Back/draft recovery scenario passes on this OPPO at default scale. Local actual Flutter renders and focused tests cover320×568/200% with keyboard open. Physical200%/TalkBack, application A/B switching on the device, process-death support restoration, real transport and backend authority are NOT newly qualified. The original host Retry overlap was a test render-timing issue; no production Chat layout was modified and it is not a new OPPO child.

Historical device findings remain12 total: one narrowly corrected/device-retested and eleven open. No new distinct native defect was confirmed by this continuation. Keep unrelated children held for founder's consolidated review; do not declare the entire27-item batch closed. No real messages, WhatsApp, payments, publication, integration, release build, security changes or data clearing occurred.
