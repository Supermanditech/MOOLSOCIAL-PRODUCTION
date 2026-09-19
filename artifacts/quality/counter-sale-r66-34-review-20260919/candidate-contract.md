# Counter Sale r66.34 review candidate

Candidate: UAW-COUNTER-SALE-R66.34-REVIEW-20260919.
Ticket: UAW-COUNTER-SALE-20260919; CS-201 through CS-216.
Proposed version: 1.0.0-r66.34 / 2026091901.
Package: com.moolsocial.app.runtime. Build mode: debug.
Profile: uaw_runtime_ui_review_debug / wrapper RuntimeUiReview.
Branch: work/codex-ui/counter-sale-20260919.
Baseline: moolsocial-source-baseline-20260918-v2, 123ff42cf8179b272d33b480e8267dfa83af2de3.

Status: founder approved all v13 local screens and explicitly authorized
ticket-scoped Git commit/push, required integration and one nonproduction review
APK build/install after all gates pass. Machine build activation remains pending
current-source qualification and required integration. No APK has been produced
or installed and physical-device acceptance remains pending.

## Outcome and exclusions

Qualify the retailer's complete Counter Sale journey: customer/business typing,
inline product search/scanner, full Store Product add/return, review/payment
selection and invoice. Use the existing synthetic review Store. UPI QR encodes
the explicitly configured test destination and exact amount; it never confirms
payment. No real transaction, customer message, backend deployment, production
signing, Play upload, merge to main, release or production promotion.

Required defines are exactly MOOLSOCIAL_UI_REVIEW_ONLY=true,
MOOLSOCIAL_DEVICE_REVIEW=true, MOOLSOCIAL_USE_EMULATORS=true and this candidate ID.
Promotion remains forbidden_non_promotable. Only the existing guarded wrapper may
build it after all prerequisite checks and an exact one-build authorization.

## Authorization boundary requiring resolution before activation

Founder requested implementation, local testing and the full OPPO visual journey,
and granted narrow standing authority for ticket-specific gate blockers. This
record does not silently waive integrationRequiredBeforeSuccessorApk, cleanliness,
source sealing, provider, release or founder acceptance requirements. The later
explicit authorization includes required integration; retain that requirement,
complete it and bind the final candidate to the actual qualified integrated
source before enabling build/install. Final device acceptance remains unfulfilled.

## Evidence rules

Pin the exact committed source/evidence seal, current manifest, unique version,
toolchain and runtime defines before authorizing one build. Match the produced APK
hash, signer, package and version to the installed physical OPPO serial2b3e0f71.
Record actual action/result PNG+XML, not intended-action filenames. Keep original
failures and prior screenshots. Host tests/PDFs/QR captures are not OPPO evidence.
Founder acceptance must identify this exact candidate and full visual journey.
