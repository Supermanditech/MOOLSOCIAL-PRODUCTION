# C30M Dev YouTube provider deployment and installed r60.39 live preproof

## Outcome

C30M's bounded Dev-only provider recovery passed. The real
`youtubeProvider` advanced exactly once from `youtubeprovider-00035-jis` to
`youtubeprovider-00036-qer`; the already-installed checksum-matched r60.39
loaded real current Shorts and completed playback of the first Short on OPPO.

This is not an APK acceptance. r60.39 remains rejected and preserved because
its immutable compile-time configuration still omits the MoolSocial content
endpoint. No APK was built or installed under C30M.

## Authority and exclusions preserved

- Project: `moolsocial-dev-503018` only.
- Region: `asia-south1` only.
- Deployer account: `hello@moolsocial.com`.
- Exact Firebase target: `functions:provider:youtubeProvider`.
- No Firestore Rules, Storage, Hosting, OAuth callback, content-function,
  Staging or Production deployment occurred.
- No password, token, API key, OAuth credential or Secret Manager value was
  read or copied.
- No commit, push, promotion, message, payment, uninstall, data clear,
  downgrade, APK build or APK install occurred.

## Provider-only control

The inherited private-Dev deployment owner was rejected because it targets the
provider, OAuth callback and Firestore Rules together and has two-service IAM
and rollback behavior. C30M introduced an exact provider-only control with:

- regression-memory, MVP execution-authority and delivery-lock gates;
- Firebase `--dry-run` before the mutation;
- required before-revision parameters for provider, callback and content;
- an exact one-function `--only` target;
- provider-only App Check invocation-posture restoration;
- callback/content before-and-after revision and runtime-identity invariants;
- provider-only prior-revision traffic containment on failure;
- no access-token printing or secret-value read path.

The pre-existing ignored PublicDataReview runtime file was preserved byte for
byte. Its 15 keys and values matched the deterministic accepted profile, no
secret assignment was present, and its metadata remained:

- length: `678` bytes;
- modified UTC: `2026-08-11T15:33:48.0724746Z`;
- SHA-256: `5AED3DD3D27EE82EDDC4B76FD2AAD2082EEDB3C7E8DEB3109F1FC798242E4702`.

## Qualification

- C30M focused provider-only deployment controls: passed.
- Existing private-Dev deployment-control contracts: passed for all seven
  capability profiles and hard containment, locally only.
- Backend TypeScript typecheck: passed.
- Backend build: passed.
- Complete backend suite: `499/499` passed with bounded dot output.
- Built Functions export inventory: exactly `moolSocialContent`,
  `youtubeOAuthCallback`, `youtubeProvider`.
- Tracked/untracked private-Dev package content scan: `162` UTF-8 files passed.
- Firebase provider-only dry-run: passed.
- Artifact cleanup policy: already deleting images older than one day; no
  change needed.

Sealed owner hashes:

- `shared_catalogue.ts`: `48E5655A6B4284A435AC8111F1B88C9E8AD47D5BCB7E07D15152920A9D75BF13`
- `index.ts`: `19A4DCB751A4E5E5862B25BD72B5CD02DDDFB0C566827C7272FF1371B67A0F95`
- `provider_service.ts`: `45BFEEA5BC592A6CBF8DE54B168FF8F43F87D97262DED5205D3EC2B23A40C341`
- `deploy-youtube-provider-c30m.ps1`: `B9674A62EC27F30BC878341C2E7ADAC74E08E5119DC386CE489E2E0F1E2ED187`
- provider-only control test: `5A955B751CF7556C21DD441539776F7E4CE409294C0697305B089BC6F9EDFE32`

## Independent post-deploy invariants

- `youtubeprovider`: latest created/ready
  `youtubeprovider-00036-qer`, 100% traffic, exact provider runtime identity.
- `youtubeoauthcallback`: remained `youtubeoauthcallback-00035-cir`, 100%
  traffic, exact provider runtime identity.
- `moolsocialcontent`: remained `moolsocialcontent-00003-juw`, 100% traffic,
  exact content runtime identity.
- No-credential provider request: HTTP `401`, `permission_denied`,
  `App verification is required.`
- Bounded revision-36 request logs during device replay: repeated HTTP `200`
  completions and no `ERROR` entries.

## OPPO live proof

- Serial: `2b3e0f71`, state `device`, model `CPH2375`.
- Installed identity preserved: `1.0.0-r60.39`, code `2026081239`.
- Installed APK SHA-256 preserved:
  `F1CED62759C9AC45CE790014397177D0921F2EC95958FC11AA71F949676D7DC3`.
- YouTube Home loaded real videos plus current Shorts.
- Shorts opened the first real NDTV India item rather than the prior truthful
  unavailable state.
- A user tap started the YouTube player; the OPPO frame showed `0:09 / 0:09`
  with replay state, proving completed playback.
- Accessibility exposed `Show player controls`; no commentary/debug copy was
  visible.

Evidence:

- `artifacts/quality/uaw-personal-mvp-social-c30m-runtime-recovery-20260812/oppo-r60.39-live-shorts-provider-r36.png`
  SHA-256 `616D81254EE366F03A1DA5636D6B4D0745363CC58B261ED5BEC7472E004255B5`.
- `artifacts/quality/uaw-personal-mvp-social-c30m-runtime-recovery-20260812/oppo-r60.39-live-shorts-playing-provider-r36.png`
  SHA-256 `42BE075AC9BFB74DB2D8B2CB3DB53D397DBEAC2E69029E4841AF043557CE8F18`.

## Remaining gate

Feed remains unavailable only in the immutable installed r60.39 because that
APK lacks `MOOLSOCIAL_SOCIAL_CONTENT_URL`. The source/build gate now requires
the exact Dev endpoint and rejects missing, empty, omitted or wrong-environment
values. A separately authorized fresh successor host qualification, one build,
one install and full OPPO founder review are still required. r60.39 and all
C28D/C30L evidence remain protected.
