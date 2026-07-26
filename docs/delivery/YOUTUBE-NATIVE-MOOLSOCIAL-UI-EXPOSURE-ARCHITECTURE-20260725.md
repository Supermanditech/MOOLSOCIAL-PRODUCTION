# YouTube native MoolSocial UI exposure architecture — 25 July 2026

## Record status

- **Status:** authoritative delivery architecture for the next editable
  founder-review cycle; not a frozen UI reference and not customer
  availability.
- **Environment boundary:** local disabled contracts, then
  `moolsocial-dev-503018` supervised proof only.
- **Presentation boundary:** native Flutter V2. The direct official YouTube
  IFrame Player in one isolated Android `WebView` or Apple `WKWebView` is the
  sole provider-HTML exception.
- **Current official-method audit:** 99/99 methods classified:
  - 87 have backend adapters, typed Flutter clients and local tests behind
    disabled capability controls;
  - 8 require provider programme, channel eligibility or partner authority;
  - 3 are excluded from customer exposure; and
  - 1, `liveChatMessages.streamList`, remains a pending safe server-stream
    bridge.
- **Not authorized by this record:** live customer traffic, blanket OAuth
  scopes, provider programme claims, Screen 04 mutation, founder `FINAL`,
  reference freezing, Flutter presentation changes, OPPO acceptance, Staging
  or Production promotion.

The binding delivery sequence remains:

`official inventory -> disabled local contract -> supervised private-Dev
proof -> editable HTML -> founder FINAL -> immutable reference -> native
Flutter parity -> physical OPPO acceptance`.

No YouTube-derived customer feature becomes visible merely because its method
exists or its local tests pass.

## Decision

MoolSocial will expose every **officially supported and product-relevant**
YouTube capability that the connected account, current programme entitlement,
current project quota and current YouTube policy actually allow. MoolSocial
may adapt its Social and Creator Workspace information architecture around
those proven capabilities.

This does not mean embedding or recreating the complete YouTube application.
The 99 official Discovery methods are backend plumbing. Several methods support
one customer action, while one destination can depend on several methods.
MoolSocial therefore presents a small number of coherent native destinations
rather than 99 API-shaped buttons.

The APIs do not provide a clone of personalized YouTube Home, the native
YouTube Shorts recommendation feed, Watch History, Watch Later, the YouTube
notification inbox, Community-post creation, Stories, arbitrary public
transcripts, raw audiovisual URLs or offline/background playback. None of
those outcomes may be promised, inferred or simulated.

## Permanent product boundaries

### Native app only

Flutter owns:

- all MoolSocial headers, search, filters, navigation and bottom rails;
- the native catalogue of videos, channels, playlists and live items;
- thumbnails, titles, provider metadata and source labels;
- loading, empty, restricted, disabled, revoked and recovery states;
- MoolSocial Feed, Create, Save, Discussion, Share, commerce, campaign,
  attribution and earnings;
- connected-account inventory and consent return states;
- Creator Workspace upload, asset, live and intelligence destinations; and
- accessibility, text scaling, device fitment and app lifecycle.

No MoolSocial page, form, account surface, navigation, reviewer control or
business rule may be delivered through HTML or a WebView.

### Sole isolated WebView exception

After a deliberate user selection, Flutter may host the direct official
YouTube IFrame Player in an OS-provided Android `WebView` or Apple `WKWebView`.
That host:

- contains only the provider-owned player bootstrap;
- uses the required stable app identity and origin/referrer;
- leaves YouTube branding, links, controls and advertising visible and
  unobstructed;
- has no MoolSocial overlay, commerce card, gesture layer or advertisement
  inside or over the player;
- does not download, proxy, extract, cache or retain YouTube audiovisual
  media;
- keeps at most one active player and stops/releases it when replaced,
  backgrounded or disposed; and
- maps provider events and errors back to typed Flutter state.

MoolSocial actions, metadata, commerce and advertising remain native and
visually separate outside the player.

### OAuth boundary

MoolSocial sign-in never grants YouTube access. A YouTube connection begins
only from a feature that needs it.

- Authorization opens in the system browser using Authorization Code with
  PKCE and returns to the native MoolSocial app.
- Google authorization never runs in the player WebView.
- The return must restore the exact pending native destination without
  fabricating success.
- The server stores encrypted refresh tokens. Flutter receives no client
  secret or refresh token.
- Scope escalation is incremental: read, viewer mutation, upload, analytics
  and live-management consent are not requested as one blanket grant.
- The account owner can see the exact connected channel, scopes/uses,
  connection health, last use, disconnect and retained-data deletion state.

### MoolSocial-owned Social boundary

- `Feed` and its Post, image, carousel, poll, quiz and discussion experiences
  remain proprietary MoolSocial products.
- MoolSocial-owned Reels remain a proprietary short-video product.
- Eligible, positively classified YouTube Shorts may appear in the continuous
  Shorts discovery journey, but each remains clearly identified as YouTube
  content and plays through the official provider player.
- MoolSocial does not host an owned long-form video format at MVP.
- Creator commerce, campaigns, order-line attribution, commission and payout
  remain MoolSocial-owned and cannot be inferred from YouTube engagement.

## Product information architecture

The destinations below are the only approved architecture into which the 99
methods may be exposed. Exact placement, typography, animation and interaction
details remain subject to provider proof, editable HTML verification and
founder `FINAL`.

### 1. Social — Videos catalogue

**Audience:** all eligible signed-out or signed-in MoolSocial users.

**Purpose:** help a user choose from many eligible YouTube videos without
leaving MoolSocial.

The native catalogue may provide:

- a MoolSocial-ranked starting selection from popular India/category results,
  approved channels, approved playlists and cost-controlled metadata caches;
- an explicit expandable search action;
- native filter choices derived from returned categories, languages, regions,
  live state and approved MoolSocial editorial groupings;
- paginated video cards with thumbnail, duration, title, channel identity,
  publication time and available public statistics;
- channel activities and public channel sections where they add real
  discovery value;
- public playlist and playlist-item browsing;
- public comment previews only where comments are available and appropriate;
  and
- truthful unavailable, removed, non-embeddable, restricted, quota and network
  recovery states.

The catalogue is never labelled `YouTube Home`, `Recommended by YouTube`,
`Your YouTube feed` or any equivalent personalized claim. Its ranking is
MoolSocial-owned and its supply is provider-attributed.

Deliberate `search.list` use is quota-sensitive. Default scrolling should
prefer lower-cost approved playlists, channel uploads, popular-video lists and
permitted caches rather than spend a search request on every refresh.

### 2. Social — Selected video

**Audience:** a user who deliberately selects an eligible catalogue item.

**Purpose:** play one selected provider video and expose its supported public
record without leaving the MoolSocial journey.

The destination contains:

1. the isolated official player;
2. native title, channel, publication time, duration, description and
   available public statistics;
3. source attribution adjacent to the item and the unobscured player;
4. native expansion for long descriptions and optional metadata;
5. a route to the native channel surface;
6. public comments/replies where returned and permitted;
7. MoolSocial Save, Discussion, Share and Details actions clearly labelled as
   MoolSocial actions;
8. an optional `Connect YouTube` entry for provider-owned viewer actions; and
9. another native MoolSocial-selected video choice after or beside the current
   item.

The next choice is not represented as YouTube's personalized `Up next`
recommendation. Selecting it releases the current player and loads the chosen
item.

Public metrics are shown only when returned. Hidden subscriber counts, missing
like/comment counts and unavailable fields are omitted; they are never
estimated. MoolSocial does not invent verification badges, dislike counts,
provider entitlements, downloads, ad-free playback or provider AI features.

### 3. Social — Shorts

**Audience:** all eligible MoolSocial users.

**Purpose:** one continuous vertical discovery journey containing
MoolSocial-owned Reels and only positively classified eligible YouTube Shorts.

For each YouTube item:

- source identity remains visible;
- playback uses the official provider player;
- swipe changes the native selected-item state and releases the prior player;
- creator, title and available details remain readable until the user
  dismisses or collapses them;
- YouTube viewer mutations remain behind the separate connection; and
- no MoolSocial action covers the player.

There is no dependable general `isShort` field. Duration or aspect ratio alone
is not enough. A provider video enters Shorts only when classification is
positively known through a MoolSocial-originated qualifying upload with
confirmed outcome, an independently verified approved collection, or a future
official field. Uncertain items remain in Videos.

This is not the native YouTube Shorts recommendation feed and must not be
presented as one.

### 4. Public channel

**Audience:** a user who opens a source channel from a catalogue, selected
video, comment or approved link.

The native channel surface may show:

- returned channel title, thumbnail, description and public statistics;
- public uploads resolved from the channel's uploads playlist;
- public playlists and playlist items;
- public channel sections and recent activities where returned;
- paging, empty and hidden-count states; and
- a `Connect YouTube` or provider-owned Subscribe action only when its exact
  connection and consent boundary is satisfied.

The channel surface is a MoolSocial presentation of permitted data. It is not
a copy of YouTube channel navigation or YouTube Studio.

### 5. Public live viewing

**Audience:** a user who selects an eligible live or upcoming provider item.

Public live discovery comes from supported search/video catalogue sources.
`liveBroadcasts.list` is treated as an owner-authorized Creator Live method,
not a public API-key catalogue shortcut.

The native public live surface may show:

- live/upcoming state, title, source channel and available public metadata;
- the official provider player;
- returned read-only live chat through bounded provider polling;
- chat disabled, empty, restricted, ended, delayed and rate-limited states;
  and
- native MoolSocial discussion or commerce outside the player when a real,
  independently valid MoolSocial record exists.

The current safe ordinary fallback is bounded
`liveChatMessages.list` polling that honours the provider interval. A
low-latency `liveChatMessages.streamList` experience must remain hidden until
the pending authenticated server-side gRPC bridge has bounded fan-out,
backpressure, cancellation, reconnect, cursor persistence and supervised
provider proof. Flutter must never hold the server credential or provider
refresh token to open that stream directly.

### 6. Account — YouTube connection

**Audience:** a signed-in MoolSocial user who requests a real provider-owned
action or creator capability.

The native connection surface shows:

- the exact selected YouTube channel;
- the requested capability in customer language;
- current connection state and the minimum additional consent required;
- the system-browser departure and native return;
- cancelled, denied, mismatched-channel, expired, revoked and delete-data
  recovery;
- separate viewer, upload, analytics and live capability status; and
- disconnect without implying deletion of content already published on
  YouTube.

MoolSocial cannot infer a connection from Google or MoolSocial login. Success
is accepted only after the backend validates the OAuth state, selected channel
and granted scopes.

### 7. Selected video — connected YouTube actions

**Audience:** a user who separately connects a YouTube channel and deliberately
invokes an action.

Supported product groupings may include:

- provider Like state and deliberate Like/Remove Like action;
- Subscribe/Unsubscribe for the exact source channel;
- provider Comment and Reply with explicit acting-channel identity;
- edit/delete of the user's own eligible comment;
- owner moderation in a separate owner-authorized discussion destination;
- Report with current provider abuse reasons and deliberate confirmation; and
- Save to a named YouTube playlist, including eligible playlist ordering and
  artwork management.

Every action names YouTube and the acting channel. Pending provider
reconciliation is not displayed as confirmed success. YouTube Like, Subscribe
and playlist actions remain distinct from MoolSocial reactions, Follow and
Save. No external engagement action earns a MoolSocial reward.

### 8. Profile — Creator Workspace — YouTube overview

**Audience:** a connected creator, not every consumer.

The overview may summarize:

- selected channel and connection health;
- uploads and processing states;
- owned playlists and assets;
- publishing eligibility and private-only audit restriction;
- channel appearance tools;
- live eligibility and live workspace entry;
- recent YouTube-sourced performance with refresh time; and
- MoolSocial campaign, attributed sales and commission in separate
  MoolSocial-labelled panels.

The overview does not reproduce YouTube Studio. It groups supported MoolSocial
workflows around the creator's connected channel.

### 9. Creator Workspace — Upload and video lifecycle

**Audience:** an authorized creator with upload consent.

The native flow:

1. confirms the exact YouTube channel;
2. selects media and records rights/audience declarations;
3. captures title, description, privacy and permitted scheduling fields;
4. initializes a resumable provider upload;
5. uploads bytes directly from the device to YouTube using only short-lived
   authorization material;
6. shows pause, retry, resume, cancel, processing and failure states; and
7. reconciles the returned video ID and provider processing result.

MoolSocial retains job/consent state and permitted metadata, not a permanent
duplicate of the YouTube-bound media. There is no separate Shorts upload API.
A qualifying vertical upload may be presented as intended for Shorts, but
MoolSocial cannot claim YouTube classified it as a Short until that outcome is
confirmed.

Until the required YouTube compliance audit permits otherwise, automated
uploads from the unverified project remain private. Public/unlisted controls
must not be customer-visible or simulated.

### 10. Creator Workspace — Video and channel assets

The native asset destinations may group:

- owned-video metadata update, scheduling/status reconciliation and delete;
- custom thumbnail;
- creator-owned caption list, download, add, replace and delete;
- public/owned playlists, items, ordering and playlist images;
- channel metadata;
- channel sections;
- channel banner; and
- channel watermark.

Destructive actions require exact target identity, explicit confirmation and
post-mutation reconciliation. High-quota caption and thumbnail operations
remain disabled until their independent quota and provider proof gates pass.
Channel appearance controls may be hidden when the connected channel or
current provider contract does not allow them.

### 11. Creator Workspace — Live Studio

**Audience:** an eligible connected creator after live-management consent and
capability probing.

The workspace may group:

- owned broadcast creation, scheduling, update, stream binding, transition,
  completion and delete;
- owned stream configuration and health;
- live-chat read/write;
- polls or supported message transitions;
- moderator inventory and role changes;
- participant bans and unbans; and
- provider-eligible monetization events only after entitlement.

Sensitive ingest data stays server-side or in a protected creator flow and
must never appear in logs, analytics or general Social state. Every live
mutation needs channel eligibility, exact actor/target, idempotency, recovery
and immutable moderation/audit evidence.

Provider-eligibility features are not shown as unavailable upsells. They are
absent until a successful capability probe proves that exact channel is
eligible.

### 12. Creator Workspace — YouTube Insights

**Audience:** a channel owner with analytics consent.

Native Insights may provide fixed, server-approved views for:

- content performance;
- audience/geography;
- device and playback context;
- traffic sources;
- audience retention;
- subscriber change;
- eligible Shorts and live performance;
- cards/end-screen outcomes; and
- MoolSocial campaign visits, delivered sales and commission in separate
  MoolSocial panels.

Every provider metric is labelled `YouTube` with a collection/refresh time.
Every MoolSocial order or earnings metric is labelled `MoolSocial`. YouTube
views, likes, comments or subscribers never determine MoolSocial commission.
Arbitrary Analytics query builders and monetary metrics remain outside the
customer app until separately approved.

Analytics groups and group items may support owner-created content collections
inside this destination after CRUD proof. They are organizational plumbing,
not separate bottom-navigation items.

### 13. Creator Workspace — Reports

**Audience:** a channel owner who needs delayed bulk operational analysis.

The Reporting API belongs in Creator Workspace, not realtime public Social.
The native destination may provide:

- available channel report types;
- a deliberate report subscription/job;
- job status and delete;
- available report periods;
- secure report retrieval and parsing;
- delayed-data and no-data states; and
- retention/deletion controls.

Reporting data is delayed and cannot drive realtime video cards or immediate
publication success. Secure server processing/storage, permitted retention,
operating cost and deletion must pass before the destination is visible.
Content-owner/system-managed reports must not be shown to an ordinary creator
connection.

## Capability and recovery state contract

Every provider-backed destination resolves a server-owned capability state
before rendering actions. Customer-visible states must be finished product
states, not engineering diagnostics.

| Internal state | Native customer outcome |
|---|---|
| `not_requested` | Show only the user-selected feature entry. Do not imply a connection. |
| `connect_required` | Explain the specific benefit and offer `Connect YouTube`. |
| `consent_in_progress` | Preserve the pending native destination while the system browser is open. |
| `consent_cancelled` | Return safely with the prior content and a non-blocking retry action. |
| `scope_missing` | Request only the additional permission required for the selected action. |
| `channel_mismatch` | Show the validated channel and let the user choose/reconnect. |
| `ready` | Render only actions proven for the exact channel and environment. |
| `loading` | Preserve layout and target identity; prevent duplicate mutations. |
| `empty` | Explain the real empty outcome without example content. |
| `partial` | Keep successful provider results and identify only the unresolved portion. |
| `processing` | Show upload/live/report processing as pending, never published. |
| `reconciling` | Keep the action pending until provider truth is known. |
| `rate_limited` | Preserve data, stop retry storms and show an honest later retry. |
| `quota_stopped` | Use a permitted cache where valid or stop the capability without fabricated data. |
| `provider_unavailable` | Keep MoolSocial-owned content usable and offer a bounded retry. |
| `revoked_or_expired` | Stop new actions, protect drafts and offer reconnect. |
| `ineligible` | Hide the unsupported action; do not imply the user failed. |
| `restricted_content` | Identify that the provider item cannot play here and return to catalogue choice. |
| `removed_or_private` | Remove stale playable claims and offer another item. |
| `made_for_kids_limited` | Remove unavailable engagement actions and preserve permitted playback/metadata. |
| `disabled_by_release_gate` | Do not render the provider control in customer UI. |

The interface must not expose internal words such as API, adapter, scope,
payload, quota units, proof profile, sandbox, test, cache key or provider job.
Those remain logs/evidence concepts.

## Attribution, commerce and advertising

YouTube attribution appears:

- adjacent to every YouTube-derived card or item;
- in channel and comment authorship;
- in every real provider-owned mutation;
- inside the unobscured official player; and
- in analytics/report source and refresh labels.

MoolSocial branding owns the surrounding app, discovery, Feed, commerce and
workspace. It must not remove required YouTube attribution to make content
look MoolSocial-owned.

MoolSocial commerce or advertising may appear only outside the player and only
when it is independently valid:

- `Products featured in this video` requires a real campaign/product
  attribution record;
- sponsor and potential creator-commission disclosure remain adjacent;
- an unrelated public YouTube result never receives a fabricated product
  action;
- MoolSocial promotions remain visually and semantically separate from the
  selected YouTube item; and
- no user is paid or incentivized for YouTube views, likes, comments, shares
  or subscriptions.

YouTube serves the provider audiovisual media. MoolSocial still owns the cost
of its backend, metadata, token custody, monitoring, moderation, commerce and
support. Public YouTube watching cannot be sold as a MoolSocial premium
entitlement.

## Complete 99-method product-capability mapping

This mapping is exhaustive for the pinned official Discovery inventory. A
method listed under a destination is an implementation dependency, not a
promise that the customer sees a matching button.

### A. Public catalogue, channel, playlist and video detail — 13 methods

**Native destinations:** Social Videos, Selected video, Public channel and
public playlist/detail surfaces.

- `activities.list`
- `channelSections.list`
- `channels.list`
- `commentThreads.list`
- `comments.list`
- `i18nLanguages.list`
- `i18nRegions.list`
- `playlistItems.list`
- `playlists.list`
- `search.list`
- `videoCategories.list`
- `videos.batchGetStats`
- `videos.list`

These methods supply MoolSocial-ranked discovery and returned metadata. They
do not supply personalized YouTube Home or native Shorts ranking.

### B. Connected viewer library, discussion, safety and provider actions — 23 methods

**Native destinations:** Selected video's `YouTube actions`, named YouTube
playlist management and owner-authorized discussion moderation.

- `abuseReports.insert`
- `commentThreads.insert`
- `comments.delete`
- `comments.insert`
- `comments.setModerationStatus`
- `comments.update`
- `playlistImages.delete`
- `playlistImages.insert`
- `playlistImages.list`
- `playlistImages.update`
- `playlistItems.delete`
- `playlistItems.insert`
- `playlistItems.update`
- `playlists.delete`
- `playlists.insert`
- `playlists.update`
- `subscriptions.delete`
- `subscriptions.insert`
- `subscriptions.list`
- `videoAbuseReportReasons.list`
- `videos.getRating`
- `videos.rate`
- `videos.reportAbuse`

Comment moderation is shown only to an authorized channel owner/moderator.
Playlist and provider Save actions remain distinct from MoolSocial Save.

### C. Creator publishing, owned-video and channel assets — 16 methods

**Native destinations:** Creator Workspace Upload, Video assets, Captions and
Channel appearance.

- `captions.delete`
- `captions.download`
- `captions.insert`
- `captions.list`
- `captions.update`
- `channelBanners.insert`
- `channelSections.delete`
- `channelSections.insert`
- `channelSections.update`
- `channels.update`
- `thumbnails.set`
- `videos.delete`
- `videos.insert`
- `videos.update`
- `watermarks.set`
- `watermarks.unset`

Upload and asset methods stay disabled until exact-scope, rights, media,
quota, destructive-action and provider-reconciliation proof passes.

### D. Public live read plane and Creator Live Studio — 20 methods

**Native destinations:** Public live viewing and gated Creator Live Studio.

- `liveBroadcasts.bind`
- `liveBroadcasts.delete`
- `liveBroadcasts.insert`
- `liveBroadcasts.list`
- `liveBroadcasts.transition`
- `liveBroadcasts.update`
- `liveChatBans.delete`
- `liveChatBans.insert`
- `liveChatMessages.delete`
- `liveChatMessages.insert`
- `liveChatMessages.list`
- `liveChatMessages.transition`
- `liveChatModerators.delete`
- `liveChatModerators.insert`
- `liveChatModerators.list`
- `liveStreams.delete`
- `liveStreams.insert`
- `liveStreams.list`
- `liveStreams.update`
- `liveChatMessages.streamList`

Nineteen methods have disabled local adapter/client/test coverage.
`liveChatMessages.streamList` is the one outstanding ordinary-method gap and
has no customer exposure until its safe server-side bridge and supervised
proof pass. `liveBroadcasts.list` belongs to the owner-authorized workspace;
public live catalogue discovery uses supported public search/video sources.

### E. YouTube Analytics — 8 methods

**Native destination:** Creator Workspace YouTube Insights.

- `groupItems.delete`
- `groupItems.insert`
- `groupItems.list`
- `groups.delete`
- `groups.insert`
- `groups.list`
- `groups.update`
- `reports.query`

These support fixed owner-authorized insights and optional owner collections.
They do not authorize arbitrary queries, monetary metrics or public-user
analytics.

### F. YouTube Reporting — 8 methods

**Native destination:** Creator Workspace Reports.

- `jobs.create`
- `jobs.delete`
- `jobs.get`
- `jobs.list`
- `jobs.reports.get`
- `jobs.reports.list`
- `media.download`
- `reportTypes.list`

These are delayed bulk-report plumbing. They require secure backend download,
storage, parsing, retention and deletion; they do not drive realtime Social
UI.

### G. Provider/eligibility/partner-gated — 8 methods

**Customer exposure:** none until the exact connected channel receives the
required provider grant or entitlement and a new approved product gate passes.

- `liveBroadcasts.insertCuepoint`
- `members.list`
- `membershipsLevels.list`
- `superChatEvents.list`
- `thirdPartyLinks.delete`
- `thirdPartyLinks.insert`
- `thirdPartyLinks.list`
- `thirdPartyLinks.update`

These controls stay absent rather than appearing as decorative, disabled or
`coming soon` actions. A normal OAuth connection does not prove entitlement.
YouTube membership or Super Chat values are provider-owned and never imply
MoolSocial commission or payout.

### H. Excluded from customer product — 3 methods

**Customer exposure:** permanently none under the current decision.

- `comments.markAsSpam` — current YouTube guidance says it is no longer
  supported in Data API v3. It must not be aliased to
  `comments.setModerationStatus`.
- `tests.insert` — provider test-only surface with no customer product use.
- `videoTrainability.get` — no approved MoolSocial customer outcome.

### Reconciliation

| Classification | Count |
|---|---:|
| Backend + typed Flutter + local tests, disabled pending proof | 87 |
| Provider/eligibility/partner-gated | 8 |
| Excluded/no customer exposure | 3 |
| Pending safe `liveChatMessages.streamList` bridge | 1 |
| **Total official Discovery methods** | **99** |

The 87 local contracts equal:

`13 public + 23 connected viewer/owner + 16 creator assets + 19 live +
8 Analytics + 8 Reporting`.

This count is code-contract coverage only. It does not mean 87 live provider
proofs, customer actions, approved screens or production features.

## Adjacent official integration surfaces outside the 99-method count

The following are part of the architecture but are not additional methods in
the pinned 99-method Discovery inventory:

### Official IFrame Player

Provides provider-controlled playback/events inside the sole isolated WebView
exception. It does not supply the native catalogue, personalized YouTube
recommendations, MoolSocial UI or provider metadata.

### YouTube WebSub / PubSubHubbub

May notify MoolSocial that an approved channel uploaded a video or changed
title/description. It is a refresh hint, not a complete data record. The
backend validates, deduplicates and then hydrates the item through normal Data
API reads. It does not expose a customer notification inbox.

### Google OAuth 2.0

Provides system-browser consent and native-app return. It is not a YouTube
content surface and may not run inside the player.

## HTML and Flutter adaptation gate

After the supervised Dev proof records real response shapes and eligibility:

1. revise only the editable Screen 04 HTML and required connected
   founder-review states;
2. expose only capabilities whose real proof passed;
3. verify every visible state, action, nested action, back/forward path,
   interruption and recovery at the required viewport/text-scale matrix;
4. present the exact HTML URL and checksum to the founder;
5. wait for explicit founder `FINAL`;
6. freeze a new immutable reference, assets, interaction contract and
   checksum;
7. implement native Flutter parity without importing HTML UI;
8. compare HTML and Flutter at identical viewport, data state and text scale;
9. run physical OPPO player, OAuth, interruption, capability and recovery
   tests; and
10. wait for founder `Accepted` before any promotion.

If a provider method is locally implemented but its live proof fails, its
customer control remains absent. UI adaptation follows observed provider truth;
the UI must not be designed first and then force unsupported behavior.

## Required proof before customer exposure

At minimum, evidence must cover:

- public catalogue from at least two permitted source types;
- pagination, long/missing fields, hidden counts and metadata expiry;
- provider source attribution on every item and action;
- official player start, pause, completion, error, captions, fullscreen,
  orientation, audio focus, app switch/resume and disposal;
- private, removed, non-embeddable, age/region restricted and Made-for-Kids
  behavior;
- explicit connected viewer mutation with acting-channel identity,
  reconciliation, revocation and no engagement reward;
- one private resumable upload with selected channel, metadata, audience,
  retry/resume/cancel and processing result;
- creator asset mutation, destructive confirmation and rollback/recovery;
- Analytics empty, limited, delayed, stale, revoked and refresh-label states;
- Reporting delayed-data, secure retrieval, retention and delete states;
- public live read behavior and bounded chat;
- each Creator Live mutation before its individual action is exposed;
- partner feature absence for a normal channel;
- quota stop, service disable and all-disabled rollback;
- no credential, token, secret, personal response or private media in
  repository evidence; and
- HTML-to-Flutter-to-OPPO visual and interaction parity after founder `FINAL`.

## Release invariants

- Screens 01–03 remain immutable.
- The approved Universal bottom rail is not changed through this provider
  architecture without a separate founder decision and reference cycle.
- No partial Social screen is merged into frozen `main`.
- Every customer-facing action has a real destination or proven state.
- No internal, example, test or planning copy appears in customer UI.
- MoolSocial does not claim the complete YouTube experience, a YouTube clone,
  personalized recommendations or unsupported provider ownership.
- Required YouTube attribution, links, controls and advertising remain
  unobscured.
- MoolSocial Feed/Create, commerce, attribution and earnings remain visibly
  MoolSocial-owned.
- No MoolSocial advertisement, product control or interaction overlay is
  placed inside or over the official player.
- Provider quota, policy, account eligibility and pricing are rechecked at
  Dev proof, founder review, Staging and Production promotion.

## Authorities

Repository authorities:

- `docs/decisions/ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md`
- `docs/decisions/ADR-0004-CREATOR-CONTENT-DISTRIBUTION-AND-ANALYTICS.md`
- `docs/decisions/ADR-0006-YOUTUBE-API-FIRST-SOCIAL-INTEGRATION.md`
- `docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`
- `docs/delivery/YOUTUBE-COMPREHENSIVE-CAPABILITY-GAP-AUDIT-20260724.md`
- `deployment/youtube-official-api-capability-registry/capability-registry.json`

Current provider authorities:

- YouTube Data API:
  <https://developers.google.com/youtube/v3/docs>
- YouTube Live Streaming API:
  <https://developers.google.com/youtube/v3/live/docs>
- YouTube Analytics API:
  <https://developers.google.com/youtube/analytics/reference/reports/query>
- YouTube Reporting API:
  <https://developers.google.com/youtube/reporting/v1/reference/rest/>
- YouTube IFrame Player API:
  <https://developers.google.com/youtube/iframe_api_reference>
- Required minimum functionality:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>
- YouTube developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- OAuth for installed apps:
  <https://developers.google.com/identity/protocols/oauth2/native-app>

When provider authority conflicts with this architecture, stop the affected
capability, preserve evidence and obtain a revised product decision. Do not
scrape, imitate, reverse-engineer or route around the provider boundary.
