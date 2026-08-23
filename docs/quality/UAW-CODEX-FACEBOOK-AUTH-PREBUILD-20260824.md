# UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824

Founder date: 24 August 2026 IST
Lane: `codex_auth`
Work ID: `facebook-auth-prebuild-20260824`
Branch: `work/codex-auth/facebook-auth-prebuild-20260824`

## Objective

Establish production-grade Android Facebook authentication readiness from the
existing MoolSocial sign-in action through native Facebook Login, Firebase
credential exchange, authenticated session creation and MoolSocial state
transition, without performing a private provider login during prebuild work.

## Scope

- Reuse the existing Facebook contract, native SDK adapter, Firebase gateway,
  Android package configuration and shared authenticated-session owners.
- Identify a proven source, package/signing, Facebook application, redirect,
  SDK, Firebase or session gap before functional change.
- Preserve the accepted Google r60.87 path and prebuild-qualified email-link
  implementation.
- Retain sanitized stage/result telemetry without tokens, account identity,
  email, UID, app secret, client token, key hash or credential output.

## Exclusions

- No Facebook private login, account choice or consent by Codex.
- No production/Facebook/Firebase external mutation without an exact proven
  requirement and founder-held action.
- No Instagram, X, YouTube Connect or unrelated UI/backend implementation.
- No APK until every provider in the founder-authorized authentication batch
  passes all possible local/config/non-private runtime preflight.
- No AAB, Play upload, uninstall, data clear, real email/SMS or secret access.

## Prebuild acceptance

Focused source/analyzer/tests and Android/configuration checks prove the exact
Facebook flow, failure classification, collision/retry/session behavior and
all locally provable tuple relationships. Any private or external requirement
is reported precisely. Real Facebook and OPPO acceptance remains deferred to
the single combined authentication APK and is required before final ticket
closure or promotion.
