# r66.14 OPPO review

Installed and checksum-verified; scoped real-user review is in progress, not qualified as a whole. Source HEAD 73c0a2840da4e038fc90a650b069467060eb27de; APK SHA-256 CF9457EB29F01FE7CCB78A036BC6F49657FC39EC99B498CD637816AC32679BD1; 210157569 bytes; OPPO CPH2375 / 2b3e0f71 / 720x1612 / physical font scale 1.0. Version 1.0.0-r66.14-runtime +2026091101. Install -r succeeded without data clearing; exact pm-path APK was pulled and independently hash-matched, including the lawful Android ~~ directory prefix. Redmi was not targeted. Build, install and checksum evidence are in the adjacent provenance and post-install owners.

## Native pass 1 — initial navigation and contact

External root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-14-native-20260911. Captures 001–009 comprise 18 PNG/XML files / 1751049 bytes. Sorted filename + space + uppercase SHA-256 rows, LF-joined without a final newline, have aggregate SHA-256 ACEF3C26817C0766EC8C47EC66AA3A15FD0925A36607B3101A36A94690E42E55. Captures remain immutable; later passes use new numbers.

- 001: cold launch succeeded into Shop. No cart, purchase or consumer action was taken.
- 002–004: observed Mool menu → Work → Workspace navigation. 004 PNG is the transient Opening your Workspaces state; its later XML is the settled selector. Do not treat that pair as a synchronized visual pass. Subsequent Grocery entry succeeded. No approved Store was restored in this review session; historical fixture approval is not production persistence evidence.
- 005/006: Grocery preview and settled re-capture are byte-identical. 006 was visually inspected: compact category tabs, expandable retailer concerns, pagination and Choose this Workspace are visible. Their deeper actions have not yet all been replayed.
- 007: Choose this Workspace reaches document prerequisites; Continue setup is reachable.
- 008: contact screen retains the existing operator name, previously entered number and QA email. Screenshot inspected. This proves retention of those observed values, not contact verification or all application data.
- 009: Send code accepted the retained 1111111111 under +91 and showed Sent to 1111111111 with the real numeric keyboard. Confirm remains visible. No code was entered or confirmed. RuntimeUiReview uses the isolated review gateway; no real SMS was sent.

## R6614-UAT-CONTACT-01 — open, deduplicated with REG4510

Primary mobile validation accepts the malformed retained number because sendPrimaryMobileOtp checks normalized length only (work_session.dart). Audit the primary, alternate and Continue guards together before the bounded correction; preserve independent authoritative verification, exact field feedback and changed-value invalidation. This is not a backend/SMS success. Native proof: 008-contact-retained.png SHA-256 A256B44F1E7A647F1818FA53A2D5DC5054B16EDBCC342B89139F01F3D2BC72FA; 009-invalid-phone.png 3068C4E413DA7E6E8E1678D802BBC7191D89B9D54379CC92E2CF705E72BE1D88; 009 XML 9E83C60B661C4A03B30FBA554404BA4C2DC38F391FA3B1CBA413F82FA5BC156F. Registered under existing REG-20260906-4510-WORKSPACE-NATIVE-CONTACT-AND-PICKER-FEEDBACK, not a duplicate parent ticket.

Next: complete remaining scoped native checks, deduplicate the complete UAT child list, then implement the authorized correction batch. The phone is currently on primary-code entry with the keyboard open; do not assume it is on the dashboard. No ticket is closed by this initial pass. Physical 200%/TalkBack, cloud-file completion, populated dashboard states and backend/shared-owner authority remain pending. Preserve the reviewed normal design.
