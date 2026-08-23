# C29U Dev Social backend deployment completion

Date: 2026-08-11

## Outcome

The exact sealed Dev Social backend is deployed to `moolsocial-dev-503018`:

| Owner | Revision | Runtime identity | State |
| --- | --- | --- | --- |
| `youtubeProvider` | `youtubeprovider-00033-tez` | `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` | ACTIVE |
| `youtubeOAuthCallback` | `youtubeoauthcallback-00033-wiz` | `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` | ACTIVE |
| `moolSocialContent` | `moolsocialcontent-00001-fef` | `social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` | ACTIVE |

All three are Node.js 22 in `asia-south1`, use the sealed entry points, 512 MiB memory and 120-second timeouts. YouTube is capped at one instance/concurrency one; Social is capped at four instances/concurrency twenty.

The YouTube functions retain exactly the five Secret Manager name bindings without reading values. The accepted public-data review profile is restored: public data true, owner connect/actions/assets/live/private upload/analytics false, the registered callback unchanged, and the bounded Dev quota caps unchanged. `moolSocialContent` has no secret binding.

## Security and persistence boundaries

- Firestore direct-client rules: deployed deny all; unauthenticated REST probe returned HTTP 403.
- Storage direct-client rules: deployed deny all; unauthenticated valid-prefix list probe returned HTTP 403.
- Default bucket: `moolsocial-dev-503018.firebasestorage.app`, `ASIA-SOUTH1`, Regional, uniform bucket-level access, seven-day soft delete.
- Social runtime: project roles limited to Datastore user, Firebase Auth viewer and App Check token verifier; bucket access limited to bucket-scoped Storage object user.
- All three HTTPS services use Cloud Run Invoker IAM check disabled so requests reach their application security boundary. Missing App Check returns HTTP 401 on Social and YouTube provider. An incomplete OAuth callback returns HTTP 400.
- No Production, Staging, provider submission, public/unlisted upload, secret value read, APK build/install/launch, OPPO mutation, commit or push occurred.

## Deployment recovery record

The first three-function command updated both YouTube functions and created Social, but Firebase could not apply the new service's implicit invoker IAM. Direct comparison showed the existing services use the current recommended Cloud Run `invoker-iam-disabled=true` model. The new Social service was made identical with `gcloud run services update moolsocialcontent --no-invoker-iam-check`; its application-level App Check rejection was then proven.

The legacy cross-repository YouTube verifier remains incompatible with the current accepted dirty tree because it stops on the unrelated `login-account-handoff` approved-UI lock before provider evaluation. It was not bypassed and no UI owner was changed. The current C29U sealed source gate, direct cloud metadata, deny-all probes and endpoint security probes are the admissible completion evidence.

## Gate disposition

C29U is complete and unblocks only C29M's founder-supervised, private-only upload proof. C29V build/install remains separately dependency-held. Installed OPPO `1.0.0-r60.34` remains protected and untouched.
