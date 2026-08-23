# UAW-R16 Personal existing workspace reopen dependency hold

Date: 6 August 2026
Ticket: `UAW-R16-PERSONAL-EXISTING-WORKSPACE-REOPEN`
State: `DEPENDENCY_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R16 remains `mvp_required`, but it is not executable without the manifest's
`workspace_membership_owner`. The required customer outcome is to reopen one
existing permitted workspace by stable identity. The batch authority states
that this identity and membership are server-owned, and that the UI must never
recreate a workspace from a label or infer membership locally.

Repository inventory found no authoritative workspace-membership service,
contract or accepted stable-workspace record. The existing mobile Work session
contains simulated onboarding state and cannot establish server membership or
authorize an exact workspace. Adding a local workspace list, hard-coded ID,
label-derived route or optimistic membership would create a second authority
and violate the ticket boundary.

No source, reference, membership data, backend, build, APK or device action was
performed for R16. The ticket will be reassessed after the authoritative
workspace-membership owner publishes the permitted stable workspace identity
contract and safe reopen result.

Next child by manifest order for dependency disposition:
`UAW-R17-PERSONAL-ADD-ANOTHER-WORKSPACE`.
