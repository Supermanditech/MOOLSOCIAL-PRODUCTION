# UAW-R18 Personal Admin-published type selection dependency hold

Date: 6 August 2026
Ticket: `UAW-R18-PERSONAL-ADMIN-PUBLISHED-TYPE-SELECTION`
State: `DEPENDENCY_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R18 remains `mvp_required`, but it is not executable without the manifest's
`exact_workspace_registry_family`. Customer selection must come from an
authorized, versioned Admin-published exact workspace registry; it may not be a
hard-coded enum or free-text customer type.

Repository inventory found only planning and governance references, including
`config/mvp-exact-user-type-scope-matrix.json`. That matrix explicitly states
that a registered-disabled type creates no implementation authority, and it is
not a live publication, eligibility or customer-selection owner. No Admin
publication contract, versioned registry response or authoritative family
projection exists in the repository.

No source, reference, registry data, backend, build, APK or device action was
performed for R18. Implementing customer choices from the planning matrix
would hard-code policy into the client and violate the ticket outcome. The
ticket will be reassessed after the exact registry family is published.

Next child by manifest order for dependency disposition:
`UAW-R19-PERSONAL-GEOGRAPHY-AUDIENCE-AVAILABILITY`.
