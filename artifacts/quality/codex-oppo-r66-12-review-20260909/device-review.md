# r66.12 OPPO pre-dashboard retest

## Exact candidate and outcome

- Device: OPPO CPH2375, serial 2b3e0f71, 720x1612, font scale 1.0.
- Source HEAD: 26b193f8d5ee4a285d4398ec4d2257d0d6d63ab0.
- Installed: com.moolsocial.app.runtime, 1.0.0-r66.12-runtime +2026090902.
- APK: 209790729 bytes; saved and installed SHA-256 D1A9E9C4A0FE190F64C9BE862B4FD324A810BD5EE90ABC71EC56D1A7F991C973.
- Installation used adb install -r without clearing data. Install verification is in post-install.json.
- REG4552 and REG4553 passed the bounded native replay described below. No further product defect was observed in those exercised checks. This is not all-screen, backend or production-release acceptance.
- The device is left on the newly approved QA Workspace dashboard. No dashboard first-tap destination was tested in this replay.

## Retained native evidence

Root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-12-native-20260909

capture-manifest-v1.json binds 234 files, 11822173 bytes: 78 PNGs, 77 XML trees and 79 capture logs. Manifest SHA-256 F76E947F78861B21200CA4B5FFB794737F4FFC621BBA3A0A676372317B04542E. Partial/failed captures are retained, not counted as successful capture commands.

| Captures | Real device action and observed result |
| --- | --- |
| 002–011 | Existing saved QA application survived installation. Its pending state did not expose editing or production approval. Review-only submitted-case memory does not survive the gateway restart; this is a harness limitation, not proof of production data loss. |
| 012–016 | Existing Earn Today setup action starts a separate application using the existing startAnotherWork flow. No reset, direct state injection, harness allowance or product change was used. Grocery preview, prerequisites and contact entry were reached normally. |
| 017–026 | QA phone and reserved example.test email entered; both confirmed through ReviewWorkGateway only. No SMS/email sent. Continue reached business details; no real OTP authority is claimed. |
| 027–033 | Clearly named OPPO-QA-r6612-Document-Test with test area/activity/relationship reached Documents. Source sheet shows complete title/options and a visible, hit-testable Cancel above Android controls. |
| 037–041 | Selected the existing clearly marked 3201-byte two-page QA PDF. Attachment filename was correct; View rendered it and Next page reached page 2 of 2. Startup loading frame039 is separate from settled rendered040. |
| 042–047 | Replace from preview; selected the 96-byte plain-text file renamed .pdf. Inline error: “This PDF could not be opened. Choose another copy.” Cancel stayed visible and worked. The original QA PDF remained attached and reopened successfully. |
| 048–051 | Cloud files entry reused DocumentsUI. A local 10 MB + 1 byte QA file was rejected with “Choose a document up to 10 MB.” Android Back left the original PDF intact. This tests the entry/validation path, not a private cloud-provider download. |
| 052–057 | Native file picker Back first returned from the nested QA directory to Download, then cancelled to the source sheet. Sheet Cancel worked; original PDF remained attached. |
| 058–065 | Review and Submit listed the exact filename and one attachment. Confirmation checkbox selected. From its View/Replace flow, the invalid local PDF via Cloud files was rejected. Cancel returned to Review with the valid filename and checked declaration preserved (XML060 and065 both checked=true). |
| 066–070 | QA-only submission remained pending with one document; explicit labelled test selector produced Clarification requested. Correct reason, Add documents and Update details appeared. Add documents retained the original proof and reason. Android Back returned to the same application. |
| 071–077 | Same QA reference WP-hm4tj1ni09-18viqiu-1. Explicit labelled Rejected scenario displayed Application not approved and its reason, retained submitted information and one attachment, exposed Contact MoolSocial, and did not expose document correction or dashboard access. No message sent. |
| 078–079 | Explicit labelled Approved scenario opened this QA Workspace dashboard directly. Welcome message cleared; the store remained off/private with zero recorded finances and setup actions. No automatic real approval or public publication occurred. |

## Capture and harness dispositions

- 001: startup PNG only; XML absent, preserved partial evidence, no install/launch repeated.
- 034/035: the external capture command wrongly required a spelling of Android's hierarchy progress text. Both remote XML files existed and were recovered later, byte-identical SHA-256 5CD2C416659200FA68FED78150CDD987DA1E6E635D56531ADE38BEEE1FF7860A. Original commands remain failed;036 is the successful settled capture. 034 PNG is an external-provider startup frame.
- 054: app-only capture correctly refused while DocumentsUI was still foreground after nested-folder Back; no PNG/XML claimed. 055–057 record the actual recovery.
- Existing REG4530 retains these observation/runner incidents and the bounded discovery-output incident. No missing output was reconstructed.
- The restarted old QA case was not granted a status bypass. The existing new-application action unblocked testing, so no additional review-control code or APK was needed.

## Limits and preserved earlier evidence

- Local normal/140%/200% layout tests and captures passed on the exact source; this OPPO replay was 100%. Physical 200% and TalkBack are still unqualified; security settings were not bypassed.
- Actual private Google/Microsoft cloud download, server OTP, authenticated backend review/upload, notification delivery, messaging, payment and secure collection remain separate dependencies.
- r66.11 contact field-error, independent-confirmation and application-scoped unsent Chat-draft tests remain retained evidence, not newly claimed r66.12 executions.
- Camera capture/save in the r66.11 loop was founder-assisted. Codex tested retake/Back/cancellation there. No fresh camera capture, real identity document, WhatsApp message or private cloud access occurred in this replay.
- REG4551 Profile/Documents return and dashboard first-tap review remain parked. The seven previously reported exploratory assertions remain unqualified and have not been declared inherited without executed parent comparison.
