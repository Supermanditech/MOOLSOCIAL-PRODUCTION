# C29L YouTube creator connection and private Short upload findings

## Founder finding

The Social bottom `+` currently opens only MoolSocial Create. There is no dedicated, customer-visible YouTube creator journey for connecting an exact channel or uploading a Short. The route currently named `youtube-connect` is a different legacy link-sharing presentation: it can set a local `youtubeChannelConnected` boolean and must not represent provider authorization.

## Reuse and duplicate assessment

- Reuse the existing authenticated `YouTubePrivateDevClient`, system-browser OAuth launcher, server-side OAuth state/PKCE flow, encrypted token vault, exact `channels.list(mine=true)` identity, direct-to-YouTube resumable uploader and processing reconciler.
- Reuse `NativeSocialMediaPicker` for camera/gallery video selection and `FileYouTubeUploadSource` for file identity and streaming.
- Preserve MoolSocial Create as the owner for text, image, image poll, quick poll, quiz and carousel. YouTube video bytes must never be hosted by MoolSocial.
- Do not reuse `CreatorSession.youtubeChannelConnected`, `YT-POST-166-0719`, or the old link-sharing completion state. They are not provider evidence.
- A new native presentation/controller is necessary because no customer UI currently owns provider capability discovery, exact-channel connection, private Short metadata, resumable progress, cancel/retry or processing recovery.

## MVP and authority disposition

This is MVP-required. The founder explicitly requires YouTube-hosted Short distribution through MoolSocial, and the existing Social creator gateway is incomplete without the truthful connection and upload journey. Founder authority permits native source and focused test work and supervised Dev provider qualification. It does not permit credential-value access, fabricated authorization, public/unlisted upload before YouTube audit, Production writes, provider messages, commit, push or deployment.

## Minimum truthful outcome

An authenticated eligible creator opens the Social `+`, deliberately chooses `Create a YouTube Short`, connects and verifies the exact YouTube channel in the system browser, selects a local vertical-intent video, enters required metadata and audience disclosures, confirms the private destination, then sees direct resumable upload progress, cancel/retry and provider-processing reconciliation. The UI fails closed when capability, authentication, consent, file, network, session or processing requirements are not satisfied.

## Protected device boundary

Installed OPPO r60.34 and all C28D/C29I/C29J/C29K evidence remain immutable. C29L is source-only until fresh host qualification passes. It may not build or install a successor under the C29K device state.

## Runtime capability reconciliation

The Dev controller activates exactly one expiring proof profile. Therefore the
Short creator must not require `ownerConnect` and `privateUpload` together.
The least-privilege `privateUpload` profile owns upload-purpose Google consent,
the exact connected-channel status needed for reconnect/disconnect, and the
private resumable upload. Read-only owner videos, playlists and subscriptions
remain exclusively behind `ownerConnect`. The impossible combined fixture from
the first host cycles is permanently registered and superseded; corrected
source requires two fresh cycles in the `20260811-02` evidence set.
