# UAW C33K local Firebase CLI Auth deploy target unsupported

Date: 2026-08-15

Regression: `REG-20260815-2523-C33K-LOCAL-FIREBASE-CLI-AUTH-DEPLOY-TARGET-UNSUPPORTED`

## Finding

The source `firebase.json` now declares the current official
`auth.providers.emailPassword` field. A dry-run-only invocation of
`firebase deploy --only auth` was rejected locally with `No targets in
firebase.json match '--only auth'`. No deployment or external write started.

The current official Firebase documentation and schema expose the Auth target,
but the installed CLI surface does not. No CLI version update was attempted.

## Resolution rule

- Do not retry an unsupported local deploy target.
- Do not update tooling, obtain access tokens or call the REST API as a bypass.
- Preserve the source declaration and use the signed-in Firebase console only
  after the founder refreshes or reauthenticates the session.
- Count only authoritative console-table readback.

No Hosting, email, build, Play or device action was performed.
