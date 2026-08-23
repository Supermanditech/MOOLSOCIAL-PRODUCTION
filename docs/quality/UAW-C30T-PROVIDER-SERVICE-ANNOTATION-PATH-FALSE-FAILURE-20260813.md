# C30T provider service-annotation path false failure

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1888-C30T-PROVIDER-SERVICE-ANNOTATION-PATH-FALSE-FAILURE`

## Observation

Firebase successfully deployed the exact `functions:provider:youtubeProvider` target and the delegated owner verified fresh revision `youtubeprovider-00038-cic`. The outer C30T wrapper then failed while looking for `run.googleapis.com/invoker-iam-disabled` under revision-template annotations.

## Read-only qualification

- `youtubeprovider-00038-cic` is latest-created, latest-ready and receives 100% traffic.
- `youtubeoauthcallback-00035-cir`, `moolsocialcontent-00004-gig` and `moolsocialchat-00001-yaf` remain unchanged at 100% traffic.
- Public data and read-only owner connection are enabled.
- Owner actions, creator assets, live, private upload and owner analytics remain disabled.
- Accepted review mode is present.
- The service-level `run.googleapis.com/invoker-iam-disabled` annotation equals `true`.
- The ignored runtime was restored byte-for-byte to SHA-256 `5AED3DD3D27EE82EDDC4B76FD2AAD2082EEDB3C7E8DEB3109F1FC798242E4702`.

The authorized provider revision is therefore retained. Rolling traffic back would discard a correctly deployed, policy-bounded revision because of a verifier-path defect rather than a runtime defect.

## Correction

The wrapper now reads the annotation from Cloud Run service metadata and its focused static control requires that exact path.
