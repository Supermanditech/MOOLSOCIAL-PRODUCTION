# UAW-INTEGRATION-REPAIR-SHOP-V2-R61-5-CURSOR-REVIEW-BUILD-20260828

State: `prebuild_repairs_passed_commit_pending`

- Work ID: `shop-v2-r61-5-cursor-review-build-20260828`.
- Branch:
  `work/integration-repair/shop-v2-r61-5-cursor-review-build-20260828`.
- Baseline: `2ff8062dee1027e25ca128c2df968d16896e434e`.
- Candidate: `UAW-SHOP-V2-R61.5-CURSOR-UI-REVIEW-20260828`.
- Version: `1.0.0-r61.5` / `2026082807`.
- Runtime profile: `CursorUiReview`.
- Package: `com.moolsocial.app.cursorreview`.
- Device: Redmi `TG8HCYTGGQT885OF` only.

Customer outcome: install the exact repaired Shop V2 UI-only candidate on the
founder's Redmi for final visual review of Shop landing, shared global profile
context, accessibility, proportions and Back recovery.

This is `mvp_supporting` build qualification. It may assemble prebuild evidence,
consume one debug build authorization, verify the APK identity, install in
place on the named Redmi and launch the UI-review runtime. It may not initialize
Firebase, call backend APIs, alter Android configuration, touch OPPO, install
`com.moolsocial.app.runtime`, promote an artifact or start another Shop
destination.

Required host evidence includes two successful complete Buy cycles, clean
source identity, protected Buy/Social/UI/brand gates, package isolation,
wrapper self-test and the exact runtime-define allowlist. Post-build evidence
must bind APK bytes and SHA-256 to the installed Redmi package before founder
review.

Prebuild qualification completed:

- final source manifest: `636` files, SHA-256
  `8512355AD08E1CC45731B7D8B97772AE9CE45360811D1FF68D9F496E28CF64E8`;
- format verification and focused analysis passed;
- R58.8.7 complete focused file passed with stderr `0` bytes;
- wrapper cleanliness self-test and Cursor package isolation passed;
- approved UI, Brand, protected Buy, protected Social, interaction, customer
  copy, backend-boundary and data-egress gates passed;
- the backend and clipboard allowances are restricted to exact accepted
  ancestor commits and byte-identical owners on this literal build branch.

Build attempt 1 was consumed and failed before APK creation because the Google
Services Gradle task still required an intentionally absent Firebase client
configuration. The founder then authorized one exact Android build-profile
repair: disable `processDebugGoogleServices` only when
`MOOLSOCIAL_ANDROID_DEBUG_PACKAGE=cursorreview`. Runtime, release, OPPO and
`com.moolsocial.app.runtime` behavior remain unchanged. A fresh authorization
is required after the repaired profile is tested and resealed.
