# Step-by-step YouTube API client screencast

## Recording specification

- Target duration: 3–5 minutes.
- Output: MP4 with the portrait OPPO screen centred and readable at full size.
- Device: founder-authorized OPPO connected to the laptop.
- Client: `youtube-compliance-followup-20260729-20`.
- APK SHA-256:
  `641957A49AFC9F6A8D742CF71A4F22E65832F2443701BDB89F7C06BEE6EAC8FC`.
- Repository commit:
  `0aaa32bfd383b77a392b3426a49e6ef3744493dd`.
- Project: `moolsocial-dev-503018`.
- Do not edit the recording to imply that two separate runs are one continuous
  provider response. A cut or replay must receive a visible caption.
- Turn on Do Not Disturb and remove private notification previews before
  recording.
- Do not expose Google credentials, OAuth codes/state, tokens, API keys,
  Firebase identifiers or personal data.

## Opening card — 10 seconds

Show:

- `MoolSocial YouTube API client — private Dev compliance walkthrough`;
- project ID;
- Android package;
- exact APK SHA-256;
- exact repository commit;
- recording date;
- `Public data + read-only owner connection`;
- `No Production access claimed`.

Narration:

> This is the real MoolSocial private-Dev Android client. It uses YouTube Data
> API services for eligible public discovery and a separately authorized
> read-only channel connection. Playback is supplied by the official YouTube
> embedded player. MoolSocial does not download or proxy YouTube video.

## Step 1 — Open the real MoolSocial Videos library — 35 seconds

1. Launch MoolSocial from a cold start.
2. Enter `Mool`, then `Social`, then `Videos`.
3. Keep the provider source label visible.
4. Slowly scroll through several distinct cards.
5. Show title, thumbnail, channel, duration/publication metadata and available
   public counts.
6. Show one real category or pagination change only if that exact action is
   provider-backed in the recorded build.

Narration:

> MoolSocial renders a native catalogue using eligible YouTube metadata. The
> low-quota starting source is `videos.list` with the India `mostPopular`
> chart, followed by permitted channel enrichment. MoolSocial ranks the
> returned choices and does not claim that this is YouTube Home or YouTube's
> personalized recommendation feed.

Visible outcome:

- multiple genuine YouTube items;
- YouTube source identity;
- no copied YouTube navigation;
- no fabricated product link.

## Step 2 — Select and play one video — 45 seconds

1. Tap one eligible video card.
2. Show the isolated official player mounting.
3. Start playback deliberately.
4. Keep provider branding, controls and `Watch on YouTube` visible.
5. Show that MoolSocial metadata/actions sit below or outside the player.
6. Return to the native catalogue.

Narration:

> Selecting a card loads one official YouTube embedded player in an
> OS-provided WebView. MoolSocial does not overlay, restyle or obstruct the
> player. Player advertising and controls remain YouTube-owned. Leaving the
> selected item releases the active player.

Visible outcome:

- real frame playback;
- official controls;
- one active player;
- direct return to the native MoolSocial library.

## Step 3 — Open the real Shorts lane — 55 seconds

1. Select `Shorts`.
2. Select the recorded build's YouTube source/filter.
3. Show the first real Short's title, channel and source identity.
4. Start the official portrait player.
5. Swipe once to the next distinct real Short.
6. Show the second title/channel and playback surface.

Narration:

> YouTube does not provide a general public `isShort` field. This private-Dev
> client admits an item only when it is public, processed, embeddable and
> available in India, the creator-declared metadata identifies it as a Short,
> and its returned duration is within the bounded lane. Duration alone is not
> treated as proof. A swipe changes MoolSocial's selected item and releases
> the prior player.

Visible outcome:

- two distinct real Shorts;
- provider source remains visible;
- no claim of access to YouTube's native Shorts recommendation feed.

## Step 4 — Show the separate YouTube channel connection — 45 seconds

Use the clearly dated supervised proof. Do not disconnect or re-authorize the
founder-controlled channel merely to make the recording appear continuous.

1. Caption the segment `Dated supervised proof — 26 July 2026`.
2. Show that MoolSocial sign-in and YouTube connection are separate.
3. Show the system-browser account/channel selection and read-only purpose
   without exposing a credential, token, OAuth code or state.
4. Show the exact native Share from YouTube screen.
5. Show the automatic token-free return and temporary success confirmation.
6. State the reconciled VetoNews channel ID in the accompanying reference,
   not as an unverified claim on the app screen.

Narration:

> The YouTube connection begins only from a feature that needs it. OAuth uses
> the system browser. The backend validates the OAuth response and reconciles
> the selected channel. The browser result is not treated as durable success
> by itself. Refresh tokens remain server-side.

Visible outcome:

- exact channel chosen by the user;
- read-only scope;
- safe native return;
- no token or internal user identifier in the return route.

This dated proof is not presented as part of the current continuous playback
run.

## Step 5 — Clarify the submitted endpoint scope — 20 seconds

Show a reviewer card stating:

- `Demonstrated now: videos.list, channels.list, bounded search.list,
  official embedded playback and youtube.readonly channel connection`;
- `The original broad endpoint selection described a staged roadmap`; and
- `Uploads, viewer mutations, Analytics/Reporting and Live management are not
  represented as active`.

Narration:

> The original quota form included a broad future method inventory. This
> screencast demonstrates only the currently implemented API Client boundary.
> MoolSocial asks YouTube to assess this demonstrated boundary and advise
> whether a corrected form is required before separately gated future
> capabilities are reviewed.

## Closing card — 20 seconds

Show:

- `Demonstrated: public discovery, official playback, Shorts lane, read-only
  owner connection and native return`;
- `Not claimed live: uploads, viewer mutations, Analytics/Reporting, Live
  management or Production approval`;
- `No MoolSocial advertising or commerce inside or over the YouTube player`;
- monitored contact `hello@moolsocial.com`;
- the exact APK and recording SHA-256.

## Post-recording verification

Before attaching:

1. watch the full recording at normal speed;
2. verify every displayed API result belongs to the exact recorded build;
3. verify the player is never covered;
4. verify no secret or private notification is visible;
5. verify captions do not claim personalized YouTube recommendations;
6. verify future UI is unmistakably labelled as planned;
7. calculate and record the video SHA-256; and
8. preserve an unedited source recording and one redacted reviewer copy if
   redaction was required.
