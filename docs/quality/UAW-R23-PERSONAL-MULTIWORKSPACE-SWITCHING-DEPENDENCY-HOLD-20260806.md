# UAW-R23 Personal multiworkspace switching dependency hold

Date: 6 August 2026
Ticket: `UAW-R23-PERSONAL-MULTIWORKSPACE-SWITCHING`
State: `DEPENDENCY_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R23 remains `mvp_required`, but it is not executable without the manifest's
`membership_and_capability_owner`. Switching must preserve Personal-user
history while changing only the exact active workspace, and it must never leak
one workspace's rights into another.

Repository inventory found the qualified local `SUP-001` participant and
capability contract, but its handoff explicitly holds persistence and endpoint
ownership. It does not publish account membership, multiple stable workspace
identities, active-workspace revision or an authorized joined capability
projection. Existing local session state therefore cannot prove or safely
switch membership.

No source, membership/capability data, backend, build, APK or device action was
performed for R23. The ticket will be reassessed after the authoritative owner
publishes the permitted workspace set, per-workspace grants and safe switching
contract with stale/denied behavior.

Next child by manifest order for dependency disposition:
`UAW-R24-PERSONAL-WORKSPACE-LIFECYCLE-RECOVERY`.
