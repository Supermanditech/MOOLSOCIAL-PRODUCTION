# PROFILE-B02: founder-approved Workspace placement amendment

Founder approved this behaviour on 27 October 2026 after reviewing the Personal/Workspace selector. This amends placement and activation guidance only. Original B02 contract SHA-256 44233B52F1FE9371D37BDE8476D8B6FA18305E5CCD2B9F20AC110514B22E2F9A remains unchanged as historical evidence.

## Approved behaviour

- Before a Workspace is approved, personal Plans may show Personal and Workspace. Workspace is an activation guide, not a Workspace subscription catalogue. Activate Workspace opens the existing registration/document journey.
- An existing pending application shows its actual status and View application, using the existing original application/status route. Never create another application or overwrite a draft to implement this shortcut.
- After Workspace approval, hide the Workspace promotional selector/guide from personal Plans. Personal identity, delivery addresses, buyer invoice profiles and personal subscriptions remain personal. My Workspaces stays available for opening/switching Stores.
- Inside an approved Store, Plans & billing opens only that Store's subscription catalogue and current subscription. Preserve an accessible route back to that Store. Reuse the existing Store profile menu entry instead of adding another permanent Store-home promotional lane.
- Document submission and MoolSocial approval precede Store activation. Approved free Store access is independent of subscriptions. Paid-feature activation requires no second human approval. Expiring/cancelling a subscription cannot remove otherwise-approved free Store access.

## Implementation and authority boundaries

Use the original Profile/My Workspaces routing, account recovery and B03 approval/application readback. Unknown or unavailable authority is not proof that registration is needed: show Check Workspace/View application as appropriate rather than inventing a missing application or new approval. An approved application with temporarily unavailable Store access must not encourage duplicate registration; only current verified Store authority permits opening Store plans.

Personal plans always query personal account scope. The pre-approval Workspace guide never queries Workspace billing or displays Store offers. Store plans use a separate existing-Workspace route guarded by current authenticated actor, approval and selected-Store authority, and query only its Store scope. Navigation/query parameters are not backend permission proofs. Backend readback continues to enforce current account/Store authorization independently of where a request originated.

If approval, account or Store changes while a guide/read is open, retire stale content and callbacks. Hiding the guide grants nothing. Keep missing-source, pending/rejected, approved-free, paid, expired and revoked-access cases distinct. Reuse existing cards/controllers and the compact branding; no new plan prices, benefits, free-AI allowance, seat-sharing rule, admin interface or payment writer.

All original B02 testing, data preservation, source/permission and deferred qualification requirements remain. Google setup/deployment, billing/provider connection/live charges, admin, APK, runtime source commits and pushes remain excluded. No production-readiness or formal ticket-close claim.
