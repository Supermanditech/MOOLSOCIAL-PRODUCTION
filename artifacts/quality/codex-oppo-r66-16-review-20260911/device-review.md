# r66.16 OPPO review

## Native068 correction — existing UI restores QA Store access without rebuilding

The earlier conclusion that a new APK was required was too strong. The existing Earn Today persistent Create your Workspace banner calls startAnotherWork(), which remembers the active application before starting a separate draft. Native053–065 followed that normal route to create OPPO-QA-Recovery-Store using retained QA contact details, explicit review OTP verification, and the existing option to provide documents later. No additional private document was uploaded and no real application was submitted to a backend.

Native066 exposes the already-installed review control with the explicit warning: Test data only; no real application, payment or approval is changed. Selecting its Approved scenario restores the Store dashboard in067. Native068 visually and semantically confirms OPPO-QA-Recovery-Store is selected while OPPO-QA-Cloud-Document remains separately Under review and OPPO Review Store B remains Application saved. This verifies visible preservation of the earlier applications, not a blanket assertion of every persisted field or production approval behavior.

No new APK, source/test/Android edit, stored-approval mutation, data clearing, hot reload, security-setting change, backend action or Cursor/Redmi operation was used. The installed r66.16 checksum is unchanged. This is an isolated QA workflow, not a production approval workaround. R6616-QA-RECOVERY-01 remains open because the original review control still loses eligibility after restart; its Store-testing reachability blocker now has a verified existing-UI workaround. Restock/product/cart/Back testing can continue but has not yet passed through this recovery evidence alone.

Native049–051 additionally verify the support attachment sheet honestly reports unavailable review pickers; closing it preserves the unsent draft, and Android Back returns to the same application. No real attachment selection was completed through Chat. Native052 confirms Profile itself only offers View application while pending; the Earn banner is the distinct recovery entry.

Immutable external native-capture-manifest-v4.json binds049–068,40 PNG/XML files. SHA256:28027537D823B819359A24E5B773F27988A9C87942ADA3AD6895E60670BE974C. Actual067/068 captures inspected. Earlier failed checks and manifests remain preserved. Counts unchanged:13 customer-facing/native findings,1 narrowly closed and12 open, plus the separate open QA recovery defect. No product fixes or further APK builds authorized in this testing round.

## Native048 continuation — dashboard replay blocked by review-fixture recovery

Current source HEAD at audit start421aa770f112bbc7baf4c75688caed4be01548be was clean; OPPO2b3e0f71 connected. No product/test/Android edits or APK build. The new support restart child was additionally recorded under existing REG4549 with only its registry hash binding refreshed before this device continuation.

042 rechecks exact application A with empty draft.043 Back reaches its persisted Application received state, not the previous synthetic rejected state.044–047 exercise Mool > Work > Workspace > Grocery: the retained pending application offers View application, not a new submission or test approval.048 sends the known dashboard route through Runtime and confirms No approved Workspace yet / Choose a Workspace. This negative access-control check passes; no unauthorized dashboard access occurred. Actual048 PNG inspected. The intended Restock product/cart/Back replay was NOT reached and is not marked passed.

Source evidence: ReviewWorkGateway._submittedReviewCases is an in-memory Set; canSelectDeviceReviewCase requires membership. The application state-control eligibility is lost after process recreation. WorkChooseActivityScreen.chooseWorkspace routes all choices back to proof while resumeApplication is true; it does not provide a fresh review submission here. WorkWorkspaceDashboardScreen requires an existing verified workspace before rendering Store or its seed controls. These are review-fixture reachability limitations, not proof of production approval loss. Do not count another customer defect from the lost mock approval, clear app data, mutate stored approval, bypass the guard or build a successor under the current testing-only instruction.

Remaining native Store replay requires a permitted recovery of an approved QA workspace/test-control state. No such recovery is exposed on this retained application in the installed build. Founder direction or a later authorized review-fixture correction is required; no change is performed now. Historical findings remain13 total, one narrow closure and12 open. The original27 items are not all device-qualified.

External native-capture-manifest-v3.json binds042–048 (14 PNG/XML files); SHA256 372D55B0D593DDC2AA10C0537280FE8924D177C49035BDFB36BEBBDDF24B1F83. Earlier manifests and evidence remain untouched.

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
