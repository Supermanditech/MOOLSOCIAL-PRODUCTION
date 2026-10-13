# r66.2 OPPO native review — completed defect-discovery round

Source: `595353d7fd74a29a60a86c8f15c0ff0a606643da`. Device OPPO CPH2375, serial `2b3e0f71`, 720×1612, density 320, font scale 1.0. Installed package/version/checksum verified in post-install.json. No Redmi/production package actions.

Native captures: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-2-native-20260906`. PNG and XML are retained, with hashes to be inventoried at close.

## Boundaries

ReviewWorkGateway is selected by the APK's UI-review bootstrap, with NativeWorkProofPicker. OTP 123456, administrative outcomes and operational fixtures are simulated; native interaction, keyboard, camera/picker, routing and rendering observations are real. No real OTP, document upload, admin notification, payment, order, GPS or production approval qualification is claimed.

## Observed children (not duplicate parent tickets)

- OPPO-R66.2-01 — Selector first-view density. Capture 05: on 360 dp / normal text, repeated introductory headings and vertical spacing leave the first Grocery selection clipped below the fold. Compact the existing hero/heading spacing without removing the approved five progress steps, benefits or accessible targets.
- OPPO-R66.2-02 — Contact OTP keyboard obstruction. Captures 13–16: sending a code leaves the code field below the current focus; after entering six digits, Confirm has only a 4-pixel visible sliver above the fixed Continue bar. Code submission via keyboard Done works, including rejection/retry. Keep the current contact/code action visible, retain safe areas, and avoid premature page Continue competing with verification.
- OPPO-R66.2-03 — Email typing observation to reproduce. ADB entered `review.owner@example.com`; displayed field became `review. owner@example.com`. Current email TextField uses default autocorrect. Verify with native IME and disable automatic correction/suggestions for email and OTP without mutating entered identity silently. A second address `qa@example.com` was retained exactly.

## Completed native checks so far

- OPPO-R66.2-08 — Continue store setup opens the legacy Set up your shop shell (54–58): obsolete Earn Today/Workspace bottom rail, duplicate top Chat/help affordances, oversized step cards and internal catalogue wording. Keep the existing setup validations/data path, but bring the first-tap setup destination into the Store context and compact its controls; no Buy source copying.
- OPPO-R66.2-09 — Store-off empty-state mismatch. After choosing Finish setup with store off, the centre says Your store is ready / New orders and urgent tasks will appear here (59), while status is off/private. Show the actual availability and the relevant next action, without implying customer orders can arrive when the store is closed/private.

- OPPO-R66.2-06 — Captured-document presentation: image_picker's generated `scaled_<uuid><digits>.jpg` occupies five broken lines in Review (42); preserve the real reference, but present a clear camera-photo filename/metadata without a random identifier dominating the table. Also replace the transient `Work profile sent for review` wording with `Application submitted`.
- OPPO-R66.2-07 — First approved Workspace uses the business category as its name. Native 53 shows Grocery / Kirana Shop instead of the entered Review Kirana. Source checkReview creates a first Workspace with selectedProfile.label, ignoring workName. Preserve the submitted business name after approval and existing Workspace identity on subsequent updates.

After native camera process loss, the already-tested synthetic contact/details values were restored via a guarded local VM fixture to continue coverage. Runtime package/version/PID, uiReviewOnly, ReviewWorkGateway and NativeWorkProofPicker are checked before mutation. Flutter attach provides expression evaluation only; no hot reload/restart was requested. Pending/clarification/rejected/approved outcomes are injected ReviewWorkGateway responses. The process-loss child remains open; this restoration is not its fix.

- OPPO-R66.2-04 — Document picker errors behind the modal. Capture 28: camera permission denial appears on the obscured parent, absent from the active modal's accessible content. Show the error with the retry/source choices; preserve cancellation and Android safe areas.
- OPPO-R66.2-05 — Camera process-recreation loses the Workspace journey. After choosing Only this time, OPPO revoked camera permission while its native Camera activity was foreground. Exact exit-info: 2026-09-06 05:07:57.583, old PID 31865, reason 8 PERMISSION CHANGE, description one-time permission revoked. New runtime PID 6477. Returning the captured blank/non-sensitive test image relaunched Shop instead of restoring the document step (captures 30–34). No force-stop, clear-data or uninstall was issued. Investigate account-scoped draft + pending document recovery; do not report this camera return as passed.

- Update install preserved app data; local and installed SHA-256 match.
- Mool > Work > Workspace navigation succeeded.
- Grocery benefits expand in the same selector and Choose this Workspace opens the prerequisites.
- Document list includes payout bank proof and nationwide GST applicability. All content reachable by scroll; Continue setup above Android navigation.
- Name and phone typing retained values. Invalid code does not confirm contact; review code confirms phone. Email code flow entered.

## Capture runner note

Captures 01–04 initially captured PNG before the route transition settled while XML was later. They remain preserved, not used as same-frame visual evidence. Added 650 ms animation-settle delay to the external capture helper; 05 onward uses settled captures. No product defect inferred from this capture timing.

## First-tap review additions

- OPPO-R66.2-10 — Work procurement host resets the nested Buy subtree when the keyboard appears (65–67); Search closes again and typed text is lost. Its overlay uses BlockSemantics, removing all Buy controls from the native accessibility tree, and a translucent Store rail reveals the obsolete Buy rail underneath. The Work host also forces text scale to 1. Fix only Work embedding: stable subtree, honest keyboard insets, opaque contextual rail, accessible content and inherited text scaling. Buy content remains provisional and Cursor-owned.
- OPPO-R66.2-11 — The top financial and right supply controls appear as non-clickable buttons in the native accessibility tree (68, 92, 99). Their outer Semantics excludes the InkWell action without providing its own onTap. Retain one label and one accessible action.
- OPPO-R66.2-12 — Bill review reserves almost the whole screen for a short order (82), repeating the rejected tall-form treatment. Use a content-sized, bounded sheet with a visible confirmation action; retain validation, payment truth, draft guard and Android/keyboard clearance. Minor consumer-copy corrections: `1 units` and `No all order needs action` (78, 82, 86). Compact the oversized generic empty states and manufacturer offer rows without changing their data or destinations.
- Extend 09: Alerts says `Your store is paused` while the actual state is off (87). Distinguish off, paused and private consistently.

Native successes: all three finance entries and their empty/disabled states (60–62); procurement Back to the same Store (68); Buy Direct and Group Bulk Buying (69–70); unpublished store-link honest unavailable state (71); Promote form (72); compact requirement selector, keyboard-safe editor and retained `Source rice` draft after Back/re-entry (73–76); Sell item quantity, live total, customer sheet and keyboard (77–81); unsaved-sale discard guard (83; filename says stock but the frame is the guard); Stock and complete product editor (84–85); customer Orders (86); Alerts/Profile/Operations/status/switcher (87–91). No actual invoice or offer was sent externally.

A guarded synthetic App pickup order exercised the real native controls: 60-second countdown (92), Accept changes the centre to packing (93), item checklist enables Mark ready (94), Ready requires pickup code (95–96), invalid code is rejected (97), valid review code completes the pickup and creates exactly one review invoice with the correct amount (98). Group offer fixture proves live side-rail information and the detailed price, quantity, deadline, delivery, fees and participant information (99–101). These are UI gateway simulations, not payment, GPS, customer, administrative or backend certification. The external fixture initially used `item.name` instead of the model's `title`; that failed before adding an order and was corrected after the exact model read. It is not a product defect or passed journey.

Children remain open until source correction and local/native retest. Founder appearance approval remains pending. Optional native gallery/cloud-provider completion and all real backend-dependent outcomes are not claimed as tested.

## Round preservation

The completed round contains 101 PNG/XML pairs (202 files). Exact filename, byte length and SHA-256 inventory: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-2-native-evidence-sha256.json; SHA-256 272835FABA145FED8A32FC83E42D7DFDD8925F30367BC2F6C4E51211587752A7. Captures 01-04 retain the timing caveat above. The 12 observations are grouped without duplication in REG-4509 through REG-4513. Corrections are being qualified for the separate r66.3 candidate; r66.2 is retained as defect evidence, not retroactively passed.
