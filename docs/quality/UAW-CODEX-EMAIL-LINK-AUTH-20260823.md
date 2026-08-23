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

## Prebuild qualification — runtime acceptance deferred

- Implementation commit: `883f1d06c315438823c801b184b990b672c77f85`
- Disposition: locally qualified; real email, private login, APK and OPPO
  acceptance are deferred to the single combined authentication candidate.
- Focused analyzer: exit `0`; no issues.
- Focused suites: `5`; authored tests `37`; failed `0`; skipped `0`;
  terminal success; exit `0`.
- Safe Firebase codes are retained exactly; unsafe values normalize to
  `email-link-firebase-unclassified`; matching-address recovery and sanitized
  stage telemetry are covered.
- C33J, FIX4, FIX5, C33K, combined source and approved UI-lock gates passed.
- Approved UI-lock result retains the current splash for later founder/OPPO
  visual acceptance and reuses the accepted Google r60.87 baseline.
- Changed-owner secret scan: owners `14`; secret-value pattern classes `0`;
  secret-path risks `0`.
- Precommit dirty digest: bytes `1105`; records `14`; SHA-256
  `FA2B3BBFC11D557A30A71D043491D0303140367C62D528E9B6960681FC25EC80`;
  stderr bytes `0`; exit `0`.
- No build, device, provider, private, live-email or external action occurred.
- This record is not founder/OPPO acceptance and is not final ticket closure.
