# C30D historical C26D Social-projection literal rejection

- Regression: `REG-20260812-1374-C30D-HISTORICAL-C26D-SOCIAL-PROJECTION-LITERAL-REJECTION`
- Date: 2026-08-12
- Gate: `scripts/check-personal-social-shop-navigation-conformance-c26d.ps1`.
- Rejection: it requires the removed literal `bottomNavigationBar: MoolDestinationNavigationV2(` for Social.
- Current accepted owner: `_SocialOwnershipDock` in the conditional Social branch, proven by C29E/C29N/C30D widget tests for direct Home, Shorts, Create, Feed, Mool-left, Chat-right and exported target geometry.
- Disposition: retain the historical gate and do not restore the obsolete generic Social rail. The customer-copy gate from the rejected batch is run separately.
