# Social external reach and Creator Studio full-stack contract

- Status: **Founder approved product and engineering direction**
- Decision date: 21 July 2026
- Applies to: Social discovery, embedded external media, Creator account,
  Creator Studio, campaign distribution, channel analytics and attributed
  creator earnings
- Supersedes: conflicting handoff-only or blanket WebView wording in ADR-0002
  and ADR-0003 only to the narrow extent stated below
- Does not approve: Screen 04 `FINAL`, Flutter implementation, credentials,
  OAuth clients, API enablement, provider submission, Dev/Trial use, Staging or
  Production promotion

## Required outcome

MoolSocial will use two complementary loops:

1. **Stay and discover:** people watch MoolSocial-owned Reels and
   Posts/carousels plus eligible public YouTube Shorts and long-form video
   through an official embedded YouTube player without leaving the MoolSocial
   journey. MoolSocial does not host an owned long-form video format at MVP.
2. **Create and distribute:** eligible creators choose a campaign, prepare
   content in Creator Studio, publish through their connected external
   accounts and bring external audiences to attributable MoolSocial product,
   service or campaign destinations.

The commercial loop is:

`funded campaign -> creator content -> selected external accounts -> tracked
MoolSocial action -> order-line attribution -> fulfilled sale -> creator
commission`.

Creators keep any income paid by the external platform and may earn additional
MoolSocial commission from eligible MoolSocial sales. MoolSocial never pays for
external views, likes, comments, shares, follows or subscriptions.

This contract does not claim that Facebook, Instagram, X or YouTube becomes a
full external application inside MoolSocial. At MVP, YouTube is the only
approved external public media library for inline playback. Other launch
connectors distribute creator content outward and return interested people
through tracked MoolSocial links.

## Final platform decision

### Launch-critical, cost-first lane

| Platform | MVP customer value | Eligible account | Cost posture | Decision |
| --- | --- | --- | --- | --- |
| MoolSocial | Owned Reels, Posts/carousels, Promoted discovery, commerce and earnings | MoolSocial account; Creator/Business workspace for commercial tools | MoolSocial pays storage, processing and delivery | Build first; system of record |
| YouTube | Eligible public video discovery and official inline playback; creator channel upload and analytics | Google identity plus a separately connected YouTube channel | No YouTube video hosting/egress charge to MoolSocial; Data API quota and compliance apply | MVP priority 1 |
| Instagram | Publish eligible Reels/posts/carousels and read permitted insights | Instagram Professional Business or Creator account | No per-post price assumed; App Review, operations and media delivery still cost money | MVP priority 2 |
| Facebook | Publish eligible Page posts/video/Reels and read permitted insights | A Page the user is authorized to manage; never a personal timeline | No per-post price assumed; App Review, operations and media delivery still cost money | MVP priority 3 |
| WhatsApp Business | Opt-in product enquiry, order and support follow-up | Approved business sender and customer consent | Message charges and template/category rules apply | Separate commerce-messaging slice; never a public feed |

### Feature-flagged expansion lane

Threads, Pinterest, eligible LinkedIn accounts and Google Business Profile may
be added only after their individual account, permission, media, review,
analytics and cost proof passes in Dev/Trial. They are not launch blockers and
must not appear as enabled controls before their adapters are live.

### Deferred or excluded

- **X:** disabled by default. Its current API is pay-per-use and publishing a
  post containing a URL is materially more expensive than a plain create call.
  Enable it only behind a founder-approved budget, a campaign-funded cost rule
  and a hard spend limit.
- **TikTok:** excluded from the India MVP.
- **Snapchat and partnership-only networks:** later, after written access and
  an independent proof.
- **ActivityPub, Mastodon, Bluesky/AT Protocol:** optional later reach, not an
  MVP substitute for YouTube, Facebook or Instagram reach.

Provider policies, permissions, prices and format limits can change. The live
provider capability registry described below is authoritative at runtime; this
document defines the product boundary, not eternal provider values.

## Social viewing contract

### Native MoolSocial discovery

- The public Social surface remains MoolSocial-owned, media-first and native
  Flutter.
- Its approved discovery modes remain `For You`, `Following`, `Nearby` and
  `Promoted`; do not add a permanent row of external-network feed buttons.
- A feed item may be MoolSocial-owned or an eligible YouTube item. Source,
  creator/channel and sponsor disclosures must be unmistakable.
- Facebook, Instagram and X personal feeds cannot be silently aggregated or
  reproduced as if they were MoolSocial content.
- Like, Comment, Share, Remix and commerce actions belong to the individual
  content item, never to a fixed page-level action rail.

### Browsable YouTube library — required, not a single-video feature

The embedded player is only the playback surface for the currently selected
item. It is not the browsing interface. MoolSocial must provide a native,
paginated choice of many eligible YouTube videos:

1. `Shorts` presents a full-height sequence containing MoolSocial Reels and
   only positively classified YouTube Shorts. Each swipe replaces the active
   item while the next and previous choices remain native feed data.
2. `Videos` presents scrollable native YouTube thumbnails/cards for eligible
   long-form items. Tapping a card loads the official player in MoolSocial.
   `Feed` remains the MoolSocial-owned Post/carousel surface and does not act as
   a second YouTube video library.
3. A creator/channel surface may page through every currently available,
   public and embeddable item returned from that channel's uploads playlist or
   an approved public playlist.
4. Public discovery may include current India/category popular video and
   clearly identified YouTube search results that satisfy the provider's
   embeddable and syndicated filters.
5. A separately authorized YouTube-read connection may later show the user's
   subscription list and eligible uploads from those subscribed channels. It
   is optional, requires explicit consent and is not implied by MoolSocial or
   Google sign-in.
6. Search, channel, playlist and pagination controls must remain usable while
   playback is active. Selecting another item stops/releases the current
   player and loads the selected item; users never have to leave MoolSocial to
   choose the next video.

YouTube's public Data API exposes duration filters but no dependable general
`isShort` flag. `search.list(videoDuration=short)` means under four minutes and
must never be treated as proof that an item is a YouTube Short. A YouTube item
may enter the MoolSocial `Shorts` sequence only when classification is known
from one of these controlled sources:

1. a connected-creator upload prepared and distributed by MoolSocial, for
   which orientation, duration and upload date were validated;
2. a curated provider URL whose Shorts classification was independently
   verified and recorded in the catalog; or
3. a future official provider field specifically identifying Shorts.

Unverified short-duration YouTube items remain under `Videos`. At the current
provider boundary, a standard-channel upload on or after 15 October 2024 must
be square or vertical and no longer than three minutes to be categorized as a
Short; current provider policy must be rechecked at implementation time.

The Screen 04 video discovery labels map to real supply paths:

- `Discover`: MoolSocial-selected eligible public videos from approved
  playlists, creator uploads and cost-controlled cached metadata;
- `Popular`: `videos.list(chart=mostPopular, regionCode=IN)` with category
  filters where applicable;
- `Topics`: deliberate category or query results that pass embeddable,
  syndicated, region and availability checks; and
- `Channels`: creator upload playlists resolved from
  `channels.contentDetails.relatedPlaylists.uploads` and paged through
  `playlistItems.list`.

For public unauthenticated YouTube items, MoolSocial may offer its own Save,
Discussion, Share, Details and attributable commerce functions outside the
player. It must not imply that a MoolSocial `Like`, `Comment`, `Follow` or
`Remix` mutates YouTube. Any real YouTube mutation requires separate YouTube
authorization, explicit source identity and provider-compliant consent.
Commerce appears only when the content has a real campaign/product attribution
record and disclosure; it is never attached to every public YouTube result.

### YouTube metadata, account actions and MoolSocial revenue presentation

Founder direction recorded 21 July 2026 requires the production presentation
to use as much useful, currently supported public YouTube metadata as fits the
approved responsive hierarchy without reproducing YouTube's complete watch
page. The native MoolSocial video surface may show:

- video title, description, thumbnail, duration and publication time;
- channel title, channel thumbnail and public subscriber count when available;
- public views, likes and comment count when available;
- topics/tags, caption availability and the truthful embeddability/availability
  result needed by the player boundary.

Relative time and compact number formatting are MoolSocial presentation of the
authoritative values. Hidden or unavailable values are omitted or receive a
truthful unavailable treatment. MoolSocial does not invent a channel
verification badge, public dislike count, YouTube `Ask`, download, Premium/
ad-free entitlement or YouTube Home/Up Next recommendations.

YouTube source identity remains visible beside the item and inside the
unobscured provider-owned player. The surrounding browsing, MoolSocial actions,
commerce and advertising use MoolSocial branding. Reducing repeated YouTube
wording must never obscure the provider source or disguise a YouTube action as
a MoolSocial mutation.

Like, Comment and Subscribe require a separate, optional YouTube viewer-action
connection. Before connection, one compact customer prompt explains the three
benefits and names `Connect YouTube`. After connection, every action remains
user initiated, source identified and independently reversible where the
provider permits. This connection is separate from MoolSocial sign-in and from
Creator Studio's channel publishing connection.

MoolSocial-owned revenue may appear outside the player through:

- real campaign-linked `Products featured in this video` or service actions
  with sponsor/commission disclosure and order-line attribution;
- clearly labelled `Promoted on MoolSocial` placements that are visually and
  semantically separate from the selected YouTube item; and
- MoolSocial Save, Discussion, Share and Details actions that deepen discovery
  without pretending to change YouTube engagement.

No generic public YouTube result receives a fabricated product link. No
MoolSocial advertisement or commerce control may overlay, cover, alter or be
represented as part of the official YouTube player.

The target experience is the richness and choice of a modern video library,
not a visual or algorithmic copy of YouTube Home. YouTube does not provide its
personalized Home recommendation feed through the Data API. MoolSocial must add
independent value through owned discovery, local relevance, creator commerce,
service/product actions and attributable earning.

`Allowed video` means a video that is public, currently available to the
viewer, permitted for embedding/syndication and compliant with applicable
region, age, safety, made-for-kids and policy requirements. A creator who
connects a channel may explicitly opt eligible uploads into MoolSocial
discovery. Public API discovery may also return other videos whose YouTube
settings permit embedding; those remain clearly YouTube content.

For cost control, the default scrolling supply should favor one-unit metadata
paths such as creator upload playlists, approved playlists and regional
popular-video lists. Do not spend a `search.list` request for every feed scroll.
Use search only for deliberate user search, cache permitted metadata within
current YouTube retention rules and obtain audited quota before public scale.

### Narrow YouTube player exception

The app remains a native Flutter product. The only approved HTML/WebView
exception at MVP is a provider-owned YouTube embedded player:

1. The multi-item discovery library, cards, titles, channel information,
   source badges, loading, recovery, MoolSocial discussion and commerce actions
   remain native Flutter.
2. After a deliberate tap, the video plays from a direct official YouTube
   embed URL in an OS-provided Android `WebView` or Apple `WKWebView`.
3. The WebView contains no MoolSocial page, navigation, form, business logic,
   reviewer control or copied YouTube interface.
4. The request supplies the required stable app identity/referrer. Player
   branding, ads, controls and attribution remain YouTube-owned and unobscured.
5. No overlay may cover the player. MoolSocial actions sit outside it and are
   visually identified as MoolSocial actions.
6. Playback is user-initiated for MVP. Only one player may be active; it stops
   and releases when offscreen, replaced, backgrounded or disposed.
7. Minimum player size, fullscreen/orientation, audio focus, captions,
   accessibility and provider error codes are handled explicitly.
8. Removed, private, age/region-restricted, non-embeddable and unavailable
   items are skipped or receive a truthful recovery state.
9. MoolSocial never extracts, downloads, proxies, caches or permanently stores
   YouTube audiovisual media.
10. Children-directed status, consent, privacy disclosure and playback-data
    sharing must be handled under current YouTube policy and applicable law.

The server discovers only eligible public video and requests the minimum fields.
Search or candidate selection must check current embeddability, syndication,
availability, region and safety rules. MoolSocial provides its own discovery
value; it does not claim access to YouTube Home recommendations, watch history
or Watch Later. A separately consented subscription-list feature is permitted
only within the scoped boundary above.

## Creator account boundary

- A personal MoolSocial login proves identity only; it never grants channel
  publishing access.
- Creator distribution, campaigns, products to promote, connected channels,
  analytics, commission and payouts live under **Profile -> Creator account**.
- Business campaign funding, product/service ownership and audience/customer
  follow-up live under **Profile -> Business account**.
- Each external destination is connected separately with least-privilege OAuth
  and can be disconnected independently.
- The UI names the exact eligible object: YouTube channel, Instagram
  Professional account, Facebook Page or WhatsApp Business sender. It never
  uses the vague promise `social account connected`.
- Personal Facebook timelines and personal Instagram consumer accounts are not
  presented as API publishing destinations.

## Creator Studio publishing experience

Creator Studio supports two explicit paths. Both use the same server-side
validation, preview, consent, asynchronous jobs and evidence.

### Path A — choose destination first (default)

This is the safest and clearest route for a creator who intends to publish to a
specific platform:

1. Choose one destination.
2. Show the connected account, eligibility and exact supported content types.
3. Show current media, caption, link, disclosure, visibility and scheduling
   requirements before the creator selects or uploads media.
4. Choose `Reel`, `Video` or `Post/Carousel` only from formats supported by
   that destination.
5. Upload or select media.
6. Validate and prepare a destination-specific variant.
7. Enter the destination-specific title, caption, audience/privacy, sponsor
   disclosure and MoolSocial action.
8. Preview the real destination payload.
9. Confirm the named destination and account.
10. Show per-destination upload, processing, publication and recovery status.

This path must be the default. It prevents a creator from discovering format
incompatibility only after a large upload.

### Path B — Standard Publish

`Standard Publish` is the optional fast route for creators who want one
preparation flow across several compatible destinations:

1. Choose a controlled MoolSocial standard preset.
2. Select or deselect every compatible connected destination.
3. Upload once.
4. Generate and validate a separate variant and metadata payload for each
   selected destination.
5. Show one compact preview per destination and any required correction.
6. Allow a single final confirmation only after every selected destination is
   ready.
7. Publish asynchronously and report each destination separately.

`Publish everywhere` never means sending a blind identical file everywhere.
It means one customer confirmation after destination-specific checks pass.
Partial success is a normal outcome: one failed destination does not remove or
misreport successful posts elsewhere.

### Standard presets

The initial design may offer:

- **Standard Vertical Video:** a conservative vertical H.264/AAC MP4 master
  from which compatible Reel/Short variants are generated.
- **Standard Post:** a common image/carousel/text master for compatible social
  destinations. YouTube is excluded when the selected YouTube API does not
  support that post type.

Do not hardcode provider limits in Flutter. Duration, dimensions, aspect ratio,
file size, codec, carousel count, caption length, link behavior, audience,
privacy and disclosure constraints come from a versioned server capability
registry. The app displays the resolved current rules before upload.

## Full-stack architecture

### Native Flutter V2 responsibilities

- Social discovery and media cards;
- the isolated official YouTube player host described above;
- Creator/Business account entry and connection status;
- destination chooser and pre-upload requirement sheet;
- media selection/upload progress and recoverable cancellation;
- destination-specific editor and preview;
- Standard Publish compatibility and correction states;
- per-destination publish timeline, retry and partial-success result;
- channel analytics, attributable sales and creator earnings with source and
  freshness labels.

No provider secret, refresh token, eligibility calculation, payout amount or
authoritative publication decision belongs in the client.

### Backend services

1. **Provider capability registry** — account eligibility, formats, limits,
   required fields, permissions, review state, quota and cost posture.
2. **Connection service and token vault** — OAuth state/PKCE, encrypted tokens,
   scopes, expiry, refresh, revocation and disconnect audit.
3. **Media ingest service** — resumable upload, malware/file validation,
   checksum, ownership/rights declaration and short-lived source storage.
4. **Media preparation service** — probe, transcode, thumbnail/caption assets
   and one immutable variant per destination/preset version.
5. **Distribution orchestrator** — idempotent requests, durable queue,
   provider-specific jobs, backoff, rate limits, circuit breakers and cancel
   rules.
6. **Provider adapters** — YouTube, Instagram, Facebook and later providers;
   no provider-specific assumptions leak into shared UI state.
7. **Reconciliation service** — authenticated callbacks where available plus
   scheduled status reconciliation where callbacks are absent or uncertain.
8. **Analytics sync** — provider metrics with source, collection time,
   freshness and permitted retention.
9. **Commerce attribution and payout** — promotion identity, tracked link,
   order-line attribution, return-window hold and ledger owned by ADR-0003.
10. **Quota and spend guardrail** — provider quota, direct charges, media
    processing, CDN, message and retry spend with budgets, alerts and automatic
    feature stops.

### Minimum durable records

- `external_account_connections`;
- `provider_capability_versions`;
- `media_assets` and `media_variants`;
- `distribution_requests`, `distribution_jobs` and `distribution_attempts`;
- `external_publications` with provider identity and permalink;
- `provider_metric_snapshots`;
- `promotion_links`, order-line attribution and commission ledgers from
  ADR-0003;
- consent, disclosure, token, moderation and administrative audit events;
- provider quota and cost-ledger entries.

Every mutation has an idempotency key. Unknown provider outcomes reconcile
before retry. Successful external identities are never lost because a later
destination fails.

## Security, privacy and rights

- Keep client secrets and refresh tokens server-side in an encrypted managed
  secret/token store; never commit or return them to Flutter.
- Use least scopes, explicit provider consent and a separate connection from
  MoolSocial sign-in.
- Verify redirect state/PKCE, account ownership and the exact channel/Page/
  professional account selected by the user.
- Give users connection inventory, last use, disconnect and deletion controls.
- On revocation, stop new jobs, remove tokens within provider/legal retention
  rules and preserve only the minimum financial/audit evidence legally needed.
- Require media rights, sponsor/affiliate disclosure and campaign truthfulness
  before commercial distribution.
- Never incentivize YouTube playback or engagement. Creator commission derives
  from eligible delivered MoolSocial sales.
- Use signed, short-lived media URLs and deny public bucket access.
- Moderate MoolSocial-owned media and commerce independently of provider
  moderation.

## Cost and scale rules

- **YouTube playback:** YouTube serves the media. Embedded playback is not a
  MoolSocial video egress bill, but discovery/metadata uses quota and the app
  still pays its own backend and operational costs.
- **YouTube publishing:** default quota is a validation boundary, not a scale
  plan. As checked on 21 July 2026, Google's default allocation is 100
  `search.list` calls, 100 `videos.insert` calls and 10,000 units per day for
  other endpoints; it is subject to change and must be rechecked. Official
  embedded playback is not a YouTube Data API request, although discovery and
  metadata are. The founder accepts the MoolSocial API-project compliance audit
  as a required provider gate, not a product blocker. Do not create extra
  projects to evade quota.
- **MoolSocial-owned media:** measure ingest, storage, transcode and delivery
  cost per viewed minute. Apply explicit retention to funded/promoted media and
  lifecycle temporary cross-post masters after jobs, evidence and dispute
  windows allow deletion.
- **Meta publishing:** do not assume permanent zero cost merely because no
  per-post price is published. Budget app review, media processing, retries,
  monitoring and policy changes.
- **WhatsApp:** every initiated message path checks opt-in, category/template
  eligibility and the current rate before send.
- **X:** current official pricing checked on 21 July 2026 lists content create
  at USD 0.015 per request and content create with URL at USD 0.200 per
  request. Recheck the live rate. No production request is allowed without
  prepaid budget, per-campaign allocation and automatic cutoff.
- Cache permitted non-personal capability/configuration data, not raw provider
  media or stale personal analytics beyond allowed retention.

## Environments and proof sequence

The environment order remains:

`local mocks/emulators -> moolsocial-dev-503018 Trial -> Dev App Distribution
Preview -> moolsocial-staging-503018 -> later Production`.

No API is enabled merely because it appears free. Each real-provider step needs
action-time authorization and a credential restriction plan.

### Dev/Trial provider proof

Before an adapter is shown as available, preserve evidence for:

1. one eligible public YouTube item discovered and played inside the official
   player on the connected OPPO;
2. a paginated native YouTube choice surface populated from at least two
   supported source types, with multiple distinct selections replacing the
   active player without leaving MoolSocial;
3. unavailable/non-embeddable/private/removed YouTube recovery;
4. one private YouTube upload with title, description, privacy selection,
   processing result and revoked-token recovery;
5. one Instagram Professional Reel/post and permitted insight read;
6. one Facebook Page post/Reel with tracked MoolSocial link;
7. WhatsApp opted-in enquiry/order follow-up only when its independent budget
   and messaging slice is authorized;
8. every feature-flagged expansion connector before its flag can be enabled.

For every proof record account eligibility, scopes, review/audit state,
quota/cost, consent, token revocation, media requirements, partial failure,
analytics freshness, deletion/disconnection and actual provider identity.

### Real-user and interruption matrix

Test at minimum:

- fresh and returning Creator account;
- destination disconnected, expired and revoked while editing or publishing;
- upload paused by call, lock, app background, process death and network
  change;
- duplicate tap, timeout with unknown outcome, retry and cancellation;
- one destination succeeds while another fails;
- provider processing delay and later rejection;
- app restart restoration of in-progress and completed jobs;
- one active YouTube player, rapid feed scrolling, background/resume, audio
  focus, orientation/fullscreen and text scaling;
- YouTube item removed, private, non-embeddable, age/region restricted or
  blocked by player error;
- tracked link open, order attribution, cancellation/return and payout hold;
- cost/quota threshold crossing and automatic connector stop.

Evidence must bind the build, commit, environment, account class, provider
object, media checksum, request/job identities and observed result.

## UI and release gates

- The approved Universal bottom rail remains byte-for-byte unchanged unless
  the founder separately authorizes a correction.
- Screen 04 and Social are not `FINAL`; no reference is frozen and no Flutter
  work begins from this decision alone.
- Finish and obtain explicit founder approval for the first-layer HTML of all
  main Universal actions before native Universal implementation.
- Customer-facing UI contains only professional actions and outcomes. Never
  display internal terms such as API, adapter, scope, payload, job, provider
  proof, sandbox, sample, demo or test.
- Every displayed destination is actually connected, eligible and enabled.
- Every metric names its source and refresh time. External engagement is never
  presented as MoolSocial commission.
- Provider policy and pricing are rechecked at implementation, Dev/Trial,
  staging and production gates.

## Official implementation authorities

Recheck these sources before implementation because provider rules change:

- YouTube IFrame Player API:
  <https://developers.google.com/youtube/iframe_api_reference>
- YouTube required minimum functionality:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>
- YouTube developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- YouTube quota and compliance audits:
  <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
- YouTube video upload resource:
  <https://developers.google.com/youtube/v3/docs/videos/insert>
- YouTube public video resource and embeddability fields:
  <https://developers.google.com/youtube/v3/docs/videos>
- YouTube public search filters and pagination:
  <https://developers.google.com/youtube/v3/docs/search/list>
- YouTube playlist-item pagination:
  <https://developers.google.com/youtube/v3/docs/playlistItems/list>
- Current YouTube Shorts classification boundary:
  <https://support.google.com/youtube/answer/15424877?hl=en>
- Instagram content publishing:
  <https://developers.facebook.com/docs/instagram-platform/content-publishing/>
- Facebook Reels publishing:
  <https://developers.facebook.com/docs/video-api/guides/reels-publishing/>
- WhatsApp Business Platform pricing:
  <https://developers.facebook.com/documentation/business-messaging/whatsapp/pricing>
- X API pricing:
  <https://docs.x.com/x-api/getting-started/pricing>

If a provider authority conflicts with this document, stop that connector,
record the change and obtain a revised product decision. Do not fake, scrape,
reverse-engineer or route around a provider limitation.

Merchant Center and Google Ads Demand Gen are deferred Workspace integrations,
not Social launch connectors. Their absence must not block native Social
go-live. Public Social never exposes merchant catalog administration,
advertiser budgets or Google Ads account controls.

## Screen 04 founder-review interaction contract — 21 July 2026

The current Social HTML candidate implements the founder-directed discovery
and playback model without authorizing production implementation:

- `Shorts` is one continuous vertical sequence. MoolSocial Reels and only
  positively classified eligible YouTube Shorts share the same swipe surface;
  there is no separate YouTube-Short page and no large `Next` action.
- MoolSocial owned and paid/promoted Reels rank first in the representative
  sequence. Every sponsor and commission disclosure remains visible when the
  contextual engagement controls auto-hide.
- Native reel controls appear on entry, hide after a short viewing interval
  and return on a deliberate content-surface tap. Vertical touch/pointer
  swipe, wheel and keyboard up/down provide equivalent review behavior.
- `For You`, `Following`, `Nearby` and `Promoted` are real selection states and
  must change the content result, not only the selected-tab appearance.
- `Videos` is MoolSocial-owned discovery using eligible YouTube inputs. The
  current categories are All, Popular, Live, Learning, Local and Business.
  Tapping an item opens one official provider player state inside MoolSocial;
  Back returns directly to the native discovery list.
- Compact YouTube source attribution remains beside each YouTube result. It
  must not grow into a large badge that displaces content, and it must never be
  removed, hidden or disguised.
- MoolSocial promotions and campaign commerce are separate from YouTube
  result cards and the official player. No MoolSocial overlay may cover the
  player, and no public YouTube item receives fabricated commerce.
- Familiar mobile media-discovery principles are permitted; reproducing or
  passing off YouTube Home, recommendations, navigation or unsupported
  controls as MoolSocial is prohibited.

The verified candidate SHA-256 is
`D9444962A2E74D4F8A05E1DBF6929C5BD6D0C7A6D577E5C03B31797641DEE697`.
Automated evidence is recorded at
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-SWIPE-VIDEO-DISCOVERY-FOUNDER-REVIEW-20260721.md`.
The candidate passed 56/56 fitment rows and 24/24 interaction assertions with
zero console errors or failures. Founder visual approval is still pending;
this section does not mark Screen 04 `FINAL`, freeze a reference or authorize
Flutter, backend, provider or cloud implementation.

### Responsive player and metadata containment gate

The founder-reported 21 July 2026 correction adds a mandatory implementation
gate for Shorts and video watch states:

- measure vertical containment, not only document or horizontal overflow;
- keep the official provider player at least 200x200 and fully inside its host;
- prevent player, metadata surface and persistent navigation rail overlap;
- preserve portrait content with non-cropping presentation;
- expose channel, title and useful metadata on entry, with the remaining public
  record reachable through a bounded scroller and full `Details` sheet;
- support long titles, long descriptions, missing optional fields and 140%
  text without losing actions or attribution; and
- reserve the provider player for playback only. MoolSocial metadata, actions,
  commerce and advertising remain outside it.

The corrected candidate SHA-256 is
`A5307EB077E136B09064B40BB015C1856EE0B4A407F13CEA359B6303C75268B1`.
Evidence is recorded at
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-YOUTUBE-CONTENT-FITMENT-CORRECTION-20260721.md`.
This gate does not approve or freeze Screen 04.

## Superseding Screen 04 Social correction — 22 July 2026

This section supersedes the earlier auto-hide wording in the founder-review
interaction contract above:

- Shorts controls and creator/content details are visible on entry. They do
  not disappear on a timer. A deliberate content-surface tap may hide or
  restore the chrome; opening `More` keeps details visible until the user
  explicitly selects `Less` or dismisses them.
- MoolSocial Reels and eligible YouTube Shorts use one centred, icon-only
  `54×54` play-control specification. Long-form selected-video playback uses a
  separate provider-player boundary.
- `For You`, `Following`, `Nearby` and `Promoted` share one typography role.
  Video categories use that same role.
- Bottom-rail targets are at least `44×44`, do not overlap and keep the active
  action plus its next action visible after every selection. Horizontal swipe
  remains available.
- Feed owns immediate update/photo/poll posting. Create owns Reel, Carousel,
  detailed Post, Drafts, audience and scheduling. Both are available to every
  authenticated MoolSocial account; creator/business status gates only
  professional monetisation and distribution capabilities.
- The Data API does not supply a clone of personalized YouTube Home.
  MoolSocial must not copy or disguise YouTube navigation, recommendations or
  unsupported actions. Required source identity and the official player remain
  visible and distinct.

The current verified HTML candidate SHA-256 is
`5C18839F19DCB21982453A908BA96B75986B7ABCD963346F85BF765A44429A8D`.
Its expanded audit passes `1,441/1,441` with zero console/page errors. Evidence
is recorded at
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/SCREEN-04-SOCIAL-CORRECTION-V4-FOUNDER-REVIEW-20260722-02.md`.

This remains founder-review HTML. The ordered deployment authority is
`docs/delivery/SOCIAL-MODULE-GO-LIVE-CASCADE-20260722.md`: founder `FINAL`, new
immutable reference, native Flutter parity and OPPO acceptance, then real
YouTube integration in Dev/Trial before Staging.
