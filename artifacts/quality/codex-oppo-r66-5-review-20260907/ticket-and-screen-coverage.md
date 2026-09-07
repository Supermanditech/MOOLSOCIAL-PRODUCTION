# r66.5 frontend ticket and screen coverage

## OPPO audit round 1 — registered findings, 7 September 2026

Audit only. Source91d9a9b8/r66.5 was not changed. Findings below do not supersede founder-approved dashboard placement or authorise shared/Cursor edits. Preserve existing OPPO-R66.4-OBS-02 (expired review opportunity) and OPPO-R66.5-REVIEW-ENTRY-01 (no approved review Workspace) without duplicate tickets.

Evidence names below resolve under artifacts/device/codex-oppo-r66-5-review-20260907/. Complete filename/byte/hash inventory is in device-review.md. Native observations apply to OPPO CPH2375,720x1612,density320,font1.0 only. Backend responses in this build are review fixtures.

### Frontend findings for the next correction round

1. **AUDIT-R665-01 — review freshness stops silently (P1, source-confirmed).**
   - Owner: apps/mobile/lib/features/work/screens/work_onboarding_screens.dart, _refreshReview at1854.
   - After20 polls the30-second timer is cancelled; only lifecycle resume resets it. Remaining continuously foreground can therefore stop receiving review updates while the page promises automatic updates. This was established from source, not a completed ten-minute server/device replay.
   - Correction: bounded backoff or subscribed refresh with visible stale/offline/retry state, retaining lifecycle and exact-case guards. Do not create rapid endless polling or simulate admin approval.
   - Retest: pending beyond the current cutoff, transient errors, resume, case switch, rejection/clarification/approval and one exact dashboard transition. Backend contract BE-02 supplies revision/freshness.

2. **AUDIT-R665-02 — custom-request sheet overlaps Android status area with keyboard (P2, native-confirmed).**
   - Owner: apps/mobile/lib/features/work/screens/work_onboarding_screens.dart, Tell us what you do sheet.
   - Evidence10-other-keyboard and13-other-detail-keyboard: title/Close occupy physical y40..136 while Android status area occupies y0..82. Empty-submit then focus/type reproduces the overlap.
   - Correction: retain actual window top inset through the modal boundary; constrain and scroll the form above the IME. Preserve touch targets, draft and keyboard continuity.
   - Retest: three/four fields, Other selection, validation, keyboard dismissal and small/200% layouts; no security-setting workaround.

3. **AUDIT-R665-03 — corrected custom-request field retains an obsolete error (P2, native-confirmed).**
   - Owner: same custom-request form/session validation.
   - Empty Send request reports the missing business/service. After entering a valid nonempty title, that error remains through category and activity entry (captures10,12,14). Reopening clears it.
   - Correction: clear or revalidate only the changed field's error; do not clear still-invalid category/area/activity errors.
   - Retest: empty submit, correction, changed category, Other activity, cancel/reopen and failed submission. Valid local fixture submission is not production delivery (BE-04).

4. **AUDIT-R665-04 — business-relationship prompt truncates at normal size (P2, native-confirmed).**
   - Owner: work_onboarding_screens.dart business details dropdown.
   - Evidence49-business-details: the unselected prompt renders “Your relationship with the busi...” at font1.0. Selection and Back work.
   - Correction: put the full customer-facing field label above the value or adapt its layout; retain Owner / Partner or director / Authorized representative choices and the approved business subtitle.
   - Retest: all options, empty value, long labels, keyboard,320px and200% text; no clipped prompt or reduced hit area.

5. **AUDIT-R665-05 — backup-number confirmation recovery focuses the wrong task (P2 UX, native-confirmed).**
   - Owner: contact setup validation/focus in work_onboarding_screens.dart.
   - Evidence45-backup-guard: Continue with an entered but unconfirmed backup number correctly blocks progress, but opens the phone keyboard and leaves Send code below the visible IME boundary. The number is already complete; the required action is confirmation, not further typing. Dismissing the keyboard exposes the action (46).
   - Correction: for an otherwise valid unconfirmed number, reveal the verification action/row without forcing number editing. Keep ordinary invalid-number focus and optional remove behaviour.
   - Retest: blank optional backup, valid unverified backup, invalid backup, same-as-primary, code error, keyboard Back and changed verified number.

6. **AUDIT-R665-06 — document View needs usable inspection (P2, source-confirmed usability gap; native image opening passed).**
   - Owner: work_onboarding_screens.dart _showDocument.
   - Evidence59-document-preview opens the exact PNG; long content requires scrolling before Close/Replace. Source uses Image.memory without zoom; PDF View renders an instruction to check the original rather than document pages.
   - Correction plan: reuse a bounded safe document viewer where available, with accessible close, image zoom and a clear PDF open/preview action. Do not claim unsupported PDF preview or add a large new viewer dependency without assessing existing owners.
   - Retest: small/large images, multipage PDF, unreadable/corrupt/oversized files, replacement cancel, Back and large text. Actual PDF selection/view was not run in this audit.

7. **AUDIT-R665-07 — Workspace review Chat needs more precise, compact presentation (P2 copy/visual, native-confirmed).**
   - Shared Chat owners, not Cursor Buy: apps/mobile/lib/features/chat/chat_session.dart and screens/chat_thread_screen.dart; exact owner claim must be checked before implementation.
   - Evidence80/81: support subtitle is truncated, unavailable call/video controls occupy top-row space, and the seeded message still says “Choose one work profile” regardless of the current application stage. Call semantics truthfully say unavailable; no call was placed. Empty/one-line composer uses approximately78-79 logical pixels before surrounding spacing.
   - Correction plan: concise retailer-facing support copy, stage-neutral until an authoritative case update exists; visually truthful unavailable actions; assess one-line composer density without losing attachment/voice access,48dp targets or IME safety. Preserve accepted Chat entry/return architecture.
   - Retest: exact Workspace return, drafts, keyboard, long/multiline messages, large text and other global Chat entries. Sending, calls and real admin messaging remain unqualified.

8. **AUDIT-R665-08 — separate pending submission from new Workspace drafts (P1 source risk; destructive reproduction deliberately not performed).**
   - Owners: apps/mobile/lib/features/work/work_session.dart selectProfile and submitted-summary consumers in work_onboarding_screens.dart.
   - selectProfile mutates the current profile and removes non-personal proof entries when changing selection; it has no pending-case guard. Pending summary reads current session fields. Native02 showed both a pending retail review and an outstanding different opportunity banner in the selector.
   - Correction requirement: immutable account/case/revision-bound submitted snapshot and a separate draft per selected business; selecting another business must not relabel a submitted case or discard its displayed attachments. Preserve existing case correlation checks.
   - Retest in isolated fixtures: pending retail case -> another selection -> return exact case; rejection, clarification, multiple cases, account change, late response and restart. No existing founder attachment was deliberately removed to prove this risk.

### Frontend/backend dependencies to settle before live onboarding

- **BE-01 — account and application recovery.** Current contact draft restores entered text; native restart did not restore standalone contact confirmations or the review fixture's submitted case. Do not save a local trusted verified/approved boolean as the fix. Require authenticated verification receipts keyed to exact account/channel/value, explicit invalidation on change, and server recovery of the immutable application snapshot (authorised name, legal business name, relationship, contact identities, document IDs/metadata, profile and case revision). Production data loss was not established by an in-memory ReviewWorkGateway restart.
- **BE-02 — authoritative admin state and correction.** WorkReviewResult currently carries case/status/plan/workspaceId/reason/profile/name/area/activity, but no structured requested-field list, revision, submitted snapshot or expected response timestamp. submitCorrection in the production gateway explicitly remains unavailable. Define pending / clarification requested / rejected / approved / suspended responses, professional public reasons, requested field/document IDs, exact case/revision, safe correction idempotency, last-updated/retry and approved Workspace identity. Pending has no dashboard action; approval requires a real authorised response. Represent the24-working-hour expectation from the configured service calendar rather than inventing deadlines.
- **BE-03 — document storage and recovery.** The native PNG selection is real; saveProof acknowledgement here is local. Bind server-issued upload references to account, application, requirement and document revision; enforce size/MIME/content validation, secure storage/access, resumable retry, expired URL handling, malware checks and safe replace/remove semantics. Preserve original-file metadata and distinguish local attached / uploading / received / needs correction. Do not treat a filename or the test PNG as identity verification.
- **BE-04 — unsupported business request.** sendUnsupportedRequest returns success only for ReviewWorkGateway; production explicitly reports unavailable. Define authenticated request/idempotency, category/Other activity, operating area, durable draft, receipt/reference, status, retry and failure contract before enabling real submission. Fixture success must not promise delivered review/Chat updates in production.
- **BE-05 — admin communications and return routes.** Review updates in MoolSocial Chat and any WhatsApp/email/call channel need real consent/preferences, authenticated sender/case context, delivery status and an exact application deep link that resumes after sign-in. Do not equate “Now” review seed messages with an admin reply or send any WhatsApp/SMS/email during this audit.

Record/agree these interfaces before backend development; implement service authority when the backend lane starts. Frontend fixes must preserve honest unavailable/error states meanwhile. Backend security cannot be qualified by this APK's fixtures.

### Design refinements and accessibility verification, not extra duplicate defects

- Compact the simultaneous pending-case and opportunity banners only if founder agrees; preserve both intentions and avoid repeating the existing stale-opportunity ticket.
- Verified contact summaries can be more compact; do not undo the approved contact wording or shrink targets. The observed normal-size fields are usable.
- Cloud files currently invokes the same picker as PDF or image and opens Downloads. Clarify provider discovery; real signed-in cloud-provider completion remains pending.
- Review Edit/View controls work. Native XML exposes repeated generic Edit/View labels, while source already includes section-specific Tooltip text. Verify actual TalkBack output before declaring an accessibility defect; strengthen semantics only if the section context is not announced.
- Physical200% text is pending because Android denied WRITE_SETTINGS; font remains1.0. This is a test-environment boundary, not an app failure. Other screen sizes, TalkBack, rotation and reduced-motion replay require separate physical/local evidence.

### Current closure boundary

No ticket above is implemented or closed by this audit. Reachable retailer onboarding and unsent Workspace Chat interactions were exercised; admin-approved dashboard/first-tap operations, other business types, real OTP delivery/autofill, PDF/gallery/cloud completion, actual camera capture, physical200%, authenticated clarification/rejection/approval and live services remain pending. No source edits, APK rebuild, integration, Cursor/Redmi action, outbound message or real payment occurred.


## Source reconciliation

All completed Codex frontend fixes are retained through 6212aca44117d70fdbe2fc517ca2de7774f1a966. The founder's frontend clarification additionally authorizes S09-ACCEPTANCE-TIME-UI-01 in six existing Work source/test owners. This candidate imports no new Cursor work. Historical pending implementation notes in the append-only founder review ledger are superseded only where source and tests support the disposition. Backend-only and consumer integration dependencies remain open.

| Journey | Current frontend implementation | Remaining qualification |
| --- | --- | --- |
| Workspace discovery and retailer introduction | Inline search; compact partnership introduction; existing 18 selections; grouped, same-page pain-point/action previews; no extra benefit screen | Fresh OPPO and founder review |
| Cannot find Workspace | Existing compact form, keyboard handling, validation, local request/retry and Back | Native replay; production submission service is not asserted |
| Documents to keep ready | Accepted layout, concise retailer-specific evidence list, bank proof, nationwide applicable-GST wording | Actual admin review and outbound notices deferred |
| Contact setup | Authorised-person wording, exact-account prefill, required phone/email and optional backup; scoped draft recovery and confirmation invalidation when changing a contact | OPPO keyboard/relaunch; real OTP delivery/autofill is not qualified by fixtures |
| Business details | Grocery / Kirana Shop or Speciality Retail Shop subtitle; Business name (as per PAN card); Your relationship with the business; stable keyboard and Back | OPPO replay; legal verification deferred |
| Document upload and preview | Accepted list, PDF/JPG/JPEG/PNG/WebP up to 10 MB, camera/gallery/file entry, preview/replacement/Undo and interrupted-picker recovery | Native camera/gallery/PDF/cloud-provider replay; no real document submission required |
| Review and submit | Compact grouped business/contact/document summary, section-local Edit and document View, explicit declaration and recheck after change | OPPO replay |
| Application status | Pending, requested clarification and rejection reasons on the same screen; no automatic production approval; direct approved dashboard entry | Authenticated admin correction/review/notification backend deferred |
| Store first view | Approved header, finance rail, central order card, supply edge, bottom/subrail retained; one compact read-only status control | OPPO visual/motion and founder review |
| S09-01 dashboard-wide finish and motion | Compact navy/white finance hierarchy, sourcing emphasis, central state accent, coordinated reach/first-tap controls; finite confirmed-value/state transitions; stable actions and reduced-motion/lifecycle containment | Final analysis0 issues;89 native cases pass; two38-file cycles each1315passed/83 unchanged exclusions/0failed. OPPO qualification remains separate. Shared bottom navigation keeps its accepted family accent; no Cursor/global owner is recoloured |
| Store first tap | Exact Orders, Sell bill, Stock catalogue, statement, dues, settlement, Restock, Buy Direct, Group Bulk Buying, store link, promotion, requirement selector, Chat/Profile/alerts and Back | OPPO navigation/input replay; live purchase/publication/payment services deferred |
| Money and customer history | Ordinary and 100-1000 crore-range layouts; full exact amounts on disclosure; paid-customer purchase/contact history retained | OPPO large-text replay; no financial-authority claim |
| Multiple orders and multiple stores | Lazy identity-bound order queue, preserved selection, per-store operational state, guarded switching during active/uncertain operations, account invalidation and late-result containment | Local 1000-order queue tests are not production throughput/capacity qualification |
| More time | Compact timer-adjacent request sheet; current deadline retained while requesting; unavailable, declined, retry and confirmed presentation; original operation reused after uncertainty; exact store/order/operation and current-state validation; confirmed acceptance and fulfilment times; no local extension shortcut | The optional authenticated WorkOrderTimeGateway has no live implementation. Durable backend reconciliation, store-wide capacity rules and consumer notifications/estimate propagation remain deferred; fixtures are frontend evidence only |
| Retailer customer collection | Existing central card, explicit Order ready, QR/wait, Customer confirmed, Hand Over, Collected; inline unavailable/error/reconciliation; biker pickup preserved | Consumer 022-R5-A, authentic backend enforcement, real QR transport and integrated acceptance remain pending |

## Deferred service dependencies, not APK-review claims

- Authoritative store capacity, customer-visible waiting/ETA, extension decisions and reassignment. The retailer request frontend is implemented; a device timer must not fabricate acceptance, reassignment or delivery.
- Collection account/order/store/item/revision/payment/readiness validation; challenge/approval expiry and replay; durable operation reconciliation and exactly-once stock/invoice/payment/completion effects. Review fixtures cannot qualify handover security.
- Exact public retail-store links and post-sign-in resume/payment destinations; authenticated customer contact and messaging integration. Do not substitute Wholesale or a local Work session as a public link.
- Real document/admin review, clarification delivery, notifications, payment/settlement, invoice sending, promotion/requirement publication and procurement commitments. No WhatsApp sending or real payment during this review.
- Cursor consumer UI/scanner/return mapping and integration acceptance. Shared contract remains Codex-owned; Cursor source and Redmi are untouched.
- Timing adapter contract: request carries workspaceId, orderId, operationId, expectedAcceptanceDeadline and additionalMinutes (2 or 5). Response must repeat all identities and return approved/declined, with confirmed acceptanceDeadline and fulfilmentDeadline when approved. The backend must authenticate staff/store permission, atomically compare the expected order state/deadline, validate payment and current store workload, reconcile repeated operation IDs and deliver revised estimates to the purchasing customer. Pending request persistence and fresh authoritative order hydration on relaunch are required before enabling this service in production. No new endpoint, transport or consumer file is implemented here.

Local and device results are recorded separately in local-validation.md and device-review.md. No broad go-live or founder visual acceptance is inferred from automated tests.

## OPPO reconnect checkpoint, 7 September 2026

The exact r66.5 APK is installed and its device checksum matches. Native Shop > Mool > Work > Workspace entry and the retailer introduction preview were observed. This does not close the remaining rows above. OPPO-R66.5-REVIEW-ENTRY-01 holds dashboard device qualification: ReviewWorkGateway.loadFeed returns no approved workspaces on fresh launch and device-review submissions default to pending. The prior r66.4 checkpoint also opened the selector; this is not evidence that update-install deleted an approved business. A clearly isolated approved review fixture or genuine authenticated approved-workspace response is required for Store device replay; do not weaken production approval guards or silently fabricate live orders. A Back attempt was blocked before input when the runtime left the foreground; no Back pass is claimed.
