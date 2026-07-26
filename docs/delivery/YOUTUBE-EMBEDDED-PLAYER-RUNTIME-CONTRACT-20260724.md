# YouTube embedded-player runtime contract — 24 July 2026

## Status

This is the production contract for the future native Flutter V2 player
boundary. It does not authorize Flutter or Screen 04 changes before the
provider proof, revised HTML founder `FINAL` and immutable freeze.

## Runtime isolation

- Use one isolated OS player WebView and one official YouTube IFrame player:
  Android `WebView`, iOS `WKWebView`.
- Bundled HTML contains only official-player bootstrap and a typed event
  bridge. It contains no MoolSocial UI, authentication, commerce, navigation
  or business logic.
- Discovery cards, metadata and MoolSocial controls are native Flutter.
- Never create hidden players per card. Only one player may be mounted or
  audible.

## Eligibility and provider authority

Before mounting, require:

- a valid video ID;
- a current Data API record;
- `status.embeddable = true`; and
- no known device-region exclusion.

These checks are advisory. The official player is the final authority for
rights, age, privacy, removal, region and playback restrictions. Known
ineligible content opens a native unavailable state with a user-initiated
`Open in YouTube` action.

## Identity and bridge

- Stable base URL, Referer and origin:
  `https://com.moolsocial.app/`.
- Android uses `loadDataWithBaseURL`; iOS uses
  `loadHTMLString(..., baseURL:)`.
- Set `enablejsapi=1`, `origin=https://com.moolsocial.app` and
  `strict-origin-when-cross-origin`.
- Never load from `file:`, `data:`, `about:blank`, localhost, a no-referrer
  context or an arbitrary origin.
- Do not use Android `addJavascriptInterface`.
- Use an origin-allowlisted WebMessage channel on Android. On iOS accept
  messages only from the expected main-frame security origin.
- Commands are typed and closed: cue/load, play, pause, seek, mute/unmute,
  caption preference, state request and dispose. Never permit arbitrary
  JavaScript execution.

## Player configuration

- Baseline: `autoplay=0`, `controls=1`, `fs=1`, `playsinline=1`,
  `enablejsapi=1`.
- Preserve branding, controls, settings, captions, advertising, related
  content, end screens and provider links.
- Do not hide branding, fake quality controls, recolour, mask, round-crop,
  cover or place a gesture layer over the player.
- User-initiated YouTube logo, channel, help, related-content and account links
  open the YouTube app when available, otherwise the system browser.
- OAuth always uses the system browser, never this WebView.

## Fitment

- Player viewport is never smaller than 200×200 CSS pixels.
- Standard video uses full available width and
  `height = max(width × 9 / 16, 200)`.
- At 320 px width use 320×200, not 320×180.
- A positively verified vertical Short may use 9:16 while still meeting the
  minimum.
- Thumbnails are at least 120×70.
- No clipping or horizontal overflow at the seven required phone viewports at
  100% and 140% text.

## Lifecycle and autoplay

- Switching content pauses and cues the reused player, or disposes the old
  player before creating another.
- Pause when less than 50% visible, route-hidden, app-inactive, backgrounded,
  locked, interrupted by a call, or after audio-focus loss.
- Return to the app paused until the user resumes.
- Never implement background playback or audio-only extraction.
- Videos do not autoplay or automatically advance.
- Shorts autoplay is a future feature flag only after proof, and requires
  greater-than-50% visibility, foreground, unlocked screen, audio focus and no
  other player.
- `onAutoplayBlocked` waits for user action; reduced motion disables autoplay.

## Fullscreen and Back

- Use provider fullscreen only.
- Android implements `WebChromeClient.onShowCustomView/onHideCustomView`.
- iOS enables inline playback and supported element fullscreen.
- Back exits fullscreen first and restores the same item/timestamp; the next
  Back performs MoolSocial navigation.
- Restore prior orientation, system UI and focus.
- No custom picture-in-picture in MVP.

## State and error mapping

Player states:

- `-1` initializing/unstarted;
- `5` cued/ready;
- `3` buffering;
- `1` playing;
- `2` paused; and
- `0` ended.

Errors:

- `2`: invalid request/ID; non-retryable integration defect;
- `5`: player failure; one explicit recreation/retry, then provider handoff;
- `100`: removed/private/not found; refresh metadata and remove stale result;
- `101`/`150`: embedding disabled; show playback unavailable here and provider
  handoff;
- `153`: missing Referer/client identity; release-blocking configuration
  defect, not a retry loop.

Do not invent a specific restriction reason without provider evidence.

## Recovery, privacy and analytics

- Combine native connectivity, main-frame errors and a ready timeout.
- Detach the provider player before displaying native failure/retry UI. Never
  overlay it.
- Retry is user initiated, bounded and circuit-broken; selection is preserved
  and remains paused after recovery.
- Provider captions remain provider-controlled.
- MoolSocial commerce and campaigns remain outside and visually separate from
  the player. The player is not MoolSocial ad inventory.
- Operational telemetry may record sanitized readiness latency, error code,
  fullscreen/retry and WebView version.
- Do not derive watch-time, completion, profiles, ranking signals or
  MoolSocial engagement scores from player time/state without a separate
  policy audit.
- Disclose third-party YouTube/Google content and data loading.

## HTML versus provider proof

HTML may model native discovery, metadata fixtures, native controls and
neutral correctly sized loading/offline/unavailable player boundaries.

HTML must not fake playback, player controls, ads, captions, provider branding,
restrictions, provider links, errors, comments or recommendations.

Native proof must show genuine origin/Referer, state events, captions,
fullscreen, provider links, related content, one-player/no-hidden-audio
behavior, restrictions, offline/recovery and lifecycle interruptions.

## Acceptance gates

OPPO:

- valid and invalid origin/Referer including deliberate Dev-only error 153;
- all states and available legal error fixtures;
- captions, fullscreen, orientation and Back;
- rapid switching and one-audio-source proof;
- app switch, lock, call, audio focus, headset/Bluetooth and process death;
- TalkBack, text scaling, reduced motion and a 30-minute lifecycle soak.

Android proof does not approve iOS. A physical iPhone `WKWebView` pass is
mandatory before iOS acceptance.

## Official authorities

- <https://developers.google.com/youtube/iframe_api_reference>
- <https://developers.google.com/youtube/terms/required-minimum-functionality>
- <https://developers.google.com/youtube/player_parameters>
- <https://developers.google.com/youtube/terms/developer-policies>
- <https://developer.android.com/privacy-and-security/risks/insecure-webview-native-bridges>
- <https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/allowsinlinemediaplayback>

## Disabled local foundation checkpoint — 24 July 2026

The isolated typed runtime foundation is implemented under
`apps/mobile/lib/core/youtube/youtube_embedded_player_*` and remains disabled
by default. It contains no WebView plugin, Android/iOS adapter, Screen 04
presentation wiring or arbitrary JavaScript bridge.

Independent analysis passed with no issues; the player and existing
private-Dev client suites passed `47/47`; forbidden bridge scans returned zero
matches; and Screens 01–03 locks passed. Durable evidence and exact source
hashes are at
`artifacts/quality/youtube-embedded-player-local-20260724-01/LOCAL-PLAYER-FOUNDATION-EVIDENCE.md`.

This is not provider proof. Platform adapters, real origin/Referer and event
proof, captions/fullscreen/provider-link/error testing, OPPO interruptions and
physical iPhone verification remain open.
