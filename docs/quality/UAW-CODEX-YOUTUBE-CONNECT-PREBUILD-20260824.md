# UAW-CODEX-YOUTUBE-CONNECT-PREBUILD-20260824

Founder date: 24 August 2026 IST
Lane: `codex_auth`
Work ID: `youtube-connect-prebuild-20260824-v2`
Branch: `work/codex-auth/youtube-connect-prebuild-20260824-v2`

## Objective

Establish production-grade YouTube Connect prebuild readiness for the separate
Google OAuth channel-connection flow: explicit pre-consent explanation,
minimum authorized scope, backend OAuth attempt, exact Android/app return,
connected-state persistence, retry and disconnect. This ticket does not reuse
Google/Firebase application login as proof of YouTube channel authorization.

## Scope

- Trace the existing Connect action through the protected return purpose,
  Android return filter, mobile session state and Dev YouTube OAuth/backend
  contracts without performing a private authorization.
- Preserve accepted Google r60.87 login and the prebuild-qualified Email Link
  and Facebook branches.
- Verify token/credential redaction, state/PKCE/attempt integrity, exact return,
  connected/unconnected/reconnect truth and disconnect/revocation boundaries.
- Inspect unclaimed UI, core YouTube and backend owners read-only. If a proven
  defect requires a write outside the claim, stop and update ownership before
  changing it.

## Exclusions

- No private Google/YouTube account selection, consent or channel access by
  Codex.
- No OAuth secret, token, account identity, channel identifier or private
  provider value may be read or emitted.
- No YouTube upload scope, upload, final API submission, quota request,
  deployment, provider-console write or production mutation.
- No APK until all providers in the authentication batch are prebuild-green.
- No AAB, Play upload, install, uninstall, data clear, email or SMS action.

## Prebuild acceptance

All locally provable OAuth, return-route, session, retry, disconnect, privacy,
backend-contract and fail-closed checks pass without source changes unless a
specific defect is proven. Private YouTube consent and OPPO acceptance remain
deferred to the single combined authentication APK and are required before
final ticket closure or promotion.
