# C30T Dev provider and configuration completion — 2026-08-13

## Authorized boundary

Only the Dev project `moolsocial-dev-503018` and the exact C30T Social configuration/providers were changed. No Staging, Production, Play Production/open/public, Gmail or YouTube quota action was taken.

## Firebase Android restriction

The existing Firebase-created Android API key value was never read. Its Android application restrictions now preserve the prior `com.moolsocial.app` certificate and add the Play signer SHA-1 `078145A1EB2FFEC009192FF1E82DAED12FB1E8AC`. Read-only verification proved exactly two package/certificate application restrictions, 27 preserved API targets and the required Firebase/Play targets.

## Provider revisions

- Social content: `moolsocialcontent-00004-gig`.
- Chat: `moolsocialchat-00001-yaf`.
- YouTube provider, unchanged: `youtubeprovider-00036-qer`.
- YouTube OAuth callback, unchanged: `youtubeoauthcallback-00035-cir`.

The Social content and Chat services both use `social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`, have `run.googleapis.com/invoker-iam-disabled=true`, receive 100% traffic and return application-level HTTP `401` for unauthenticated POST probes.

## Remaining gate

The r60.45 one-build, one-upload and one-in-place Play-update counters remain zero. Prebuild fingerprint and release configuration qualification must pass before the founder-only hidden-input launcher is used.
