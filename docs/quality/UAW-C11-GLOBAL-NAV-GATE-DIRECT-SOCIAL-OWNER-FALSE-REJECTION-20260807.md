# C11 global-navigation gate direct-Social-owner false rejection

Date: 2026-08-07

Regression ID:
`REG-20260807-244-C11-GLOBAL-NAV-GATE-DIRECT-SOCIAL-OWNER-FALSE-REJECTION`

The C11 placement gate passed, but the chained global-navigation gate rejected
Social because it still required `MoolGlobalNavigationV2` to appear directly
inside `social_v2_consumer.dart`. C11 deliberately composes Social through
`MoolDestinationNavigationV2`, whose final child is the unchanged global owner.

The implementation therefore preserved the product contract while the static
gate retained the superseded direct-composition assumption.

Permanent prevention: the global-navigation gate accepts the shared
destination-navigation composition only when the placement gate proves the
local shelf and the shared owner proves `MoolGlobalNavigationV2` remains its
final bottom child. It never requires destinations to duplicate that final
owner directly.
