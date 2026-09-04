# Shop Chat r61.7 Cursor UI Review pre-build validation

State: `passed`

- Candidate: `UAW-SHOP-CHAT-SHARED-R61.7-CURSOR-UI-REVIEW-20260829`.
- Branch: `work/integration-repair/shop-chat-shared-v1-20260829`.
- HEAD: `4c9cda953a6544d3606083a971ed698c9486b321`.
- Version: `1.0.0-r61.7` / `2026082809`.
- Runtime profile: `CursorUiReview` debug only.
- Package boundary: `com.moolsocial.app.cursorreview` only.
- Device boundary: Redmi `TG8HCYTGGQT885OF` only.
- OPPO and `com.moolsocial.app.runtime`: forbidden and untouched.
- Source manifest: `640` files; SHA-256
  `0D1B8C0F43472991C25049FE6E33B27721377466D557744458FD4A72245B2070`.
- Focused shared Chat/Buy/profile analysis: clean.
- Shared Chat suites: `55` passed.
- Buy Shop Chat: `38` passed.
- Buy screen: `78` passed.
- Full Buy cycle 1: `469` passed, `28` skipped, `0` failed;
  SHA-256 `9EDB1DDA12F1A1681D902BF2E6B473B06AC7F150D85EB099700DEB09F081A0EC`.
- Full Buy cycle 2: `469` passed, `28` skipped, `0` failed;
  SHA-256 `6234C37EC7C077A9B87FBC9BE09E47DD0EC4F8E5778410AE3B060E671B5E4835`.
- Firebase/backend initialization remains bypassed through the existing
  approved `CursorUiReview` profile; no Android configuration changed.

Authorized next action: consume one build authorization, produce one uniquely
named debug APK, install in place on the named Redmi, verify package/version and
checksum, cold launch, inspect Shop Chat and exact Back recovery, then stop for
founder review.
