# Screen 04 YouTube-centred interaction contract — 24 July 2026

## Status and authority

This document records the founder-authorized direction for the next editable
Screen 04 Social HTML candidate.

- Screen 04 v9 remains `DRAFT / HOLD`.
- This contract does not mark Screen 04 `FINAL`.
- It does not freeze a reference or authorize Flutter presentation changes.
- Screens 01–03 and every immutable Screen 04 reference remain read-only.
- Provider behavior must be proved before the HTML is revised.
- The required order remains provider proof, HTML revision, browser/state
  verification, founder `FINAL`, immutable freeze, native Flutter parity and
  physical OPPO acceptance.

YouTube may become the primary engagement centre in Social. That authorization
does not permit an indistinguishable YouTube clone. MoolSocial must provide an
independent, branded and policy-compliant discovery, commerce and collaboration
experience around real YouTube data and the unmodified official player.

The founder's 24 July 2026 “no boundary” direction applies to the next editable
Screen 04 candidate. Provider proof may justify changing any prior editable
Screen 04 layout, hierarchy, entry state, sub-action placement or navigation
presentation—including the earlier rail treatment—when that creates a materially
better YouTube-centred experience. This is not permission to overwrite an
immutable reference, bypass founder `FINAL`, imitate protected YouTube trade
dress, fabricate provider capabilities or weaken accessibility and customer-copy
gates.

## Identity and ownership boundaries

The product must keep these identities distinct:

1. the signed-in MoolSocial account;
2. an optional YouTube viewer connection for YouTube-owned actions;
3. an optional YouTube creator connection for upload and owner analytics.

MoolSocial authentication alone never authorizes YouTube Like, Comment,
Subscribe, upload or owner Analytics. OAuth uses the system browser, never the
embedded player WebView.

MoolSocial remains the owner of:

- Feed, posts, replies and carousels;
- Image Poll, Quick Poll and Quiz;
- MoolSocial reactions, saves and discussions;
- campaign associations, commerce cards, orders, attribution and payouts;
- MoolSocial Reels after their storage and cost contract is separately
  approved; and
- Universal, Mool, Chat, account, notifications and every non-Social world.

## Social entry and universal rail

- First Social entry opens `Videos`.
- Later Social entries restore the last selected Social sub-action and its
  provider-safe state.
- Treat the existing universal bottom rail as the current navigation baseline,
  not an immutable constraint on the next candidate. If provider-observed
  behavior requires a better YouTube-centred hierarchy, redesign it in the
  editable HTML and submit that complete navigation change for founder `FINAL`.
- Keep Mool, Chat, YouTube-centred Videos, Shorts and MoolSocial Feed/Create
  journeys continuously discoverable even if their placement changes.
- `Create` is the personal content-library and publisher hub. Contextual
  creation may also begin directly inside Shorts and Feed.
- System Back restores the exact previous query, filters, pagination, scroll
  position and playback context.
- Do not add a page-level “Back to Videos” pill.

## Videos discovery

Use a compact MoolSocial header:

- MoolSocial wordmark;
- an expandable Search action at the top-left;
- Notifications; and
- Account.

Do not show the service-area chip, full-width search field, scan control or
voice control on the YouTube-centred Videos surface.

Typing filters already-cached items locally. It must not consume a provider
search request. A remote `search.list` request occurs only after the user
explicitly submits Search.

Provider-backed discovery may include:

- Popular in India;
- Live now;
- videos from selected or connected channels;
- public playlists;
- Learning;
- verified Shorts when an item is positively classified; and
- Local or Business only when supported by genuine MoolSocial curation or
  explicit API-backed queries.

Never label MoolSocial-selected content as YouTube recommendations and never
claim access to YouTube Home, the personalized recommendation graph, native
Shorts feed, watch history or Watch Later.

The cost-efficient discovery order is:

1. regional most-popular videos;
2. approved-channel uploads playlists;
3. curated public playlists;
4. webhook-driven refresh when later approved;
5. batched statistics hydration; and
6. explicit user Search.

Required states include:

- cache loading, fresh ready, stale cache and offline cache;
- refreshing;
- pagination loading, failure and retry;
- search loading, results, empty, failure and quota exhausted;
- provider disabled;
- restricted, removed, private, region-blocked and unembeddable content; and
- metadata absent.

Unavailable metadata is omitted. It is never replaced with a sample or
fabricated value.

## Official YouTube player boundary

The HTML reference must not simulate a YouTube player. It may show only a
neutral player boundary that states that the official YouTube player loads in
the native app.

Flutter hosts the provider-owned IFrame Player in an isolated Android WebView
or iOS WKWebView under the sole WebView exception in `AGENTS.md`.

- Only one player may be active.
- Player controls, attribution, branding, captions, ads and provider links
  remain intact.
- MoolSocial controls, commerce cards and overlays remain outside the player
  rectangle.
- MoolSocial must not intercept provider-player gestures.
- Pause or release the player on app backgrounding, calls, route changes and
  disposal.
- Cover fullscreen, rotation, captions, audio focus, reconnect and player
  errors `2`, `5`, `100`, `101`, `150` and `153`.
- Cover age, region, embedding and network restrictions.

Below the player, show only returned provider data:

- title;
- channel identity;
- published date;
- views, likes and comment count when available;
- description, hashtags and category;
- public comments and replies; and
- clear YouTube attribution.

MoolSocial-native actions remain visually separate:

- Save;
- Discuss;
- Share; and
- an eligible product, service or campaign card.

A commerce card appears only when the provider content has a genuine
MoolSocial campaign association. It must never be attached to an unrelated
video. “More to watch” means MoolSocial-selected content and must not be
presented as the provider’s recommendation service.

## Public channel details

Display actual values only:

- title and thumbnail;
- handle or custom URL;
- description;
- country and topics;
- public video, view and subscriber values when returned;
- uploads; and
- public playlists with pagination.

Cover loading, empty, hidden subscriber count, removed, unavailable, failure
and pagination recovery states.

## Comments and provider-owned actions

Public comments may expose:

- complete text;
- author identity;
- published or updated time;
- likes;
- replies; and
- pagination.

Cover disabled, empty, deleted, restricted, failure and reply-expansion states.
Do not display a fabricated preview comment.

YouTube Like, Comment and Subscribe require a separately consented viewer
connection and the exact acting channel must be shown. Each action requires
pending, confirmed, failed and reconciliation states. `Discuss` is a
MoolSocial conversation and must never be confused with a YouTube comment.

Provider mutation endpoints remain excluded until their extra OAuth scopes,
audit implications and complete reconciliation contracts are separately
approved.

## Shorts

The Shorts surface may combine:

- MoolSocial-owned Reels; and
- positively verified public YouTube Shorts.

It must not claim to reproduce YouTube’s native Shorts feed.

YouTube Shorts use the official player. Creator metadata, MoolSocial actions
and commerce appear in a separate expandable area outside that player.
Explicit next and previous controls remain outside the player until physical
device testing proves a compliant vertical-swipe interaction. MoolSocial Reels
may retain native overlays, contextual commerce and promotion disclosure.

## Viewer and creator connection states

Cover:

- consent;
- system-browser handoff;
- cancellation;
- wrong account;
- no channel;
- multiple-channel selection;
- callback pending;
- exact channel confirmation;
- connected;
- expired or revoked;
- offline;
- disconnect; and
- provider-data deletion.

## Creator upload

Creator upload belongs in Account or Creator Workspace, not in the public
consumer feed.

The flow includes:

- destination channel;
- media selection;
- title, description and category;
- privacy locked to `private` during unaudited Dev;
- made-for-kids declaration;
- synthetic-media disclosure;
- paid-promotion disclosure;
- rights and copyright confirmation;
- direct phone-to-YouTube resumable upload;
- progress, background resume, retry and cancel;
- provider processing;
- success, rejection and revoked-auth recovery.

There is no separate Shorts upload API. Vertical short-form content uses the
normal video upload endpoint and YouTube determines its eligible surface.

## Analytics and commerce attribution

Creator Workspace may display returned owner Analytics with:

- report and date range;
- source;
- last refreshed time; and
- loading, empty, stale, limited, unauthorized, revoked, quota and failure
  states.

Do not infer revenue, CPM, audience or brand-safety values.

MoolSocial commerce analytics remain separate:

- campaign link;
- product or service;
- orders;
- delivered and returned orders;
- creator commission; and
- payout status.

Creator commission depends on MoolSocial-attributed commerce, never YouTube
views, likes, comments or subscriptions. MoolSocial must never incentivize
provider engagement actions.

## Removed or reworked behavior

The next HTML revision must remove or rework:

- fake provider players or copied player controls;
- fabricated counts, comments, channel values, earnings or connection
  outcomes;
- provider actions that appear operational without the required viewer
  connection;
- static “More to watch” content presented as provider recommendations;
- commerce attached to unrelated provider content;
- MoolSocial overlays inside a provider player;
- provider searches triggered while typing;
- simulated connection and Analytics values;
- unnecessary page-level Back pills; and
- artificial text-scale caps.

## Fitment and acceptance

Test every named state at 100% and 140% text on:

- 320×568;
- 360×640;
- 360×720;
- 375×667;
- 390×844;
- 412×915; and
- 430×932.

Also prove:

- minimum 44×44 touch targets;
- no artificial text-scale cap;
- provider player at least 200×200 and 16:9 where practical;
- Android and iOS safe areas;
- long Hindi and English titles, RTL, missing metadata and captions;
- reduced motion and semantic focus order;
- background, foreground, phone call, audio focus, headset, rotation and
  network transitions;
- exact Back restoration and player disposal; and
- every tap, nested tap and recovery path on the physical OPPO.

## Implementation order

1. Complete and verify the permitted public and owner provider contracts.
2. Prove private Dev security, quota and cost controls.
3. Revise the editable HTML against observed provider behavior.
4. Run browser and named-state verification.
5. Present the exact HTML URL for founder review.
6. Wait for explicit founder `FINAL`.
7. Freeze a new immutable reference and interaction contract.
8. Implement the native Flutter presentation and provider client.
9. Compare HTML and Flutter at identical state, viewport and text scale.
10. Complete physical OPPO replay and founder acceptance.

## Binding provider contracts

- [YouTube comprehensive capability gap audit](YOUTUBE-COMPREHENSIVE-CAPABILITY-GAP-AUDIT-20260724.md)
- [YouTube embedded-player runtime contract](YOUTUBE-EMBEDDED-PLAYER-RUNTIME-CONTRACT-20260724.md)
- [YouTube WebSub approved-channel refresh contract](YOUTUBE-WEBSUB-APPROVED-CHANNEL-REFRESH-CONTRACT-20260724.md)
