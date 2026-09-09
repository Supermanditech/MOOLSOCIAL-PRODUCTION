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
