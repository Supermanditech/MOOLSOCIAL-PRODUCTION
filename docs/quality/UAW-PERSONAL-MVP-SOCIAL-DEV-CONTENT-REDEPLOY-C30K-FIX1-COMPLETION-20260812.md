# C30K-FIX1 Dev content redeployment completion

## Outcome

The exact Dev-only Firebase target `functions:provider:moolSocialContent` was
successfully redeployed to `moolsocial-dev-503018`. New Cloud Run revision
`moolsocialcontent-00003-juw` is ACTIVE, ready and receives 100% of traffic.

The deployed runtime remains Node.js 22 in `asia-south1`, with 512 MiB memory,
120-second timeout, concurrency twenty, maximum four instances and the exact
`social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` identity.
That identity retains only Datastore user, Firebase Auth viewer and Firebase
App Check token verifier project roles.

## Bounded deployment proof

- Deployment log SHA-256:
  `3018CA9AE681DBB91E93D614FCF1E385BFA92E95A326CBE0CBC991305B927D1C`.
- Upload package: 1.25 MB, with Dev corpus operator/runner sources and compiled
  output excluded.
- Cloud Run invoker IAM check: disabled, as required by the accepted
  application-security model; no public invoker binding was added.
- Unauthenticated function request: HTTP 401 from the application's Firebase
  Auth/App Check boundary.
- Firestore direct-client request: HTTP 403.
- Storage direct-client request: HTTP 403.
- `youtubeProvider` remained `youtubeprovider-00035-jis`.
- `youtubeOAuthCallback` remained `youtubeoauthcallback-00035-cir`.
- No rule, Hosting, YouTube function, Staging or Production deployment occurred.

## Source and test proof

- Node 22.23.2 backend suite: 499/499 passed.
- Final Firebase exact-target dry run: passed.
- `firebase-functions`: current patch 7.3.2.
- Source aggregate: 110 files,
  `42BFD0A47FD22C1E4142ED8E9CE85020BF958740057921C71250360CABA74C1E`.

The moderate transitive UUID advisory and its no-safe-upstream-fix disposition
remain documented in the predeployment qualification; there are no high or
critical npm advisories and MoolSocial does not use the affected UUID APIs.

## Protected device boundary

The rejected/preserved OPPO `1.0.0-r60.38+2026081238` identity and original
first-install time were not changed. No APK build, install, launch, uninstall,
data clear or downgrade occurred under C30K-FIX1. C30L is the separately
authorized successor qualification owner.
