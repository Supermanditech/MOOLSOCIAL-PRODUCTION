# C30T YouTube read-only connection capability finding

Date: 2026-08-13
Candidate: `1.0.0-r60.45 (2026081345)`
Live provider: `youtubeprovider-00036-qer`

## Finding

The accepted Dev public-review runtime keeps public discovery active while `YOUTUBE_OWNER_CONNECT_ENABLED=false`. Backend source accepts the long-lived reviewer mode only when `publicData` is the single enabled capability. The provider must therefore reject connection start/status/disconnect operations even though the release route requests only `youtube.readonly` and defaults `uploadCapabilityAuthorized=false`.

This is a release blocker because the declared reviewer use case includes separately user-initiated read-only channel connection and user-controlled disconnect/revocation.

## Bounded correction

One exact Dev-only accepted reviewer set may enable only:

- `publicData`
- `ownerConnect`

It must keep `ownerActions`, `creatorAssets`, `live`, `privateUpload`, `ownerAnalytics`, `analyticsV2`, `reportingV1` and `publicOrUnlistedUpload` false. Proof-profile/expiry controls remain mutually exclusive with accepted reviewer mode. Wrong project, Staging, Production, malformed mode or any additional enabled capability must fail closed.

The correction is local source/configuration/test work only. No provider deployment, environment change, AAB, Play action, device mutation or external communication is authorized by this finding.

## Local verification result

- Backend typecheck and full verification: `503/503` passed, `0` failed.
- Focused release channel/account/callback Flutter tests: `14/14` passed.
- Static private-Dev deployment-control suite: passed for all supervised profiles, accepted review materialization, and hard containment; it explicitly performed no cloud command.
- Release route proof: `/app/creator/youtube-connect` omits `uploadCapabilityAuthorized`, whose default is `false`; the connection purpose is `YouTubeConnectPurpose.readonly`.
- Live provider remains unchanged at `youtubeprovider-00036-qer` with `YOUTUBE_OWNER_CONNECT_ENABLED=false` until separate Dev deployment authority is granted.
