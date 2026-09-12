# Independent Redmi V6 prebuild evidence — in progress

Immutable frontend baseline: da4d266f97b4081f55bd98f1e9522f25bc8ee05f.
Admission-only commit: 7a9e0a291c969fc12aa961a0426aaaea6b9a08ce.
Branch: work/cursor-ui/redmi-v6-audit-20260913.
Device: Redmi TG8HCYTGGQT885OF; installed CursorReview 1.0.0-r66.9-cursorreview / 2026091101. No installation or user-data change yet.

Actual bootstrap gate passed before commit, exact five-file staged set; operational implementation gate then passed under /root/cursor_redmi_v6_audit_20260913 (subagent/cursor_ui). Source and working apps/backend/contracts compare equal to V6. No app/test/dependency/native/reference edit.

New actual checks passed: UI locks; protected-Buy integrated-review source; backend-boundary and data-egress integrated-review; App brand; Cursor UI review build profile/package isolation. Existing integrated-review source argument remains 10fb79b4469203371edf888e7d4b8aacb3546581. These results preserve the independent review's privacy/payment/provider/backend limitations; they are not production acceptance.

External receipts are in C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905, named redmi-v6-bootstrap-actual-v1-20260913.log, redmi-v6-operational-gate-v1-20260913.log and redmi-v6-check-*-actual-20260913.log. The complete Windows compatibility invocation finished exit 0 (session 65873). It passed compatibility and intended boundary outcomes; its expected protected-Social rejection is not a protected-Social acceptance.

Runtime source manifest: source-manifest.txt, 325 paths, SHA256 3C71822A4E8051AA469D0F07D3C406BB314A46F883E99D322973A6066F87F797. It covers tracked mobile lib, Android, assets and pubspec/lock owners. Unchanged V6 tests and other application paths are additionally bound by full apps tree equality, not inferred from this narrower manifest.

Inherited regression evidence (not fresh Redmi or new-checkout executions): V6's two completed cycles each 2501 passed, 83 skipped, zero failures; full analysis zero issues. Exact source equality supports retaining this evidence. Protected-reference exclusions remain additional excluded coverage. No device/backend closure follows from these results. Fresh build prerequisite checks and exact build-state binding remain required.

Motion disposition: existing V6 UI/motion reused; no new effect applied. Physical large-text, accessibility, motion and all public Buy journeys remain to be audited on the exact installed successor. Fixtures and unavailable authorities remain explicit. Original failed UI-lock result, the first isolated harness mismatch and all predecessor evidence are preserved externally.

Candidate reservation: UAW-CURSOR-REDMI-V6-REVIEW-20260913, build name 1.0.0-r66.19, build number 2026091301, debug CursorUiReview. No tracked APK record in this worktree uses this ID or number. Package remains com.moolsocial.app.cursorreview; runtime defines are UI_REVIEW_ONLY=true, DEVICE_REVIEW=true, USE_EMULATORS=true and this candidate ID, using the unchanged wrapper's MOOLSOCIAL-prefixed keys. This is non-promotable isolated review, not live authenticated authority.

Additional actual check: scripts/test-flutter-clean-support.ps1 completed exit 0 and reports Flutter tracked-support cleanliness guard passed. The new worktree was source-clean at admission and the guard's preservation tests passed. Build wrapper/profile and package-isolation behavior is covered by the actual test-cursor-ui-review-build-profile.ps1 pass. Original startup/config regression records remain in the unchanged 4584-entry registry; no new startup code was introduced. Runtime profile is the existing CursorUiReview configuration, not newly invented provider authority.

Inherited exact-V6 logs are retained under MOOLSOCIAL-POST-UI-AUDIT-20260905: cycle1 SHA256 3D26D9C92F8803EA7DE26D39573961E31540ADAB7906185C79D13968F457FC7C; cycle2 SHA256 133BD551CCD1032C563EA25E21DB41A6CE97E2AD1A5469C0BBEE33848CCC2A13; analysis SHA256 837A5B9CAA556BCDB327910F36305767DBBF3501FBD324AB2863FC66E2FCBDEE. Counts and scope above remain inherited host evidence, not fresh device results. No failed predecessor has been relabelled passed.

Prebuild input qualification is recorded above; the build wrapper's own actual preflight still must pass on its exact generated machine state. Pending: Git evidence seal, machine-state binding to that published source HEAD, wrapper preflight/build, artifact signer/hash validation and data-preserving Redmi installation. No APK has been built. Machine-state and build receipts are evidence generated for that source HEAD; a later evidence-only commit must not retroactively change the recorded build source.
