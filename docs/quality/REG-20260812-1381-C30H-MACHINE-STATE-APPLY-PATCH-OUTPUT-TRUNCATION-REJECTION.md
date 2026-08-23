# REG-20260812-1381 — C30H machine-state apply-patch output truncation rejection

- Date: 2026-08-12
- Phase: C30H prebuild machine-state registration
- Candidate: `UAW-PERSONAL-MVP-SOCIAL-WATCH-RETURN-OPPO-REVIEW-C30H`
- Failure: The `apply_patch` result exceeded the available model context and was truncated, so the creation state of `config/apk-regression-gate-state-c30h.json` became unknown.
- Rejection: Never assume an interrupted or truncated mutation succeeded, and never blindly repeat it.
- Permanent prevention: Inspect only the exact target's existence, JSON parseability and bounded seal fields. Reapply only when absence or incompleteness is proved, using smaller patches. Run the permanent regression gate before resuming the build sequence.
- Protected state: No APK build, install, uninstall, data clear, downgrade, deployment, promotion, commit or push occurred because of this failure.
