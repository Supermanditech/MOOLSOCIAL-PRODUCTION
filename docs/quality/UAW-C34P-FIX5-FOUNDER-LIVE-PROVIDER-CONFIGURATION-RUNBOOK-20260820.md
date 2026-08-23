# C34P FIX5 founder live-provider configuration runbook

Date: 20 August 2026 (IST)
State: provider preparation selected; founder-controlled actions pending

## Privacy boundary

The founder alone opens provider consoles and enters or views app/client
identifiers, client tokens, secrets, private keys, signing/key-hash values,
accounts, emails, phones, private links and OTPs. Codex must not view, type,
repeat, capture or store those values. Repository evidence records only the
boolean facts below, action counts and sanitized hashes/paths.

No real login, email, SMS, build, Play or OPPO action occurs in this runbook.

## Required order

1. Configure and read back the Dev Trial provider facts.
2. Configure the existing `moolSocialPublicAuth` Dev broker runtime.
3. Qualify App Check replay protection and Firestore abandoned-attempt TTL.
4. Run the local provider-readiness gate and all auth regressions.
5. Select the separately gated C34L Internal Testing candidate.
6. After Play activation, perform founder-assisted OPPO journeys one method at
   a time.

## Google and YouTube identity

Founder confirms in Firebase/Google/Play that Google Auth is enabled, Android
package and launch activity are exact, required debug/upload/Play signing
fingerprints are registered, the server-client relationship is correct and the
authorized return is exact. YouTube remains a second visible control using the
same Google identity and Firebase session, not a second OAuth provider.

## Apple through Firebase

Founder confirms the Firebase Apple provider, Apple App/Services configuration,
exact return, native capability and revocation configuration. Apple private
keys, team/service identifiers and client-secret material remain founder-only.

## X OAuth 2.0 plus PKCE

Founder confirms one OAuth 2.0 public client, the exact registered redirect,
authorization-code flow with PKCE S256, and only `tweet.read users.read`.
`offline.access`, OAuth 1 and a mobile client secret remain absent. Founder
enters the required Functions parameter/secret values privately and confirms
provider project readiness without exposing any value.

## Instagram professional login

Founder confirms the provider-supported Instagram professional-login product,
exact redirect, required app-review/live status and only
`instagram_business_basic`. Personal accounts remain ineligible; the accepted
classes are BUSINESS and MEDIA_CREATOR. Founder privately enters the server
runtime values and confirms transient-token revocation.

## Facebook native login

Founder confirms Facebook Login for Android, exact package/activity, debug and
release signing-key hashes, exact redirect, `public_profile` only, privacy
policy, data-deletion path, Graph permission revocation and the exact versioned
`/me/permissions` endpoint. App ID and client token are supplied only as hidden
build environment values. Email and every unrelated permission remain absent.

## Firebase passwordless Email Link

Founder confirms passwordless Email Link is enabled, the authorized domain and
continue URL are exact, and the Android return remains registered. No real
email is sent during provider preparation.

## Firebase Mobile OTP

Founder confirms Phone Auth, the allowed region policy, Play Integrity or
reCAPTCHA readiness and Play-signing relationship. No real SMS or phone value
is used during provider preparation.

## Existing public-auth broker deployment

Deploy only the existing `moolSocialPublicAuth` export to the Dev Trial after
founder-only runtime entry. Confirm the exact endpoint without query or private
data. Grant/read back the Firebase App Check Token Verifier IAM role for the
runtime service account. Configure and read back Firestore TTL for both X and
Instagram attempt collections using their existing expiry fields. No other
backend, Hosting, provider or Production deployment is included.

## Sanitized readback

The founder reports only `qualified` or `not qualified` for each fact in
`config/public-auth-live-provider-readiness-state-c34p-fix5.json`. Any failed or
unknown fact remains false. The readiness gate must reject until all required
facts are true and every build/Play/OPPO/private/email/SMS action count remains
zero.

## Release handoff

After provider readiness is green, C34L is requalified against the current
registry and source, its hidden-input launcher is extended only for the exact
required runtime/build value names, and one AAB may proceed through Internal
Testing. OPPO acceptance then runs Google, YouTube shared identity, Apple, X,
eligible Instagram professional, Facebook, Email Link and Mobile OTP
sequentially with the founder controlling every private surface.
