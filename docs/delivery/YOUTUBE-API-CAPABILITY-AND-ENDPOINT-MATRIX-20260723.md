# YouTube API capability and endpoint matrix — 23–25 July 2026

Status: **audit-ready official capability inventory; minimum private-Dev
services enabled; credentials and live provider proof pending**

Checked authorities:

- YouTube Data API discovery revision: `20260723`
- YouTube Analytics discovery revision: `20260721`
- YouTube Reporting discovery revision: `20260721`
- YouTube quota calculator last updated: 1 June 2026
- YouTube Data API revision history checked through: 23 July 2026
- YouTube Live Streaming API revision history checked through: 20 July 2026
- YouTube Analytics/Reporting revision history checked through: 25 June 2026

This matrix is the authoritative capability contract for YouTube work in the
native MoolSocial app. It records what the official services expose, which
authorization/eligibility gate applies, and whether MoolSocial may expose the
capability. It does not approve a YouTube-clone UI, freeze Screen 04, widen the
current private-Dev deployment manifest or authorize production traffic.

“Comprehensive integration” means every officially available family is
inventoried and given an explicit disposition. It does not mean requesting
every scope, enabling every service or displaying every action. Unsupported,
deprecated, partner-only, representative-gated and ineligible capabilities
must remain absent.

## Native-app and policy boundary

- MoolSocial is a native Flutter application, not a web product.
- All discovery, metadata, comments, creator, analytics, commerce and recovery
  UI is native Flutter V2.
- The sole WebView exception is the direct official YouTube IFrame Player in
  an isolated Android `WebView` or Apple `WKWebView`. Its bootstrap contains
  no MoolSocial UI, authentication, form, navigation, commerce or business
  logic.
- Google OAuth uses the system browser, never the player WebView.
- MoolSocial must not clone or mimic YouTube, hide required YouTube
  attribution, replace or cover controls/ads/links, or imply that a
  MoolSocial-selected catalogue is YouTube Home or YouTube recommendations.
- MoolSocial-native Save, Discuss, commerce and creator-commission functions
  stay visibly separate from provider-owned Like, Comment, Subscribe,
  playlists, playback and analytics.
- YouTube engagement cannot be paywalled, rewarded or used as a MoolSocial
  payout event. Independent MoolSocial commerce may sit outside the player
  only when it has genuine standalone value and a real campaign association.

## Revision-sensitive July 2026 facts

- 1 June 2026: `search.list` and `videos.insert` moved into separate granular
  daily quota buckets.
- 3 June 2026: `videos.batchGetStats` became available with its own documented
  10,000-calls/day default bucket.
- 7 July 2026: `videos` added the eligibility-gated `brandPartner` part for
  creator-initiated brand access.
- 23 June 2026: live-chat message deleted/retracted event types were removed
  because they are not returned.
- 20 July 2026: eligible live broadcast owners can clear/past-date
  `pauseAdsUntil` to resume provider midroll ads.
- 25 June 2026 Analytics/Reporting documentation remains current for the
  revised targeted-query/report surface, including channel reach reports.

These dates are documentation/revision checkpoints, not proof that the exact
Dev account/channel is eligible.

## Decisive answer

MoolSocial can build a high-quality native library of YouTube-sourced videos,
play each selected item inside MoolSocial through the official YouTube player,
let a connected creator upload directly to the creator's YouTube channel and
show creator-owned analytics.

YouTube does **not** expose its complete application UI, personalized Home
recommendations, native Shorts recommendation feed, watch history or Watch
Later. MoolSocial must supply its own discovery, ranking, navigation and
commerce UI around clearly attributed YouTube content.

## UI exposure at a glance

| MoolSocial surface | Real provider data available | Provider-owned UI |
|---|---|---|
| Video discovery card | video ID, title, description, thumbnails, channel identity, publish time, duration, category/tags/localization where returned, public counts, live status, captions/embeddability/restriction fields where returned | none; card is native Flutter with YouTube attribution |
| Selected video | the same metadata plus selected public comments/channel data | official embedded player only |
| Channel sheet | channel title, description, handle/custom URL, thumbnails, country, public statistics, uploads playlist and public playlists | none |
| Public comments | top-level threads, replies and author/channel fields returned by API | none |
| Search | public video/channel/playlist results using supported filters and page tokens | none |
| Connected creator | selected channel, uploads, owned playlists, permitted private/owner fields | Google system-browser OAuth |
| Creator upload | title, description, privacy and other supported fields selected by user; resulting video ID/status | no YouTube upload UI; MoolSocial native UI invokes API |
| Creator analytics | authorized YouTube metrics/dimensions | none |
| Playback controls | only the controls and capabilities exposed by IFrame Player | YouTube-owned player |

MoolSocial must not fabricate a field when YouTube omits it. It must preserve
source identity and label MoolSocial-owned data separately.

## MVP endpoint set

### Public discovery and metadata

| Method | Credential | Current default quota | MoolSocial use |
|---|---|---:|---|
| `videos.list` | restricted API key; OAuth for owner/private fields | 1 general unit | hydrate metadata, status, public statistics and embeddability |
| `videos.batchGetStats` | public; OAuth for private videos | 1 call in its documented granular bucket | efficient video counts, duration and publish time |
| `channels.list` | restricted API key; OAuth for `mine=true` | 1 general unit | channel identity, statistics and uploads-playlist ID |
| `playlists.list` | public or OAuth | 1 general unit | public and creator-owned playlist metadata |
| `playlistItems.list` | public or OAuth | 1 general unit | paginated curated and channel-upload inventory |
| `videoCategories.list` | restricted API key | 1 general unit | supported regional categories |
| `i18nRegions.list` | restricted API key | 1 general unit | supported content regions |
| `i18nLanguages.list` | restricted API key | 1 general unit | supported application languages |
| `commentThreads.list` | public where comments are available | 1 general unit | top-level public comment threads |
| `comments.list` | public where comments are available | 1 general unit | replies and full comment text |
| `activities.list` | public channel activity or authorized user's own activity | 1 general unit | approved-channel activity only |
| `subscriptions.list` | public where exposed; OAuth for `mine` | 1 general unit | optional connected subscription sources |
| `channelSections.list` | public or OAuth for owner context | 1 general unit | optional channel-layout metadata; not a consumer feed |
| `videoAbuseReportReasons.list` | restricted API key or OAuth | 1 general unit | localized reason dictionary for a later explicit report flow |
| `search.list` | restricted API key; OAuth for selected filters | 1 call from separate 100/day search bucket | deliberate submitted search only |

`activities.list(home=true)` is deprecated and the API states that the user's
Home feed is not available. It is not a route to personalized YouTube Home.

### Official playback

The IFrame Player API can:

- cue/load by video ID or URL;
- cue/load a provider playlist, an explicit video-ID array or a channel's
  uploads list;
- play, pause, stop, seek, next, previous and select a playlist index;
- expose playlist contents/index and support provider loop/shuffle behavior;
- mute/unmute, read/set volume and read/set a provider-supported playback
  rate;
- expose player state, duration, current time, loaded fraction, video URL,
  embed code and iframe node;
- expose and reload the provider captions module through `onApiChange`;
- expose supported 360-degree spherical properties where available;
- resize/destroy the player; and
- emit `onReady`, `onStateChange`, `onPlaybackQualityChange`,
  `onPlaybackRateChange`, `onError`, `onApiChange` and
  `onAutoplayBlocked`.

MoolSocial may wrap only the subset required by the reviewed native journey.
The bridge is typed and closed; it never exposes arbitrary JavaScript. A
documented player method is not permission to recreate a YouTube screen or
build a second control layer over the player.

The player does not expose YouTube Home, Shorts browsing, comments, channel
screens or MoolSocial commerce. Those remain separate native Flutter surfaces.

Mandatory host rules:

- direct official YouTube embed;
- OS Android WebView or iOS WKWebView;
- valid Referer/origin/app identity and Android WebView media integrity;
- at least 200x200 viewport, with 480x270 recommended for a controlled 16:9
  player;
- no overlay, covered control, replaced ad, intercepted touch, separated
  audio, background playback or offline copy; and
- at most one autoplaying player, visible and more than half on-screen before
  compliant autoplay.

Player error `153` means the request lacks the required Referer or equivalent
client identity and is a release-blocking integration defect. Errors `2`, `5`,
`100`, `101` and `150`, autoplay-blocked, captions, fullscreen, app lifecycle,
audio focus, interruption and one-player disposal are mandatory proof states.

Deprecated or ineffective player options are not product features:

- player list search (`listType=search`) is deprecated; use Data API
  `search.list`, then load the selected IDs;
- programmatic playback-quality setters/getters are no longer supported;
- `showinfo`, `autohide` and `theme` are obsolete;
- `modestbranding` no longer changes player branding; and
- the old native Android YouTube Player API is not the approved runtime.

### Creator upload and owner operations

| Method | Minimum useful access | Current quota | MVP decision |
|---|---|---:|---|
| `channels.list(mine=true)` | user OAuth | 1 general unit | required account/channel confirmation |
| `videos.insert` | `youtube.upload` | 1 call from separate 100/day upload bucket | required private Dev spike |
| resumable upload protocol | same OAuth operation | part of upload operation | required direct device-to-YouTube transfer |
| `videos.list` | creator OAuth | 1 general unit | required processing/status reconciliation |
| `videos.update` | broader YouTube write scope | 50 general units | recommended after upload proof |
| `thumbnails.set` | YouTube upload/write scope | 50 general units | recommended after upload proof |
| `videos.insert/update/list` `brandPartner` part | creator OAuth and provider eligibility | method quota applies | candidate for eligible creator/brand deals |
| `captions.list` | YouTube write/partner scope | 50 general units | later |
| `captions.insert` | YouTube write/partner scope | 400 general units | later |
| `captions.update` | YouTube write/partner scope | 450 general units | later |
| `captions.download` | YouTube write/partner scope | 200 general units | later |
| `captions.delete` | YouTube write/partner scope | 50 general units | later |
| `videos.delete` | broader YouTube write scope | 50 general units | later, explicit destructive confirmation |

Every upload UI must let the user control:

- exact YouTube channel/destination;
- title, up to the provider-supported limit;
- description, up to the provider-supported limit;
- privacy: public, private or unlisted; and
- required audience declarations.

Where applicable the contract also supports:

- `status.publishAt` for a private, never-published scheduled item;
- `notifySubscribers`;
- `status.selfDeclaredMadeForKids`;
- `status.containsSyntheticMedia`; and
- `paidProductPlacementDetails.hasPaidProductPlacement`.

These fields are not silently defaulted. MoolSocial shows only fields supported
by the current account/content state and records the creator's explicit
selection.

### Complete creator and channel-management families

The following families are officially exposed but remain independently gated.
They belong in Account/Creator Workspace, not the public consumer feed.

| Family | Official methods | MoolSocial disposition |
|---|---|---|
| Owned videos | `list`, `insert`, `update`, `delete`, `getRating`, `rate`, `reportAbuse`, `batchGetStats` | Private upload/status proof first; destructive and viewer writes later with exact confirmation |
| Thumbnails | `set` | Post-upload creator tool after media-size, quota and reconciliation proof |
| Captions | `list`, `download`, `insert`, `update`, `delete` | High-quota creator tool; no arbitrary-public transcript promise |
| Playlists | `list`, `insert`, `update`, `delete` | Owner library after separate write consent |
| Playlist items | `list`, `insert`, `update`, `delete` | Owner ordering/management after playlist proof |
| Playlist images | `list`, `insert`, `update`, `delete` | Later creator polish; image upload and media validation required |
| Channels | `list`, `update` | Identity/read MVP; update later and only for returned writable fields |
| Channel sections | `list`, `insert`, `update`, `delete` | Later creator layout tool; not a substitute for a feed |
| Channel banners | `insert` | Later creator branding upload |
| Watermarks | `set`, `unset` | Later creator branding action |
| Comments/threads | `list`, `insert`, `update`, `delete`, `setModerationStatus` | Read-only public first; creator/viewer writes and moderation later |
| Subscriptions | `list`, `insert`, `delete` | Optional viewer/owner action; does not unlock a personalized subscription feed |
| Abuse reports | `videoAbuseReportReasons.list`, `videos.reportAbuse` | Later explicit provider-report flow with reason validation |

There is no dedicated Shorts upload method: vertical media uses
`videos.insert`, and YouTube determines whether it is eligible for a Shorts
surface.

The project is unaudited, so API uploads remain private until YouTube approves
the compliance audit. Public visibility must stay feature-disabled even if a
user selects it in a future reviewed UI.

### Creator-initiated brand-partner access

The Data API added the `brandPartner` video part on 7 July 2026. During upload
or later update, an eligible creator can identify a brand YouTube channel by
`channelId` or `channelHandle`; YouTube returns the resolved channel ID.

This is valuable for MoolSocial campaign distribution because it can establish
provider-recognized brand access for eligible deals. It does not:

- create a rights agreement;
- make every creator or brand deal eligible;
- replace the paid-promotion declaration;
- prove a MoolSocial sale; or
- determine creator commission.

MoolSocial must keep its campaign, consent, attribution, order, return hold and
payout ledger independent.

### Optional connected actions

| Capability | Read method/cost | Write method/cost | MVP decision |
|---|---|---|---|
| Video rating | `videos.getRating`, 1 | `videos.rate`, 50 | later |
| Comments | `commentThreads.list`/`comments.list`, 1 | insert/update/delete/moderate, generally 50 | public display candidate; writing later |
| Subscriptions | `subscriptions.list`, 1 | insert/delete, 50 | connected read candidate; writing later |
| Playlists | `playlists.list`/`playlistItems.list`, 1 | insert/update/delete, 50 | curated reads MVP; management later |
| Abuse reporting | reasons list, 1 | report operation, 50 where documented | later |

Every write must be:

- clearly identified as a YouTube action;
- visibly associated with the exact acting YouTube channel and target;
- distinct from MoolSocial-native likes/comments/saves; and
- initiated and confirmed by the user.

MoolSocial cannot pay or incentivize YouTube viewing, likes, comments,
subscriptions or other engagement.

The legacy YouTube Subscribe Button is not a state-authority shortcut. Its
subscription-event tracking is deprecated and provider confirmation may leave
the app. A MoolSocial-native Subscribe action, if approved, uses the authorized
Data API mutation and then reconciles the returned connected-channel state.

## YouTube Analytics API v2

### Analytics endpoint inventory

| Resource | Methods | Decision |
|---|---|---|
| `reports` | `query` | MVP creator-performance proof |
| `groups` | `list`, `insert`, `update`, `delete` | later grouped creator reporting |
| `groupItems` | `list`, `insert`, `delete` | later grouped creator reporting |

Recommended MVP authorization:

- `youtube.readonly`; and
- `yt-analytics.readonly`.

`yt-analytics-monetary.readonly` is a separate, optional consent and is excluded
until a creator-earnings product and legal owner are approved.

Authorized reports can expose supported creator-owned dimensions and metrics
such as views, watch time, engagement, traffic sources, geography, device,
playback location, operating system, content type (including supported Shorts
dimensions), live/playlist/video identifiers, audience retention, subscriber
change, card/end-screen performance and supported thumbnail-impression/reach
fields. Exact metric/dimension combinations are provider-defined and must be
validated rather than assembled arbitrarily.

`groups` and `groupItems` let an authorized owner maintain bounded collections
of channels, videos, playlists or assets for targeted queries. They are
creator-workspace organization, not public Social groups. Group use requires
its own CRUD confirmation, ownership and deletion states.

MoolSocial must:

- show these only to the creator or approved agent;
- preserve YouTube source labels;
- not combine provider data into an undisclosed cross-platform metric;
- not infer CPM, paid reach, audience composition, brand safety or financial
  performance that the API does not return; and
- verify continuing authorization and deletion status at least every 30 days.

The June 2026 current revision also means unsupported historical report
combinations, such as the removed content-owner city report, must not be
offered merely because an older example exists.

Cloud Console must be checked for the actual Analytics quota before traffic;
the service does not publish one simple Data-API-style unit table for every
query.

## YouTube Reporting API v1

### Reporting endpoint inventory

| Resource | Methods |
|---|---|
| `reportTypes` | `list` |
| `jobs` | `create`, `get`, `list`, `delete` |
| `jobs.reports` | `list`, `get` |
| `media` | authorized report download |

Reporting produces bulk CSV reports and is suitable for later back-office
reconciliation, not immediate UI. Ordinary connected creators may use
eligible **channel** reports. Content-owner reports, asset/claim/finance
reports and system-managed monetary reports require the corresponding content
owner or partner rights and are not ordinary creator capabilities.

Operationally:

- a new job starts producing reports only after creation; the first report is
  normally retrievable within 48 hours;
- each report covers one 24-hour period and new reports arrive daily;
- a new job can receive roughly 30 days of historical backfill;
- historical reports remain available for 30 days and ordinary generated
  reports for 60 days;
- a newer backfill report for the same time window replaces the earlier
  dataset; and
- download URLs and CSV files are authorized data with explicit storage,
  deletion, privacy-threshold and reprocessing owners.

Reporting is deferred until:

- targeted Analytics queries are insufficient;
- the connected creator is eligible for the required report type;
- delayed report availability is acceptable; and
- storage, refresh and deletion have an approved owner.

## YouTube Live Streaming API

Live uses YouTube Data API OAuth and quota governance, but has a distinct
eligibility, lifecycle, moderation and operational-risk gate.

| Family | Official methods/capabilities | MoolSocial disposition |
|---|---|---|
| Public live discovery | `search.list(eventType=live/upcoming/completed)`, `videos.list(liveStreamingDetails)` | Read-only catalogue candidate; official player remains playback authority |
| Live broadcasts | `list`, `insert`, `update`, `delete`, `bind`, `transition`, `insertCuepoint` | Owner workspace after channel eligibility, lifecycle and compliance proof |
| Live streams | `list`, `insert`, `update`, `delete` | Owner ingest management after credential/secrecy and operational proof |
| Live chat read | `liveChatMessages.list`, `streamList` | Read-only candidate where provider exposes an active chat |
| Live chat write/poll | `insert`, `transition`, `delete` | Later, with incremental OAuth and exact acting-channel confirmation |
| Live moderation | bans `insert/delete`; moderators `list/insert/delete` | Later creator/moderator workspace with audit and abuse recovery |
| Paid/member events | live-chat Super Chat/Super Sticker, member milestone, gifting, gift receipt and provider gift events; `superChatEvents.list` | Eligibility/owner-gated display only; never MoolSocial payment or payout truth |
| Geo availability | `liveBroadcast.contentDetails.availabilityConfig` | Eligible owner configuration after rights/legal review |
| Midrolls and cuepoints | broadcast monetization/cuepoint schedule including automated midrolls and pause/unpause | Eligible owner-only YouTube ad control; never MoolSocial ad inventory |

Provider eligibility and returned fields are authoritative. MoolSocial cannot
promise that every connected channel can create live streams, use monetization,
send chat, run polls or access member/funding events.

Current live deprecations are binding:

- `liveCuepoints.insert` is replaced by
  `liveBroadcasts.insertCuepoint`;
- `liveBroadcasts.control` is removed;
- old `sponsors` resources are replaced by `members`;
- removed `messageDeletedEvent`/`messageRetractedEvent` types must not be
  modeled as live events; and
- deprecated stream-format fields must not be used.

## WebSub approved-channel refresh

YouTube PubSubHubbub/WebSub may notify MoolSocial when an approved channel
uploads a video or changes a video's title or description. It is a refresh
hint, not a general event stream.

- It does not provide statistics, comments, likes, subscriptions, privacy,
  deletion, watch-history or viewer-notification events.
- WebSub delivery itself consumes no Data API unit; subsequent hydration and
  reconciliation do.
- The callback, leases, verification challenge, signed Atom parsing,
  deduplication, approved-channel registry, refresh quota and bounded
  revalidation require the separate WebSub contract.
- WebSub remains disabled until ADR-0008 and the private-Dev manifest
  explicitly authorize its targets and IAM. This matrix does not activate it.

## Complete Data API resource inventory and disposition

The following resource/method inventory was read from the official discovery
document. “Later” means technically exposed but outside the MVP proof.
“Excluded” means unavailable to ordinary MoolSocial MVP users, high-risk, or
not supported by a sufficiently clear public product contract.

| Resource | Methods in current discovery document | MoolSocial disposition |
|---|---|---|
| Activities | `list` | MVP only for channel activity; never Home |
| Captions | `list`, `download`, `insert`, `update`, `delete` | later |
| Channel banners | `insert` | later creator channel management |
| Channels | `list`, `update` | list MVP; update later |
| Channel sections | `list`, `insert`, `update`, `delete` | later |
| Comments | `list`, `insert`, `update`, `delete`, `setModerationStatus` | public list candidate; writes/moderation later; deprecated spam-marking is not used |
| Comment threads | `list`, `insert` | public list candidate; insert later |
| Languages/regions | `i18nLanguages.list`, `i18nRegions.list` | MVP |
| Live broadcasts | `list`, `insert`, `update`, `delete`, `bind`, `transition`, `insertCuepoint` | later live product |
| Live streams | `list`, `insert`, `update`, `delete` | later live product |
| Live chat messages | `list`, `streamList`, `insert`, `delete`, `transition` | later live product |
| Live chat bans | `insert`, `delete` | later live moderation |
| Live chat moderators | `list`, `insert`, `delete` | later live moderation |
| Members | `list` | representative-access plus eligible channel-memberships owner; 2-unit read; not ordinary OAuth |
| Membership levels | `list` | same representative/eligible-channel boundary as Members |
| Playlist images | `list`, `insert`, `update`, `delete` | later |
| Playlist items | `list`, `insert`, `update`, `delete` | list MVP; writes later |
| Playlists | `list`, `insert`, `update`, `delete` | list MVP; writes later |
| Search | `list` | MVP with strict user-submit budget |
| Subscriptions | `list`, `insert`, `delete` | read candidate; writes later |
| Super Chat events | `list` | later; eligible live/monetized creators |
| Thumbnails | `set` | post-upload recommended |
| Video abuse reasons | `list` | later reporting flow |
| Video categories | `list` | MVP |
| Videos | `list`, `batchGetStats`, `insert`, `update`, `delete`, `getRating`, `rate`, `reportAbuse` | list/stats/private insert MVP; rest later |
| Watermarks | `set`, `unset` | later |
| Abuse-report discovery resource | `abuseReports.insert` | discovery-only/undocumented product surface; do not call |
| Third-party links | `list`, `insert`, `update`, `delete` | restricted/non-ordinary product surface; do not expose without a new official contract |
| Video trainability | `get` | generally callable without auth/quota, but irrelevant to MoolSocial consumer/creator UI; no feature |
| Test discovery resource | `tests.insert` | excluded; never call undocumented/test resources |

## Partner, representative and eligibility gates

| Family | Gate | Product decision |
|---|---|---|
| YouTube Content ID API | Approved Content ID partner/content-owner rights | Excluded; claims, assets, policies, ownership and Content ID reports are not ordinary creator APIs |
| `onBehalfOfContentOwner` / CMS operations | Authorized YouTube content owner and linked channel | Excluded from ordinary MoolSocial accounts |
| Content-owner/system-managed monetary Reporting | Content-owner/partner rights plus monetary scope | Excluded until a separately authorized partner product exists |
| Members and membership levels | Eligible memberships-enabled owner **and** access requested through a Google/YouTube representative | Not part of general OAuth; disabled |
| Super Chat events | Eligible authorized owner/live channel | Later owner analytics; no representative gate is asserted merely because Members has one |
| Creator-initiated `brandPartner` | Eligible creator/deal and current provider acceptance | Later campaign tool; never rights, attribution or payout proof |
| Live monetization, gifting, midrolls and member events | Eligible channel/content/event | Later; returned capability is authoritative |

A visible action requires a successful capability probe for the exact
connected channel. MoolSocial must not infer eligibility from sign-in, channel
existence or a service being enabled.

## Explicitly unsupported product requests

No documented generally available API supplies:

- personalized YouTube Home or the provider recommendation graph;
- the native YouTube Shorts feed, a reliable general `isShort` flag, or a
  dedicated Shorts-upload endpoint;
- Watch History or Watch Later (`playlistItems.list` cannot retrieve them);
- the YouTube notification inbox or the provider's “You” account surface;
- Community-post creation, Stories or the native YouTube creation UI;
- public transcripts for arbitrary videos;
- raw audiovisual media URLs, downloads, offline copies or background/audio
  extraction;
- a reusable provider-authenticated browser/app session inside MoolSocial; or
- a permission to place MoolSocial UI, commerce or ads inside the official
  player.

These are not backlog items. They remain absent until an official generally
available contract changes and is re-audited.

## Removed and deprecated register

Do not implement:

- `activities.list(home=true)` as a Home feed;
- old native Android Player API;
- IFrame `listType=search`;
- IFrame programmatic quality setters/getters;
- obsolete `showinfo`, `autohide`, `theme` or branding-hiding expectations
  from `modestbranding`;
- `comments.markAsSpam`;
- `search.list(relatedToVideoId)`;
- deprecated guide-category resources;
- `liveCuepoints.insert`, `liveBroadcasts.control`, old `sponsors` resources
  or removed live-chat deletion/retraction event types; or
- deprecated Subscribe Button event tracking.

## Discovery sources ranked by quota efficiency

1. Regional/category `videos.list(chart=mostPopular)` — 1 unit.
2. Approved-channel `channels.list` + upload `playlistItems.list` — 1 unit
   each page.
3. Curated public `playlists.list` + `playlistItems.list` — 1 unit each page.
4. PubSubHubbub upload/update notifications — event-driven refresh.
5. `videos.batchGetStats` — efficient current statistics.
6. Explicit `search.list` — separate 100 calls/day default, so never an
   infinite background feed.

The public starting library should combine sources 1–4, then hydrate via
`videos.list`/`batchGetStats`. Search is a deliberate user action.

## Metadata and retention rules

MoolSocial may temporarily cache limited non-authorized YouTube API data, but
must refresh or delete it within 30 calendar days. Authorized statistics or
Analytics/Reporting data may be retained as necessary for the consented
purpose, but authorization and provider-deletion status must still be verified
at least every 30 days.

MoolSocial must:

- use current provider values for displayed counts;
- remove deleted/private/unavailable items promptly;
- never cache YouTube audiovisual bytes;
- never create derived substitute metrics without the additional YouTube audit
  permission introduced for such analytics use cases;
- label MoolSocial metrics as not from YouTube when shown beside provider
  metrics; and
- keep authorized data visible only to the authorizing user or approved agent.

## Quota and cost model

Current documented default allocation:

| Bucket | Default |
|---|---:|
| `search.list` | 100 calls/project/day |
| `videos.insert` | 100 calls/project/day |
| other Data API methods | 10,000 units/project/day |
| `videos.batchGetStats` | current documentation identifies its own granular 10,000/day bucket |

Current documented method costs outside those granular buckets include:

| Operation class | Typical documented cost |
|---|---:|
| common `list`/read operations | 1 general unit |
| `members.list` | 2 general units |
| most create/update/delete/rate/moderation/report writes | 50 general units |
| `captions.download` | 200 general units |
| `captions.insert` | 400 general units |
| `captions.update` | 450 general units |

The exact current Cloud Console quota for Data, Live, Analytics and Reporting
is the release authority. Do not invent a Live/Analytics/Reporting allowance
when its console quota or official method table has not been captured.

Daily reset is midnight Pacific Time. Every call, including an invalid one,
uses quota; every additional result page is another call.

The official documentation describes quota, not ordinary per-request billing.
Within approved quota, the design has no published YouTube API per-call price,
and YouTube hosts/streams its audiovisual content. MoolSocial still pays for
its own:

- backend broker and webhook execution;
- secret/token storage and security;
- metadata refresh and analytics jobs;
- attribution, moderation, monitoring and support;
- MoolSocial-owned Reels and Feed media; and
- any upload path that proxies bytes instead of uploading directly to YouTube.

Therefore “zero YouTube video hosting/streaming cost to MoolSocial” is a valid
architecture target. “The entire integration costs nothing” is not a valid
guarantee.

Quota exhaustion returns provider errors and stops the affected action; it
does not buy additional calls automatically. Higher quota requires the
official compliance/quota request and must not be evaded with duplicate
projects. MoolSocial still incurs its own Functions/Cloud Run, Firestore,
Secret Manager, logging, cache, moderation, support and network costs. The
founder-approved INR 1,000 Dev budget is an alert, not a hard cap.

Use the detailed `C0`–`C3` and provider-gate classification in
`YOUTUBE-MOOLSOCIAL-PRODUCT-AND-COST-MAP-20260723.md`. Public playback remains
free to viewers. Chargeable plans may cover only independently valuable
MoolSocial workflows, commerce, attribution, payouts, team operations,
analytics and explicitly selected managed media—not YouTube access.

## Adjacent Google/YouTube products

| Product | Real opportunity | Cost/gate decision |
|---|---|---|
| Live Streaming API | create/manage eligible live broadcasts and streams; low-latency chat via `streamList`; polls, moderation and eligible funding/member events | later; operating/moderation cost and creator eligibility |
| YouTube memberships and Super Chat resources | eligible connected creators can read supported owner/member/funding events | later; Members requires eligible-channel owner plus Google/YouTube representative access, while Super Chat has its own owner/eligibility gate |
| Merchant API YouTube Shopping affiliate reports | eligible merchants/program participants can retrieve creator/content/product affiliate analytics | later feasibility; not a general API for attaching MoolSocial products to arbitrary videos |
| Google Ads API Demand Gen | brand-funded campaigns can target YouTube in-stream, in-feed or Shorts and other Google surfaces | later paid product; advertiser media spend, developer-token/account, compliance and MoolSocial service cost |
| Content ID/Partner APIs | rights-management capabilities for approved partners | excluded from MVP; partner-only |

None of these products is enabled merely because the service-enablement action
has no displayed fee. Google Ads necessarily introduces advertiser media
spend. Merchant/Shopping, memberships and partner APIs have eligibility gates.

Merchant API and Demand Gen are future Creator/Business Workspace
integrations under
`ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md`.

- Indian creator eligibility for YouTube Shopping Affiliate must not be
  confused with merchant programme eligibility.
- Affiliate reports are read-only provider analytics. They do not enrol a
  merchant, tag arbitrary videos, import ordinary orders or replace the
  MoolSocial ledger.
- Demand Gen delivers on eligible Google surfaces. It does not place Google
  ads inside MoolSocial.
- The current Social and YouTube Dev proof proceeds without either API.

## Advertising and commerce boundary

MoolSocial commerce can appear near YouTube API data only if the non-YouTube
MoolSocial product/service content supplies enough independent value to justify
the commercial placement even after removing all YouTube data.

Never:

- place an ad, product card or interaction overlay on the player;
- cover, restyle, replace or block YouTube controls, links, branding or ads;
- attach a product to arbitrary public content without a real rights/campaign
  relationship;
- incentivize YouTube playback or engagement; or
- base creator commission on YouTube engagement.

The safe MVP is an independent MoolSocial campaign/product module outside the
player, linked only to creator-authorized campaign content, with delivered-order
attribution under ADR-0003.

## Unavailable-product register

The following requests must not be promised in production copy:

- “Your YouTube Home inside MoolSocial”
- “All YouTube Shorts”
- “The same recommendations as YouTube”
- “Your YouTube watch history”
- “Your Watch Later”
- “A full YouTube app without leaving MoolSocial”
- “No YouTube link will ever leave MoolSocial”
- “Ad-free YouTube”
- “Earn for watching/liking/commenting/subscribing on YouTube”
- “All creator uploads become public immediately”
- “Completely free integration at any scale”
- “An exact YouTube clone inside MoolSocial”
- “Pay to unlock YouTube watching”

## Official source register

- Data API:
  <https://developers.google.com/youtube/v3/docs>
- `videos.list`:
  <https://developers.google.com/youtube/v3/docs/videos/list>
- `videos.batchGetStats`:
  <https://developers.google.com/youtube/v3/docs/videos/batchGetStats>
- `search.list`:
  <https://developers.google.com/youtube/v3/docs/search/list>
- `videos.insert`:
  <https://developers.google.com/youtube/v3/docs/videos/insert>
- Brand-partner access:
  <https://developers.google.com/youtube/v3/guides/implementation/videos>
- Resumable uploads:
  <https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol>
- Quota:
  <https://developers.google.com/youtube/v3/determine_quota_cost>
- Quota/compliance audits:
  <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
- Push notifications:
  <https://developers.google.com/youtube/v3/guides/push_notifications>
- Player:
  <https://developers.google.com/youtube/iframe_api_reference>
- Required functionality:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>
- Developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- Compliance guide:
  <https://developers.google.com/youtube/terms/developer-policies-guide>
- Installed-app OAuth:
  <https://developers.google.com/identity/protocols/oauth2/native-app>
- Analytics:
  <https://developers.google.com/youtube/analytics/reference/reports/query>
- Reporting:
  <https://developers.google.com/youtube/reporting/v1/reference/rest/>
- Live chat:
  <https://developers.google.com/youtube/v3/live/docs/liveChatMessages>
- Live Streaming API and revision history:
  <https://developers.google.com/youtube/v3/live/docs>,
  <https://developers.google.com/youtube/v3/live/revision_history>
- Members access gate:
  <https://developers.google.com/youtube/v3/docs/members>
- Playlist images:
  <https://developers.google.com/youtube/v3/docs/playlistImages>
- Analytics metrics/dimensions and reporting revision history:
  <https://developers.google.com/youtube/analytics/metrics>,
  <https://developers.google.com/youtube/analytics/dimensions>,
  <https://developers.google.com/youtube/reporting/revision_history>
- Bulk Reporting lifecycle and available reports:
  <https://developers.google.com/youtube/reporting/v1/reports>,
  <https://developers.google.com/youtube/reporting/v1/reports/full_report_list>
- Content ID partner API:
  <https://developers.google.com/youtube/partner>
- Merchant API YouTube Shopping affiliate updates:
  <https://developers.google.com/merchant/api/latest-updates>
- Google Ads Demand Gen:
  <https://developers.google.com/google-ads/api/docs/demand-gen/overview>
- Demand Gen channel controls:
  <https://developers.google.com/google-ads/api/docs/demand-gen/channel-controls>
- YouTube terms revision history:
  <https://developers.google.com/youtube/terms/revision-history>
- Discovery documents:
  <https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest>,
  <https://youtubeanalytics.googleapis.com/$discovery/rest?version=v2> and
  <https://youtubereporting.googleapis.com/$discovery/rest?version=v1>

## UI admission and release rule

An endpoint appears in a customer-facing MoolSocial UI only after all of these
are true:

1. its official family, method, scope, quota bucket, retention rule and policy
   gate are recorded in this matrix;
2. its server/mobile adapter is disabled by default and has deterministic
   contract tests;
3. the exact capability succeeds against the founder-controlled private Dev
   account/channel and its missing-field, ineligible, revoked, quota and
   provider-error states are captured without credentials or personal data;
4. the editable Screen 04 (or Creator Workspace) HTML is revised from those
   observed shapes, not fabricated fixtures;
5. the founder marks one exact HTML checksum `FINAL`;
6. that reference is frozen as a new immutable version;
7. native Flutter parity is verified at identical state, viewport and text
   scale; and
8. physical OPPO acceptance passes before any Staging candidate.

An official documentation page alone does not satisfy step 3. No existing
Screen 04 draft, frozen historical reference or Flutter behavior proves the
provider contract.

## 24 July local implementation checkpoint

The local private-Dev server contract now implements and verifies the MVP
public-catalogue reads and owner P1 reads described above.

Public catalogue:

- most-popular discovery;
- explicit submitted search and metadata hydration;
- video details and batched statistics;
- channel details and `forHandle` lookup;
- public comments and replies;
- playlist details and channel playlists; and
- provider regions, languages and categories.

Owner P1:

- connected-channel upload inventory;
- subscriptions with provider-supported ordering;
- owner playlists;
- fixed Analytics presets with bounded continuation;
- 30-day channel-identity revalidation; and
- connection-status verification windows.

The independent local result is `116/116` backend tests plus a passing full
private-Dev package gate, including the Screen 01–03 locks and disabled
provider flags. Sanitized evidence and exact source hashes are at
`artifacts/quality/youtube-provider-schema-validation-20260724-08/PUBLIC-OWNER-P1-VERIFICATION-EVIDENCE.md`.

This checkpoint is not cloud deployment or live-provider proof. The official
player, WebSub, App Check endpoint enforcement, real OAuth, live Analytics,
quota/cost smoke and Screen 04 revision remain gated.
