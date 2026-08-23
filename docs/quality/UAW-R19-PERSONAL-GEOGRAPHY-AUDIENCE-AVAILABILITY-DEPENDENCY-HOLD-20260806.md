# UAW-R19 Personal geography/audience availability dependency hold

Date: 6 August 2026
Ticket: `UAW-R19-PERSONAL-GEOGRAPHY-AUDIENCE-AVAILABILITY`
State: `DEPENDENCY_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R19 remains `mvp_required`, but it is not executable without the manifest's
`geography_and_audience_policy_owner`. The customer may see only exact
workspace types currently eligible for that person's published geography and
audience, and unknown or stale policy must fail closed.

Repository inventory found delivery rules, planning portfolios and isolated
service-area UI copy, but no authoritative versioned workspace-type
geography/audience policy contract or published eligibility projection. A
locally selected service area and the separate held Work publishing plan cannot
authorize workspace-type exposure.

No source, reference, location/audience data, backend, build, APK or device
action was performed for R19. Hard-coding a locality, using device location as
permission or treating a planning record as publication would create local
policy authority and expose ineligible types.

Next child by manifest order for reference disposition:
`UAW-R20-PERSONAL-WORKSPACE-BENEFIT-PREVIEW`.
