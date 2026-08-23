# Social ownership redesign micro-ticket preselection

Date: 10 August 2026
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Founder direction and correction

The founder approved C28F r60.28, rejected the isolated FSC03 Feed HTML
candidate, supplied seven current YouTube journey screenshots from the OPPO,
and directed Social to proceed as four sequentially reviewable destinations:
YouTube Shorts, YouTube Videos, MoolSocial Feed and MoolSocial Create.

The screenshots are journey references only. They are not application assets
or evidence for a YouTube API submission. YouTube policy and the existing
MoolSocial contracts prohibit a pixel-for-pixel YouTube clone. The references
therefore inform familiar low-effort consumption and creation patterns while
MoolSocial retains distinct identity and independent value.

## Shared owner and duplicate audit

Existing owners are sufficient:

- editable HTML owner:
  `C:/GUARANTEED OUTCOME/supermandi-uiux-screenbook/screens/04-universal-focus-shell.html`;
- Social presentation owner:
  `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`;
- real public provider runtime:
  `apps/mobile/lib/ui_v2/social/social_v2_youtube_public_runtime.dart`;
- typed provider client:
  `apps/mobile/lib/core/youtube/youtube_private_dev_client.dart`;
- official player host and contract:
  `apps/mobile/lib/core/youtube/youtube_embedded_player_android.dart` and
  `apps/mobile/lib/core/youtube/youtube_embedded_player_contract.dart`;
- existing MoolSocial public-content and composer owners:
  `social_v2_public_content.dart`, `social_v2_create_workbench.dart` and
  `SharedSession`.

No new screen, route, backend service, API client, player or build is needed
for any of the four HTML reference tickets. Each ticket reuses Screen 04 and
the accepted Social destination rail. The tickets remain separate acceptance
units because their content ownership, visual language and failure contracts
differ.

The current Shorts and Videos references contain hard-coded provider-like
records when the proof runtime is disabled. Those records are not production
truth and cannot survive native implementation. The historical private-Dev
proof already established real public catalogue responses, positively admitted
Shorts and the official player; it is reuse evidence, not permission to claim
the provider is currently enabled.

## Micro-ticket order

### FSC02A — YouTube Shorts provider distribution reference

- Actor: authenticated Personal user.
- Outcome: browse and play real positively admitted YouTube Shorts through one
  official active player with clear provider attribution and recovery.
- Classification: `mvp_required`.
- Disposition: `reuse`, `configuration`, `test_only_acceptance`.
- New screens/routes/backend owners: none.
- Timeline impact: two engineering days; inside the 60–75-day lock.
- Active scope: HTML reference and browser evidence only.

### FSC02B — YouTube Videos discovery and watch reference

- Actor: authenticated Personal user.
- Outcome: discover real eligible long-form YouTube videos and open one focused
  official watch surface with supported metadata and recovery.
- Classification: `mvp_required`.
- Disposition: `reuse`, `configuration`, `test_only_acceptance`.
- New screens/routes/backend owners: none.
- Timeline impact: two engineering days; inside the lock.
- Execution remains closed until FSC02A receives founder `FINAL`.

### FSC03A — MoolSocial Feed X-informed ownership reference

- Actor: authenticated Personal user.
- Outcome: read and participate in an unmistakably MoolSocial-owned text,
  image and carousel Feed with truthful empty/loading/error states.
- Classification: `mvp_required`.
- Disposition: `reuse`, `configuration`, `test_only_acceptance`.
- New screens/routes/backend owners: none.
- Timeline impact: two engineering days; inside the lock.
- The rejected FSC03 candidate remains preserved and is not retried.

### FSC04A — MoolSocial Create publishing reference

- Actor: authenticated Personal user.
- Outcome: compose text, image, carousel, image poll, quick poll and quiz
  content in one MoolSocial-owned workbench with truthful draft and failure
  behavior.
- Classification: `mvp_required`.
- Disposition: `reuse`, `configuration`, `test_only_acceptance`.
- New screens/routes/backend owners: none.
- Timeline impact: two engineering days; inside the lock.
- Durable publish/readback remains dependency-held by an authoritative gateway.

## Permanent exclusions

- No copied YouTube screenshots, media, marks beyond permitted attribution, or
  exact YouTube trade dress.
- No fabricated YouTube video, creator, engagement, recommendation or upload
  result.
- No YouTube upload `+` until OAuth, `youtube.upload`, resumable transport,
  privacy/audience, progress, cancellation, retry, processing reconciliation,
  audit disposition and focused API tests pass end to end.
- No provider Like, comment or subscribe controls before separate OAuth and
  point-of-use action proof.
- No new route, screen, backend owner or duplicate Social implementation.
- No Flutter/runtime source, build, OPPO install, cloud, Firebase, credentials,
  external message, commit, push, deploy, promotion or Production write during
  an HTML reference ticket.

## Verification and gate sequence

Each ticket must pass HTML syntax, customer-copy, ownership/source-truth,
loading/empty/error/retry, 44-by-44 tap target and seven-viewport checks at
100% and 140% text. The exact candidate is shown in the browser and requires
founder `FINAL`. Only then may a new immutable reference be frozen and the
corresponding native ticket selected. A new APK candidate requires a fresh
host qualification and checksum-matched OPPO acceptance; accepted C28F r60.28
and rejected C28D evidence remain untouched.
