# C30O Play Internal Testing and YouTube compliance findings — 2026-08-12

## Founder disclosure

- Customer outcome: one production-grade release-signed Dev bundle distributed only through Google Play Internal Testing must prove distinct MoolSocial Feed/Create value, source-attributed eligible public YouTube discovery, official embedded playback and separately initiated read-only channel connection on the OPPO.
- Classification: `mvp_required`.
- Reason: the 2026-08-06 YouTube compliance follow-up requires a valid Android application link by the 2026-08-14 internal deadline; r60.40 cannot satisfy the current Play-recognized App Check route because it was ADB-sideloaded; the current production channel route exposes upload-purpose consent and an upload composer outside the declared reviewed use case; and the official embedded player is disabled in release builds.
- Minimum scope: reuse the existing route, connection, player, Feed/Create, App Check and gate owners; make only the read-only/no-upload and release-player corrections; qualify Play signing and App Check public certificate identities; produce one gated AAB; release/install only through Internal Testing; run the bounded OPPO matrix; prepare but do not send the reviewer response.
- Exclusions: no YouTube upload or mutations, no broad redesign, no Production/open/public track, no Staging or Production backend, no Hosting or provider deploy, no email or quota submission, no credential or private verdict access, no commit/push, no uninstall/data clear/downgrade, and no second build/install without a new exact ticket.

## Read-only reconciliation

- Branch: `remediation/prototype-conformance-2026-07-20`.
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`.
- Existing tracked, untracked and evidence state remains user-owned and preserved.
- OPPO: serial `2b3e0f71`, model `CPH2375`, installed `1.0.0-r60.40` (`2026081240`), SHA-256 `50A5CBA08A68895B3BCCCB235E5BD7209CBDDC45673BA5FC607F365C611F5121`, installer metadata `pc`.
- Active Dev revisions reconfirmed read-only: `moolsocialcontent-00003-juw`, `youtubeprovider-00036-qer`, and accepted callback `youtubeoauthcallback-00035-cir`.
- Play Console shows the Supermandi Tech Private Limited organization and no existing app under `supermanditech@gmail.com`.
- Firebase Dev ownership is `hello@moolsocial.com`; the local authenticated Google Cloud context matches that account and project `moolsocial-dev-503018`.
- Firebase Android identity remains package `com.moolsocial.app`, app ID `1:760290687711:android:4202409fd3ab38f6ce076a`.

## Bounded compliance findings

1. `social_v2_consumer.dart` exposes a `YouTube Short` action from MoolSocial Create and sends channel status to `/app/creator/youtube-connect`.
2. The production route resolves to `SocialYouTubeCreatorUploadScreen`, which requests `YouTubeConnectPurpose.upload` and renders private upload controls. This exceeds the submitted read-only connection and public discovery/playback use case.
3. The same existing route and gateway can own a connection-only presentation using minimum `youtube.readonly`, truthful status, disconnect, privacy, deletion and Google revocation controls. No new route or screen is necessary.
4. The official embedded player owner is implemented for debug/profile, while the release registrar is a no-op and Dart release guards disable it. A release AAB would therefore fail the reviewer playback journey unless the existing player owner is registered for release.
5. The current Android release build uses the debug signing configuration and no bounded repository upload keystore exists. One separate upload key and Play App Signing setup are required. Passwords and private-key material remain founder-controlled and must never enter evidence.
6. Firebase App Check for Play Integrity requires the Play app-signing certificate SHA-256 and the exact Play/Firebase project link. The Play app-signing certificate, not merely the upload certificate, is the identity installed on the OPPO.
7. The public pages already own canonical privacy, YouTube API use, disconnect and account-deletion URLs. The reviewer page contains stale candidate/link details and must not be represented as current until the exact Internal Testing link and evidence exist.

## Account and authority boundary

- Google Play Console: `supermanditech@gmail.com`.
- Firebase Dev project and authenticated Gmail: `hello@moolsocial.com`.
- Founder-visible password, MFA, upload-key password and account-switch checkpoints only.
- Console mutations remain held until the exact ticket, robustness/reuse, MVP, delivery and machine gates pass.
- Email and quota submission remain explicitly unauthorized.

## Acceptance hold

C30O is not complete until the one qualified Play-installed successor and all live Dev OPPO journeys truthfully pass. Any failed build, upload, install, account, App Check, reviewer or device attempt must be registered before a retry.
