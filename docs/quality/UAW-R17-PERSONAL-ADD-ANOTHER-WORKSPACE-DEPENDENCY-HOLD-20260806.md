# UAW-R17 Personal Add another workspace dependency hold

Date: 6 August 2026
Ticket: `UAW-R17-PERSONAL-ADD-ANOTHER-WORKSPACE`
State: `DEPENDENCY_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R17 remains `mvp_required`, but it is not executable without the manifest's
`workspace_membership_and_request_owner`. The required journey must remain
separate from every existing membership and must not replace or duplicate an
existing workspace.

Repository inventory found the accepted separation rule but no authoritative
membership-and-request contract, no stable existing-workspace set and no
idempotent server request identity. The simulated mobile Work onboarding flow
cannot prove either membership or request uniqueness. Wiring it as **Add
another workspace**, inventing a local request identity or assuming that a
label is unique would create the duplication risk this ticket must prevent.

No source, reference, membership/request data, backend, build, APK or device
action was performed for R17. The ticket will be reassessed after the combined
membership and idempotent request owner publishes the exact safe entry
contract.

Next child by manifest order for dependency disposition:
`UAW-R18-PERSONAL-ADMIN-PUBLISHED-TYPE-SELECTION`.
