# r66.11 ticket and screen coverage

| Finding | Implemented | Local verification | OPPO |
| --- | --- | --- | --- |
| OPPO-S03-02 contact instructions |00995b0c; field-specific malformed phone/email/alternate validation before verification|9 focused cases, normal/200% keyboard captures, two final connected cycles|r66.11 captures008-034: malformed phone/email/backup, physical keyboard, correction, independent review-only confirmations, Back/re-entry and optional-number removal pass. Real OTP and process-death verification persistence are not qualified.|
| OPPO-S07-04 / REG-4549 application-support draft scope |b5236a11; local application identity, drafts/replies/media/error, async/retry safety|A/B isolation, empty drafts, ordinary Chat, reset, newer edits, Work recovery and combined cycles|r66.11 captures050-099: distinct same-type A/B applications, intentional unsent edits, generic draft preservation, keyboard and exact application return pass. No message sent; A-after-B native reopening, failed-send/media recovery and process-death persistence remain unqualified.|
| REG-4550 error banner keyboard fit |b5236a11; actual48px dismissal plus bounded full error text|412x915/100%,320x568/200%,320x536/200% with220px simulated IME; edge dismissal and scope preservation|Native retest pending; physical200%/TalkBack separate|

No screen is closed solely from widget tests. Backend dependencies and seven additional unresolved exploratory assertions remain explicitly recorded in local-validation.md and the prior review ledger. The two reproduced defects pass the bounded native scenarios above; this does not close every pre-dashboard journey or qualify production.

## Founder sequencing checkpoint — pre-dashboard closure first

Founder explicitly paused Dashboard first-tap screens, including View statement. Finish the pre-dashboard journey's remaining applicable checks and Git closure before starting that review. The earlier first-tap observations remain evidence, not approval and not authority to continue those destinations.

Retain the existing visual approvals for Grow with MoolSocial, Documents to keep ready, Contact, Business details, Documents, Review and submit, Application received, More information needed, Application not approved, and the Dashboard first view. Do not reopen approved design or equate visual approval with untested technical acceptance.

| Remaining pre-dashboard boundary | Existing evidence / exact remaining work |
| --- | --- |
| Contact and application recovery | r66.11 proves retained contact values and same-process Back/re-entry. Fresh process-death/account isolation and pending application recovery beside an approved workspace remain unqualified. Review applications are in-memory fixtures; a fixture reset is not proof of lost production data. |
| Document providers and recovery | r66.10 covers QA PDF selection/preview/edit and clarification correction. Actual camera capture, Gallery selection, remote cloud completion, remaining invalid-file/format/upload-failure and interruption cases remain unqualified in that round; inventory prior exact evidence before replaying or closing them. |
| Application-support error/retry | REG-4550 has normal/200% host fitment and dismissal evidence. Native failed-send/banner/attachment recovery and post-restart drafts remain unqualified; do not send a real message to manufacture an error. |
| Physical accessibility | OPPO replay is100% only. Physical large text/TalkBack and spoken labels remain pending, independently of passing host200% captures. Do not change Android security settings to bypass access restrictions. |
| Additional shared regression assertions | Seven exploratory assertions in local-validation.md remain open for exact parent/owner classification. No new skip, weakened assertion or inherited-failure claim is authorized by this checkpoint. |
| Live backend acceptance | Server OTP, authenticated application/document storage, clarification submission, admin decisions and notifications remain backend dependencies. Review-only Approved/Rejected/Clarification fixtures qualify presentation only; do not fabricate live success or auto-approval. |

The next work is the pre-dashboard evidence/remaining-check reconciliation above, not Statement or other dashboard destinations. No additional implementation, APK, device action or source modification was performed while recording this sequencing correction.

## Native child registered during r66.11 replay

REG-20260909-4551 — Grocery/Kirana Store profile Documents loses its return context.

- Exact route observed: approved test Store A dashboard > Profile > Documents > Files > Back > generic Workspaces > Back > Social YouTube.
- Expected: Back from the document destination returns to the same Store context; no unrelated Social landing.
- Native evidence: external `oppo-r66-11-native-20260909/086-app-a-profile` through `089-profile-spaces-back` PNG/XML/capture logs under `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905`.
- Source diagnosis and shared-owner check are pending. No source fix, new general owner permission, or acceptance of this destination is implied by registration.
- Parked with dashboard first-tap follow-ups under the founder sequencing checkpoint; not silently closed or treated as one of the original contact/support defects.
- Contact malformed-input checks and application A/B draft checks remain separately qualified. No real document, message, payment or approval was changed.
