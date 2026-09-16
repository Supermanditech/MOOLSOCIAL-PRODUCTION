# Shop Chat r61.9 Cursor UI Review pre-build validation

State: `passed`

- Candidate: `UAW-SHOP-CHAT-CONTEXT-R61.9-CURSOR-UI-REVIEW-20260829`.
- Branch: `work/integration-repair/shop-chat-shared-v1-20260829`.
- HEAD: `e0b1ad3eace7094f9bc0e73ce7d36eb30dcfdb1c`.
- Version: `1.0.0-r61.9` / `2026082811`.
- Runtime profile: `CursorUiReview` debug only.
- Package/device: `com.moolsocial.app.cursorreview` on Redmi
  `TG8HCYTGGQT885OF` only.
- r61.7 is retained and rejected because Shop displayed a Food conversation.
- Corrected Shop context exposes only `shop-order`, `shop-partner` and
  `shop-offers`; Food/global conversations retain their prior contexts.
- Source manifest: `640` files; SHA-256
  `9A1D95F77A454287D7E069924FEC0235AD3ED252E7DB27EEF13D485559247A70`.
- Contextual Chat focused analysis: clean.
- Corrected combined shared/Buy Shop Chat tests: `95` passed, `0` failed.
- Full Buy cycle 1: `469` passed, `28` skipped, `0` failed;
  SHA-256 `FAB32E1DF62E9E40207137B5CEAC4BFB6F9C3F087E4C4E9E0FE5827F6B44EDB9`.
- Full Buy cycle 2: `469` passed, `28` skipped, `0` failed;
  SHA-256 `B0CFAFF0DAE1E6599182EAA78B574941939DE2F6B2DA6B5EB2AF37ED5EEF687B`.
- Firebase/backend initialization remains bypassed by the existing approved
  CursorUiReview profile; Android configuration is unchanged.
- r61.8 build authorization is consumed and preserved as failed at native
  library merge because the drive was full; no APK or install occurred.
- Generated caches were cleaned without deleting source/evidence and free disk
  was raised above the registered 6 GiB retry floor.

Authorized next action: consume one build authorization, install in place on
the named Redmi, verify checksum/version/cold launch/Shop context/Back recovery,
and stop for founder review.
