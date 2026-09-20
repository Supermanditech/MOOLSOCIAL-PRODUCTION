# Counter Sale r66.35 review candidate

Founder approved brand v26 and explicitly authorized the successor source/version
entry, preserving checks, followed by gated build/install and physical OPPO
Counter Sale testing. This is not production release or device acceptance.

- Candidate: UAW-COUNTER-SALE-R66.35-REVIEW-20260920.
- Version: 1.0.0-r66.35 / 2026092001; debug, RuntimeUiReview.
- Package: com.moolsocial.app.runtime; OPPO CPH2375 / 2b3e0f71.
- Qualified implementation: 8bfda8f862837bdc43910476a841befb750b6114.
- Approved apps tree: db194cd1baaba2783192faee52467ed67cfd83f2.
- Source manifest: 396 inputs, SHA256 FAA15FB27684C2E0446D3F3E97A0060B745C63EB23B8E735D8733BBCB411025F.
- Feature branch: work/codex-ui/counter-sale-20260919.
- Fresh integration: integration/moolsocial/counter-sale-20260919-v3 at
  C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-counter-sale-20260919-v3.

Exactly four APK defines: MOOLSOCIAL_UI_REVIEW_ONLY=true,
MOOLSOCIAL_DEVICE_REVIEW=true, MOOLSOCIAL_USE_EMULATORS=true,
MOOLSOCIAL_CANDIDATE_ID=UAW-COUNTER-SALE-R66.35-REVIEW-20260920.
EXPECT_REVIEW_PDF is a test oracle only, forbidden in the APK.

Manifest text uses UTF-8 without BOM and CRLF, matching this repository's Windows
checkout conversion. Verify its actual bytes again in integration; no global
Git settings or attribute rules are changed for this candidate.

Keep r66.34, its execution records and all prior evidence immutable. The tracked
machine JSON is a non-executable preparation template. Create a new
apk-regression-state.json.local only after clean remote-exact integration,
manifest and qualification validation, binding the real final integration HEAD.
Seal PreflightOnly in preflight-result.json.local; consume one attempt with an
exclusive create-new build-attempt.json.local before the wrapper invocation.
Never overwrite/reuse these execution records or bypass a failed gate.

All 13 prebuild gates need current evidence. Post-build gates remain pending
until actually observed. No real payment/message, production release, uninstall
or data clearing. Installed APK hash/package/version/signer must match the built
artifact. Preserve approved layout and palette; report any physical defects
before claiming device acceptance. Old CS-207 interpretation is superseded:
plus adds directly; product-name tap opens the full Product page.

Store-profile payment setup and authoritative UPI verification are still separate
dependencies. A QR or intent callback is not proof of payment. The review Store
has at most six catalogue products; large order counts are not 20/30/50 distinct
cart lines. These device cases need suitable fixtures and cannot be marked passed
from host evidence. Store Add Product and shared inventory integration are out
of this phase. Retained generic Store post-build gates are not silently waived.
