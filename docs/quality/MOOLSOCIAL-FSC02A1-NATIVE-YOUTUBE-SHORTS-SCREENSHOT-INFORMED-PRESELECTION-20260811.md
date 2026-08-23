# FSC02A1 native YouTube Shorts screenshot-informed composition preselection

- Ticket: `MOOLSOCIAL-FSC02A1-NATIVE-YOUTUBE-SHORTS-SCREENSHOT-INFORMED-COMPOSITION`
- Founder direction: on 2026-08-11 the founder rejected the obsolete HTML-first plan, directed a current-native audit against the recent OPPO YouTube journey screenshots, and explicitly approved direct Flutter implementation.
- Classification: `mvp_required`
- Customer outcome: an authenticated Personal user watches real eligible YouTube Shorts inside MoolSocial through an immersive, familiar and clearly YouTube-owned native composition while MoolSocial navigation and local actions remain distinct and reachable.
- Delivery impact: one source-only composition and acceptance slice, estimated at two days and within the founder-locked 60–75-day robust-MVP window.

## Evidence and ownership boundary

The seven images in `tmp/oppo-youtube-social-reference-20260810` are retained read-only journey and spatial evidence. They show the YouTube Shorts viewer, creation entry, capture surface, post composer, Home/Shorts discovery, long-form discovery and video watch journey. They are not MoolSocial application assets, a licence to copy pixels or provider trade dress, evidence of API capability, or authority for upload/OAuth work.

The existing native owners are sufficient:

- `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`
- `apps/mobile/lib/ui_v2/social/social_v2_youtube_public_runtime.dart`
- `apps/mobile/lib/core/youtube/youtube_embedded_player_android.dart`
- `apps/mobile/lib/core/youtube/youtube_embedded_player_contract.dart`
- the existing Screen 04, provider-runtime, fitment, copy and navigation test owners

No new screen, route, state owner, backend, API client, OAuth owner, player or build is required. FSC02A already supplies the real provider catalogue, positive Shorts admission, truthful failure/recovery states, vertical pager and official embedded player. This successor is limited to the existing Shorts composition and focused acceptance.

## Exact keep, adopt and reject decision

Keep unchanged:

1. The accepted Mool switcher, outer global navigation and one-tap Shorts, Videos, Feed and Create reach.
2. Vertical one-Short-per-page navigation and one active official player.
3. The current public, processed, embeddable, region-allowed and creator-declared provider admission.
4. Real provider title, channel, thumbnail, count and date data.
5. YouTube attribution plus the explicit external YouTube escape.
6. Separate MoolSocial Save, Discuss and Share actions.
7. Truthful provider-access, loading, empty, unavailable, error and retry states.
8. Minimum 44-by-44 actions, compact fitment, native Back behavior and no fabricated content.

Adopt as familiar spatial inputs, implemented in MoolSocial native code rather than copied from screenshots:

1. A continuous black, clearly YouTube-owned Shorts stage.
2. A larger near-edge portrait player area with less card chrome.
3. A compact YouTube/Shorts identity layer with sequence and external-open controls.
4. A visually lightweight lower-right vertical MoolSocial action rail.
5. Real channel, title and metadata visually anchored near the lower stage, outside the player bounds.
6. A subtle vertical sequence cue that does not add another navigation system.

Do not adopt:

1. YouTube global bottom navigation, search, menu or notifications.
2. YouTube Like, Comment, Subscribe, Dislike, Remix, Add sound or capture tools.
3. YouTube's central `+`, camera permission journey or any upload/post flow.
4. Personalized Home chips, recommendations, ads or sponsored content.
5. Screenshot pixels, provider content, copied layouts/assets or trade dress.
6. Any MoolSocial control, label, frame or overlay in front of the embedded player.

## Official player constraint

YouTube's current Required Minimum Functionality and embedded-player guidance require an embedded player of at least 200 by 200 and prohibit overlays, frames or visual elements in front of any part of the player or its controls. Therefore the familiar Shorts hierarchy will be achieved with one continuous black parent stage whose compact identity, action rail and metadata are adjacent to the exact player rectangle, never painted over it. The player appearance and controls will not be altered outside documented player parameters.

Primary requirements:

- https://developers.google.com/youtube/terms/required-minimum-functionality
- https://developers.google.com/youtube/player_parameters
- https://developers.google.com/youtube/terms/developer-policies-guide

## Smallest complete scope and tests

The implementation replaces the current navy header, rounded inset player and separated card-like metadata treatment with the continuous stage described above. It preserves all provider and navigation contracts, adds no API or upload capability, and does not touch Videos, Feed, Create, Shop or the HTML screenbook.

Focused verification covers provider states, single-active-player ownership, 200-by-200 minimum geometry, absence of an overlay/`Stack` in the player slot, distinct MoolSocial actions, 44-by-44 reach, 320-by-568 at 140% text, customer copy, one-tap Social navigation, approved UI locks, MVP scope/delivery discipline and permanent regression memory.

Build, install and OPPO mutation remain held. The provider runtime authority and selected-build-mode official-player packaging gates from FSC02A remain active. A new APK candidate requires a separately recorded fresh host qualification and a checksum-unique successor before the protected r60.28 install may be changed or tested.

## Paused work preservation

FSC03A Feed source and tests were started under the earlier sequence and are preserved in the dirty tree, but the founder corrected the order before its focused verification completed. FSC03A is paused and unverified; it is not reverted, advanced or claimed complete while FSC02A1 is active.

## Native implementation result

The source-only FSC02A1 composition is complete. `social_v2_consumer.dart` now presents eligible provider Shorts on one continuous black stage. The previous navy provider bar, rounded inset player card and separated metadata panel were removed. The new composition uses a larger explicit portrait player slot, compact YouTube/Shorts identity, sequence and swipe cue, an external YouTube control, lower-stage real provider title/channel/optional metadata, and lightweight circular MoolSocial Save, Discuss and Share actions.

The exact player rectangle is never wrapped in an outer overlay or `Stack`. At the minimum available-state acceptance viewport, the player remains at least 200 by 200 and the first MoolSocial rail action starts at or to the right of the player rectangle. The local actions remain at least 44 pixels high. Nullable provider views and publication dates are conditionally omitted rather than replaced with fabricated values.

Focused Flutter analysis passed with no issues. The complete six-file Social replay passed all 76 tests, covering provider admission and failure states, provider-action exclusions, player/action ownership, 320-by-568 compact fitment at 140% text, connected navigation, customer copy and the wider Screen 04 fitment matrix. Approved UI locks, MVP delivery discipline, authorized MVP scope, permanent regression memory and all seven screenshot evidence paths also pass.

No HTML file, backend, credential, provider environment, APK machine state or OPPO application state was changed. No APK was built and no successor device candidate was registered. The installed r60.28 identity remains protected.

The next lawful step is not an install. An available-state OPPO candidate still requires the existing FSC02A provider-runtime authority and a truthful selected-build-mode official-player packaging path, followed by a fresh APK host qualification. Only a checksum-unique qualified successor may then be built, installed and replayed on OPPO for founder review.
