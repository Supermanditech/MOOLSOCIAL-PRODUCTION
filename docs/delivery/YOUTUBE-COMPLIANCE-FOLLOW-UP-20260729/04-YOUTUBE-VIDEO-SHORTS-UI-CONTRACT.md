# YouTube video and Shorts UI contract

## Scope

This is the policy-aligned interaction contract for the next editable
founder-review cycle. It does not freeze Screen 04, authorize Production
traffic or claim disabled endpoints are live.

## 1. Native Videos library

The first screen is MoolSocial-owned native Flutter:

- native `Videos` destination inside Social;
- compact category row such as `All`, `Popular`, `Live`, `Learning`, `Local`
  and `Business` only when each choice has a real supply rule;
- expandable explicit search, not search on every keystroke;
- paginated cards with unmodified thumbnail, title, channel, duration,
  publication time and available public statistics;
- compact YouTube source attribution on every provider card;
- serviceable MoolSocial campaign marker only when a real campaign binding
  exists; and
- truthful unavailable/restricted/retry states.

The library is never named or styled as YouTube Home.

## 2. Selected video

Order from top to bottom:

1. native compact MoolSocial header and Back destination;
2. official YouTube player, fully visible and never covered;
3. source/channel/title/public metadata;
4. `MoolSocial` actions — Save, Discuss, Share and Details;
5. optional connected `YouTube actions` entry for explicit Like, Comment and
   Subscribe after separate consent;
6. optional campaign-linked products with disclosure; and
7. more MoolSocial-selected eligible videos, never labelled YouTube `Up next`.

The player stays at least 200×200 and large enough for its controls. Only one
player is active.

## 3. Shorts

- one continuous vertical Social journey;
- MoolSocial Reels and positively classified YouTube Shorts can coexist;
- source identity visible before playback;
- official portrait player for YouTube items;
- one item/player active at a time;
- swipe changes the native selected item and releases the prior player;
- no overlay or fixed MoolSocial action over the player;
- metadata/actions use separate native space outside the player; and
- no claim of YouTube's native Shorts recommendations.

### Navigation and visual-identity decision

- Keep the text labels `Shorts` and `Videos`.
- Use the unaltered YouTube attribution icon beside YouTube-sourced items.
- The source icon or attribution opens the corresponding YouTube
  content/component.
- MoolSocial may use a generic centred `Create` plus action, but the action is
  MoolSocial-owned and must not imply that it uploads to YouTube.
- YouTube upload is exposed only after the separately gated `videos.insert`
  workflow is approved, implemented and explicitly selected by the user.
- Do not reproduce the YouTube Shorts application pixel-for-pixel. The
  vertical gesture is familiar interaction behaviour, while MoolSocial keeps
  its own header, navigation, typography, actions and content hierarchy.
- A screenshot of the native YouTube application is design-reference evidence
  only and is excluded from the YouTube API client submission package.

## 4. Connected YouTube actions

MoolSocial sign-in is not YouTube authorization. The first provider mutation
opens a compact benefit explanation and `Connect YouTube`. Consent occurs in
the system browser.

After connection:

- every action names YouTube and the acting channel;
- pending results remain pending until reconciled;
- MoolSocial Save/Follow/Discussion remain distinct;
- Like, Comment, Subscribe and playlist actions never earn MoolSocial reward;
  and
- disconnect and retained-data deletion remain accessible.

## 5. Creator Workspace

Creator publishing lives under `Profile → Creator account`, not the public
consumer feed.

The staged upload journey is:

1. exact channel;
2. media and rights/audience declaration;
3. title, description and privacy;
4. destination-specific review;
5. resumable upload;
6. pause/retry/resume/cancel;
7. provider processing; and
8. reconciled YouTube video ID/result.

Until the exact project passes the applicable audit, customer-visible public
or unlisted upload cannot be claimed.

## 6. Motion and accessibility

- motion clarifies selection, player mounting and item replacement;
- no automatic motion interferes with provider controls;
- reduced-motion mode replaces movement with immediate state change;
- captions and accessibility remain provider/player compatible;
- 140% text keeps titles, source attribution and actions reachable;
- portrait/landscape and fullscreen preserve one active player; and
- app background, audio focus and disposal stop or release playback as
  required.

## 7. Commerce separation

Commerce never occupies player pixels. Campaign-linked products appear only
after the provider record and metadata in a clearly MoolSocial-owned section.
Independent placements are labelled `Promoted on MoolSocial` and remain
useful without the YouTube data.
