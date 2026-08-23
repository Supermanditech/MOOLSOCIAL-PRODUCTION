# C30O Play Integrity Cloud-project visibility prerequisite evidence

- Date: 2026-08-12
- Play account: `supermanditech@gmail.com`
- Firebase / Cloud account used for read-only inspection: `hello@moolsocial.com`
- Dev project ID: `moolsocial-dev-503018`
- Dev project number: `760290687711`
- Play app ID: `4974778280277295872`

## Read-only findings

- Play Integrity API is already enabled in `moolsocial-dev-503018` (`playintegrity.googleapis.com`).
- The Dev project IAM policy has no binding for `user:supermanditech@gmail.com`.
- The signed-in Play Console account has no recent Cloud projects available in the link picker.
- Manual entry of exact project number `760290687711` leaves `Link project` disabled after blur and Enter validation.
- Google Cloud's predefined `roles/browser` is read-only and contains project discovery permissions including `resourcemanager.projects.get` and `resourcemanager.projects.list`.
- Because Play Integrity API is already enabled, `roles/serviceusage.serviceUsageAdmin` is not presently justified.
- The project is directly parented by organization `1067591230270`.
- The effective legacy Domain Restricted Sharing policy `constraints/iam.allowedPolicyMemberDomains` allows only Google Workspace customer ID `C02baohu3`.
- The enforcing policy is attached at organization `1067591230270` and was last updated at `2026-07-18T09:48:39.512425Z`; the project has no replacing allow-list policy and therefore inherits the organization restriction.
- `hello@moolsocial.com` holds `roles/orgpolicy.policyAdmin` on the organization, but the founder's attempted project override serialized as `allValues=DENY` with no allowed values. That is deny-all, not disabled, and the constraint does not support Deny All.

## Rejected discovery-only prerequisite

The founder granted:

`roles/browser` on `moolsocial-dev-503018` to `user:supermanditech@gmail.com`.

This made `MoolSocial Dev Trial` visible and enabled `Link project`, but the one authorized submission failed server-side with: `Project not found. Check it again or ask the project owner to add you as an owner of the project on the Cloud Console.` Therefore `roles/browser` is not a complete link prerequisite and must not be retried as if it were sufficient.

After the founder initiated the temporary Owner grant, read-only IAM reconciliation showed `roles/resourcemanager.projectOwnerInvitee`, not `roles/owner`. Google Cloud requires the invited user to accept the ownership invitation before the real Owner binding becomes active. No Play retry is allowed while the invite remains pending.

The preferred remediation is to invite `hello@moolsocial.com` to the MoolSocial Play Console app with the minimum app permission required to manage Play Integrity, then perform the link under the identity that already has Dev Cloud visibility. This avoids weakening organization security.

If that route is not operational, the bounded fallback is a temporary project-only `Allow all` override for this legacy list constraint, followed by the one `roles/browser` grant and immediate restoration to `Inherit parent's policy`. Never use `Deny all`, a blank custom value, or an organization-wide disable for this prerequisite.

The founder accepted the Owner invitation, Play linked `MoolSocial Dev Trial` project number `760290687711`, and a fresh Play reload proved the link persisted after cleanup. The temporary Owner and Browser bindings were removed, the account has no remaining project IAM binding, and the project again inherits the organization Domain Restricted Sharing policy. Final evidence: `docs/quality/UAW-C30O-PLAY-INTEGRITY-DEV-PROJECT-LINK-AND-TEMPORARY-ACCESS-CLEANUP-EVIDENCE-20260812.md`.
