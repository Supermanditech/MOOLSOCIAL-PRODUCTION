# r66.11 OPPO review — 9 September 2026

## Candidate and evidence

- Source: `3cb25a36b277fe1d49188d5d0fb152fb19581aec`; contact implementation `00995b0c9755c3a74ee91b678572e24f2f65441f`; support/banner implementation `b5236a11f770cb96cecae08c5419e4881eb45578`.
- OPPO `2b3e0f71`, 720x1612, existing 100% font. Package `com.moolsocial.app.runtime`, version `1.0.0-r66.11-runtime`, code `2026090901`.
- Saved and installed APK SHA-256 both `0A3A8F70FD8A42F81B4045F7DC92BCFC37AE4C32AFAC446A6D07C779A4DA4801`; 209,790,309 bytes. See post-install.json.
- External root: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-11-native-20260909`.
- `native-evidence-manifest-v1.json` binds 334 files: 112 PNG, 112 XML and 110 capture logs. SHA-256 `6B1EE5CCA392723F892B2C468AFBB7000986146234BB4C28A4959B8EDA9FCD20`.
- Capture002 tool presentation was truncated; existing PNG/XML were recovered without repeating the tap. Original command completion metadata is unavailable, so it is observational only. Commands003–112 completed exit0. PNG/XML are sequential, not atomic: 004 PNG is the transient loader and XML is the subsequently settled selector; 005 separately confirms the settled selector. The manifest is not blanket visual approval.

## Contact correction — tested native checks pass

- 008: contact draft values restored after retained-data installation; no app data was cleared.
- 009–013: incomplete phone, keyboard editing, Continue blocked with the full field-specific ten-digit instruction; corrected but unconfirmed phone asks for confirmation.
- 014–015: local review-gateway confirmation only. No SMS sent; server OTP delivery is not qualified.
- 016–020: malformed email receives its own full instruction, including above the physical keyboard (018). Correcting it clears the error; Continue asks for email confirmation without clearing phone confirmation.
- 021–026: local email confirmation; five-digit optional backup gets its precise instruction; ten-digit unconfirmed backup asks to confirm or remove it.
- 027–032: Back returns to Documents to keep ready; re-entry preserves values and independent confirmations. Editing the confirmed phone to an incomplete value then Cancel restores the original confirmed number. Backup text remains on scrolling.
- 033–034: removing the optional backup permits Business details. Fresh process-death verification persistence and real authentication are not inferred.

## Application support correction — tested native checks pass

Two separate Grocery/Kirana test applications were created through the form without documents or real submission. Their review-only references end in -1 (Store A) and -2 (Store B).

- 050–052: generic Workspace Review begins empty; a synthetic general unsent draft is retained in the inbox.
- 055–056: rejected A > Contact MoolSocial opens its exact business/reference and an application-specific draft, not the general draft.
- 057–059: A's intentional unsent edit is keyboard-safe; Back returns directly to A; re-entry restores its exact edited text.
- 063–069: explicit review-only Approved opens A's dashboard directly; Request another Workspace starts a separate same-type application while retaining confirmed contacts. No real admin decision changes.
- 077–080: B is submitted and explicitly set to review-only Rejected. Contact MoolSocial shows B's business/reference and fresh B draft, not A's edit or the general draft.
- 081–084: B's edit survives Back/re-entry, returning to B's status.
- 093–099: general draft remains unchanged after both application contexts; A's chooser separately lists B as Not approved; reopening B there restores its exact unsent draft.
- Approved A intentionally no longer exposes onboarding. Its draft was checked before B creation; subsequent native A-after-B reopening is **not** claimed. Pairwise state, async/retry, deliberate-empty and media/error isolation also have separately recorded host regression coverage.
- Nothing was sent or discarded. Drafts remain synthetic and unsent. Native failed-send/banner, attachment recovery, process-death Chat persistence, live backend support routing and authentication are not claimed.

## Genuine child — REG-4551 open, parked with dashboard first-tap review

086–089: Store A > Profile > Documents > Files; Back opens generic Workspaces; next Back opens Social YouTube. Expected return is the originating Store. Registered before continuing; source diagnosis/shared ownership are pending. No unrelated source edit or acceptance of this destination. Founder subsequently paused dashboard first-tap work until the pre-dashboard journey is qualified and closed; keep this child parked, not discarded.

## Premature first-tap observations — View statement paused

102–112: same Store A identity, one-tap entry, Today/Week/Financial year selection, Sales/Purchases/Expenses switching, complete Financial year label, Back to Store and re-entry work in the exercised empty-record state. Period survives tabs and dashboard round-trip; View statement intentionally reopens Sales. Final captured screen is Sales/Today (112). This destination was started too early: founder requires pre-dashboard closure first. Do not request its review or continue first-tap testing until that boundary is complete.

No fake transactions were added. Populated-record accuracy, real feeds, physical extreme-amount fit, Month selection and physical 200%/TalkBack are not qualified by this empty-state replay. No new defect observed in tested statement controls; first-tap visual approval is deferred, not granted.

## Qualification boundary

Requested contact/draft corrections pass the native scenarios above. REG-4550 severe-size error banner remains locally qualified; physical 200%/TalkBack/failed-send replay is pending. REG-4551 and seven exploratory test-contract dispositions in local-validation.md remain open. This is a non-promotable debug UI review, not a production-ready or all-journeys-defect-free claim.

The current pre-dashboard closure checklist is ticket-and-screen-coverage.md. Preserve previous visual approvals and earlier native evidence; explicitly resolve or retain each applicable interruption, document-provider, support-recovery, accessibility and backend boundary before claiming broader closure. This evidence checkpoint does not close those untested checks.

Cursor, Redmi, production approvals, real OTP/messages/WhatsApp/payments, deployment and integration untouched. No source change or rebuild during this review. An evidence patch using delete/add for one file was rejected atomically; use one Update operation and verify readback.

## Continued pre-dashboard document replay — captures113–153

The previously saved APK remains installed; these observations concern r66.11, not the unbuilt successor. The original334-file manifest is unchanged. External `native-evidence-manifest-v2.json` adds84 files (24 PNG,37 XML,23 logs;5,041,479 bytes), SHA-256 `08800A66D3FC8F32A9B7CCE2F3CC73D8196EFBBD0B397FE62962F9F2AD5183BB`, and binds the v1 hash. It is an integrity inventory, not blanket screen approval.

| Steps | Exercised boundary | Result |
| --- | --- | --- |
|113–120|Return from the prematurely started Statement to approved Store A; chooser resumes rejected Store B; labelled review-APK fixture explicitly requests clarification; open its document list.|Correct B/application context. No real admin decision or submission. Dashboard destinations were not continued.|
|121–131|Photo gallery > Android picker > local Codex screenshot album > selected image > native Done > View.|Selected QA image attached and displayed.127 was captured before native Done and correctly rejected the external foreground; only its capture log exists.129 confirms Done visually;130–131 prove the actual return and attachment.|
|133–135|Camera photo attached and View opened while founder was operating the phone.|Founder explicitly reported taking the photo and tapping View. The displayed Camera photo.jpg opens, but these steps are founder-assisted, not independent Codex completion evidence. The image contains a test desk surface, not a private document or person.|
|136–143|Replace > Camera; Codex shutter > native confirmation > X/retake > Android Back > source-sheet Cancel.|Existing Camera photo.jpg remains unchanged. Independent shutter/confirmation/retake/cancellation is verified; a separately accepted replacement photograph is not claimed.|
|144–150|PDF or image > native DocumentsUI > QA folder >10MB+1 negative fixture.|The complete10MB instruction appears and the original photo remains.145 had an Android null-root dump and produced no XML; the same tap was not repeated.146 is the fresh settled picker capture.|
|151–153|Select a96-byte plain-text file named.pdf > View.|**REG-4552 confirmed:** picker replaces the original photo and marks the file attached; existing Preview then rejects the missing PDF signature. This is a real failed replacement-preservation boundary, not a pass.|

The two negative files are labelled NOT-A-DOCUMENT, generated locally and copied only to `/sdcard/Download/MoolSocial-QA-r6611/`. Oversized fixture SHA-256 `3A8A8579BAD5EE1E17D5D730AC6085742F64341F18369EB97095C30049B0CF36`;96-byte fixture `46ECAE6B5DA37B08453510C217650340324C21F4CA1E3E72F78FDC35CC131B91`. No customer document was replaced or uploaded to a server.

REG-4552 is being corrected by validating the same PDF signature before save/replacement. Supplementary local visual inspection also registered REG-4553: source-sheet title and source names truncate at200%. That child preserves normal typography/layout and reflows choices only where the scaled readable width requires it. Neither fix is native-qualified on r66.11; both require the corrected, checksum-matched APK and a fresh OPPO replay. Remote cloud-provider completion, physical200%/TalkBack, actual server validation and other previously disclosed checks remain unqualified.
