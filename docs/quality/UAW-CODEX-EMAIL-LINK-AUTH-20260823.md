# UAW-CODEX-EMAIL-LINK-AUTH-20260823

Founder date: 23 August 2026 IST
Lane: `codex_auth`
Work ID: `email-link-auth-20260823`
Branch: `work/codex-auth/email-link-auth-20260823`

## Objective

Establish production-grade MoolSocial email-link authentication end to end:
request link, same-device/deep-link return, Firebase credential acceptance,
authenticated Firebase session creation, session persistence and MoolSocial
authenticated-state transition.

## Scope

- Inspect and change only the exact email-link runtime, journey, Android
  deep-link and focused-test owners recorded for this task.
- Preserve the accepted Google Sign-In r60.87 path and all unrelated providers.
- Preserve exact safe Firebase failure codes and stage telemetry without
  emitting email addresses, links, tokens, credentials, UIDs, API keys or
  secrets.
- Never send a real email, perform a private login, mutate a production
  project, build an AAB, upload to Play or clear/uninstall device data.
- If Firebase Console, domain/Dynamic Links migration, OAuth, API restriction,
  credentials or a private founder choice is required, stop and request the
  exact founder action.

## Required sequence

1. Prove the current source/runtime/deep-link path and distinguish local proof
   from real-device/provider proof.
2. Identify a proven defect or external blocker before functional change.
3. Implement only the proven cause with focused negative and session tests.
4. Pass focused regression/preflight; do not build from an ambiguous result.
5. After explicit build authority, create one unique APK and perform one
   in-place OPPO test without uninstalling or clearing data.

## Acceptance

Founder enters an address on OPPO, receives and opens the real link privately,
Firebase accepts the credential, a Firebase user/session exists, MoolSocial
enters and persists authenticated state, sanitized telemetry reports no error,
and the accepted remote evidence-closure commit leaves the worktree clean.
