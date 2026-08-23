# C09 Social world-query containment defect

Date: 7 August 2026

While reconciling the six stale Screen 04 tests, source inspection proved that
the production `/app/:section` router still passed
`state.uri.queryParameters['world'] ?? section` into `SocialUniversalV2`.
Therefore `/app/social?world=work` could revive the former Work-in-Social
presentation even though C03 removed Social's main-action ribbon.

REG-20260807-139 registers the escaped containment defect. The production
router now binds `initialWorld` to the canonical `section`; Social accepts
Social only, while Eat, Ride, Book and Work continue through their existing
native route owners. Query parameters cannot reactivate the removed owner.
