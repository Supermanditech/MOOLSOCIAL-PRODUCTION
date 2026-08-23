# C29P host qualification

## Result

`UAW-PERSONAL-MVP-SOCIAL-FEED-CREATE-AUTHENTICATED-PERSISTENCE-C29P` is source qualified. Dev Firebase deployment, connected-service qualification, a separately authorized APK build/install and OPPO founder review remain pending.

## Qualified customer contract

- MoolSocial Feed/Create production code fails closed unless the exact HTTPS Dev content endpoint is supplied at build time; no process-local review gateway remains under `lib`.
- Publish requires Firebase Auth plus a limited-use Firebase App Check token. Feed uses authenticated standard App Check. The backend derives author identity from verified Firebase Auth and accepts only Public MoolSocial content.
- Text, Image, Carousel, Image Poll, Quick Poll and Quiz are validated and durably stored. MoolSocial-hosted Reel/Short creation is rejected and remains a YouTube-hosted creator journey.
- A post appears locally only after backend acknowledgement. Retry reuses its idempotency key, concurrent candidates use unique media paths, and losing or rejected candidates clean only their own uploaded objects.
- JPEG, PNG and WebP size, hash and file-signature boundaries are verified. The decoded media ceiling is 20 MB inside a separately bounded 29 MB JSON request envelope.
- Feed uses a server cursor with loading, retained-content error, retry and load-more states. Like, Save and Vote persist; Reply and Repost remain explicit fail-closed actions, while Share performs the existing device share journey without fabricating a counter.
- Firestore and Storage direct-client rules deny all reads and writes; only the privileged backend service owner can persist data. The review fake exists only under test support and emulator sources are excluded from a future function bundle.

## Qualification evidence

- C29P source gate, MVP delivery lock, MVP scope gate and permanent regression memory gate: passed in both final cycles.
- Two fresh identical final cycles from the same source:
  - `dart format`: 9 files, 0 changes per cycle;
  - full `flutter analyze`: no issues per cycle;
  - 20 protected Flutter test files: 123 passed and 1 intentionally skipped per cycle;
  - backend strict typecheck: passed per cycle;
  - backend suite: 487 of 487 tests passed per cycle;
  - local Firebase Firestore/Storage emulator: 2 of 2 signed-in/signed-out direct-client denial tests passed per cycle using synthetic project `moolsocial-c29p-local`.
- Production dependency audit: 0 critical, 0 high; seven moderate advisories remain in the current official Firebase Admin Cloud Storage dependency lineage and are registered for contextual re-review before deploy.
- Stable 24-file source/test/gate aggregate SHA-256: `24E2D0BE9E67C34C77AA9652FB34EABC997001F19E2116B26C42900A34F4B3AA`.

## External Dev gate still required

Before a connected Dev APK can be built, a separately authorized external step must create/qualify the dedicated `social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` identity with minimum Firestore, Storage and Firebase Auth read permissions; deploy the deny-all Firestore/Storage rules and `moolSocialContent` function to `asia-south1`; verify Firebase Auth and Play Integrity App Check enforcement; and build with `MOOLSOCIAL_SOCIAL_CONTENT_URL=https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent`.

That gate must also rerun dependency review, exercise authenticated publish/feed/interaction against Dev, verify idempotency and media cleanup, then qualify a new APK candidate before any OPPO install. No credential value is required in source and none was read or copied.

## Protected runtime

No APK was built or installed. No app uninstall, data clear, downgrade, deploy, cloud resource write, provider message, secret access or protected evidence mutation occurred. OPPO `2b3e0f71`, installed `1.0.0-r60.34` (`2026081134`) and checksum `96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29` remain the protected baseline.
