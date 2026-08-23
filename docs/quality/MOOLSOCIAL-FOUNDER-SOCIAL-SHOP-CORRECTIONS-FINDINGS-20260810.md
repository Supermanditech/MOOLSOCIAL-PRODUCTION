# MoolSocial founder Social and Shop corrections — bounded findings

Date: 2026-08-10
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Preserved authority and machine boundary

- The audit began in the founder-specified production repository and exact
  local dirty tree. The opening path-safe inventory recorded 381 modified
  tracked paths and 53,234 untracked paths; none was removed, reset, copied to
  another repository or replaced.
- C28D remains rejected. The installed OPPO CPH2375 package remains
  `com.moolsocial.app` version `1.0.0-r60.27` / code `2026081027`, APK SHA-256
  `E4651AEADFD2A98A7617021B8DEF645BC5D428DD1593D882D278F3706FF6BD0C`.
- The first C28D UIAutomator gate exported a 54 × 19 logical-pixel Mool node,
  below the 44 × 44 contract. No product correction in this batch authorizes a
  build, install, uninstall, data clear, downgrade, protected-runtime change or
  reuse of that rejected candidate.
- Any future APK candidate is a separate successor and must pass fresh host
  qualification before any build authority can be considered.

## Reuse, duplication and ownership findings

### 1. Redundant Social family-root cell

The exact owner is the shared `MoolDestinationNavigationV2` shell in
`apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart`. It injects a
fixed family-root cell between the compact Mool switcher and each destination's
local rail. Screen 04 separately supplies Shorts, Videos, Feed and Create from
`screen04Worlds`; therefore the injected Social cell is a navigation duplicate,
not a content owner. A Social-only omission reuses the shared shell, keeps the
Mool switcher and all four direct local actions in their existing reach zone,
adds no route and adds no tap.

Decision: MVP-required navigation correction, ready for formal preselection as
FSC01. There is no evidence that every family must lose its root: Shop still
needs its root to return from Wholesale or Orders after its redundant Products
cell is removed.

### 2. YouTube Shorts and Videos

The real local read path exists: the Flutter adapter calls the private-Dev
provider client, the provider exposes public discovery, channel enrichment and
official embedded-player owners, and App Check fails closed outside the named
Dev proof. The backend capability model defaults every YouTube capability to
disabled and allows public data only for a bounded proof or accepted public
review mode.

The current normal-build UI is not truthful: when
`MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF` is false, Shorts and Videos fall back to
hard-coded `_screen04Shorts` and `_videoCatalog` records. Those records cannot
be represented as YouTube content. The real client also has no durable evidence
in this workspace that an accepted public-data runtime is currently active for
the customer build.

Official requirements checked on 2026-08-10:

- YouTube content must be visibly attributed to YouTube, and YouTube logos must
  link to YouTube content or a YouTube component:
  https://developers.google.com/youtube/terms/branding-guidelines
- Embedded playback must use a supported player/WebView, preserve the player,
  meet minimum viewport rules and avoid overlays over controls:
  https://developers.google.com/youtube/terms/required-minimum-functionality
- Private user data and all modifying calls require OAuth 2.0; service accounts
  are not supported for YouTube accounts:
  https://developers.google.com/youtube/v3/guides/authentication

Decision: FSC02 is dependency-held. It may not claim customer availability
until the real public-data capability, App Check/runtime boundary, official
player, attribution, route states and focused API/UI tests pass together. Fake
fallback content must be removed as part of that ticket, never promoted as a
substitute.

### 3. MoolSocial Feed

Feed styling is MoolSocial-owned, but the default feed appends one hard-coded
representative `_FeedData` post in every mode. Session-published items are also
in-memory. The production app constructs `SharedSession()` with
`ReviewSharedGateway`, whose `execute` method only delays and records an
in-memory call.

Decision: FSC03 is dependency-held behind a truthful feed/read owner or an
explicit empty-state-only correction. It must remove representative posts and
remain visually separate from YouTube surfaces. No fake social graph, post or
engagement state may be added.

Founder addendum, 10 August 2026: FSC03 now includes a professional,
CTA-ready new Feed UI/UX candidate. The smallest lawful reference scope is an
empty-state-first MoolSocial design with a clear `Create a post` handoff to the
existing Create destination, plus truthful loading and retry states. This
addendum authorizes the editable founder-review reference only. It does not
authorize fabricated content, publication success or Flutter runtime work
before exact founder `FINAL`.

### 4. MoolSocial Create

The existing media picker, validation, text/image/carousel models and
workbench are reusable. The default publication owner is not durable backend
state, and the workbench also exposes Reel/poll/quiz formats beyond the founder
correction. The requested MVP outcome is text, one image and carousel posting.

Decision: FSC04 is dependency-held until a real authorized posting gateway,
persistence/readback contract, authentication/authorization, media lifecycle,
error/idempotency behavior and focused tests exist. The audit does not add a
second posting backend and does not present in-memory completion as published.

### 5. YouTube Shorts upload affordance

The repository contains private-Dev `beginPrivateUpload`, resumable transfer,
progress callbacks and processing reconciliation. It does not supply a
production-authorized upload surface with customer OAuth state, cancel state or
a server-revocable production gateway. The private proof returns a raw Google
resumable session to the device and intentionally forces private visibility.

YouTube requires an authorized `videos.insert` flow, resumable status/retry
handling, and upload clients must let users set title, description and privacy.
Unverified API projects created after 28 July 2020 have uploads restricted to
private viewing until audit:

- https://developers.google.com/youtube/v3/docs/videos/insert
- https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol
- https://developers.google.com/youtube/terms/required-minimum-functionality

Decision: FSC05 is stopped at the external/API gate. No `+` affordance or upload
claim will be added. Required authority is: approved YouTube OAuth consent and
`youtube.upload` scope for the connected channel, verified API-project/audit
disposition, production-safe session ownership, cancel/retry/progress and
post-processing state, plus focused API and UI tests. Credential access is not
part of this ticket.

### 6. Shop Products and Offers

Shop currently renders a shared Shop family-root cell plus a local Products
cell, and both route to `/app/buy?sub=shop`. This is a duplicate label/route
outcome. Genuine coupons and payment offers exist only inside catalogue/cart/
checkout transaction context; there is no independent Offers destination route
or tested customer outcome. Creating one now would duplicate contextual offer
content and change the accepted Buy model.

Decision: FSC06 will remove the redundant Products local cell and keep Shop,
Wholesale and Orders as the truthful model. It will not invent an Offers route.
The Shop family-root remains the one-tap way back to Shop from the other local
destinations.

## Sequential disposition

1. FSC01 — select and complete the bounded Social root-cell removal.
2. FSC06 — only after FSC01 gates complete, select and complete Products-cell
   removal without an Offers replacement.
3. FSC02–FSC05 remain separately registered and held at their exact authority
   or backend gates; none may be simulated or bundled into a navigation patch.

Machine-readable authority is in
`config/moolsocial-founder-social-shop-corrections-20260810-ticket-batch.json`.
