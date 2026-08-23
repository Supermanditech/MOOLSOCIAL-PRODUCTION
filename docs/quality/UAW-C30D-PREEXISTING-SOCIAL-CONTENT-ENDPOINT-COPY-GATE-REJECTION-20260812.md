# C30D pre-existing Social content endpoint-copy gate rejection

- Regression: `REG-20260812-1375-C30D-PREEXISTING-SOCIAL-CONTENT-ENDPOINT-COPY-GATE-REJECTION`
- Date: 2026-08-12
- Gate: `scripts/check-user-facing-copy.ps1`.
- Rejection: `apps/mobile/lib/features/shared/social_content_gateway.dart:441` contains the prohibited word `endpoint`.
- C30D boundary: the footer ticket does not edit this shared content/backend recovery owner. The exact context is audited before deciding whether a separately registered sequential customer-copy correction is required.
- The rejection is not waived and is not reported as a pass.
