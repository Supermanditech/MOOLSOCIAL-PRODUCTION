# C29E founder findings — YouTube native-ownership redesign

Date: 2026-08-11
Branch: `remediation/prototype-conformance-2026-07-20`
Predecessor: C29D / `1.0.0-r60.30`
Founder decision: current Social presentation rejected; evidence and installed identity preserved.

## Bounded observation

The C29D runtime proved that real App Check-protected YouTube catalogue and official embedded playback work on OPPO. It did not meet founder presentation expectations. The navy MoolSocial header, inset vertical player, side gutter/action rail and white legacy destination dock make Shorts read as an embed placed inside the old Social screen instead of a coherent YouTube-owned experience.

The founder-provided journey reference is the seven-image set already preserved without modification in `tmp/oppo-youtube-social-reference-20260810/`:

1. `Screenshot_2026-08-10-22-10-11-91_f9ee0578fe1cc94de7482bd41accb329.jpg` — edge-to-edge Shorts viewer, minimal top overlay, creator metadata, action rail and black five-item dock.
2. `Screenshot_2026-08-10-22-10-33-36_ab1359306de43320f9557c797b1c4be5.jpg` — plus-entry permission gate and truthful gallery fallback.
3. `Screenshot_2026-08-10-22-10-46-73_f9ee0578fe1cc94de7482bd41accb329.jpg` — Short capture tool hierarchy.
4. `Screenshot_2026-08-10-22-11-36-14_f9ee0578fe1cc94de7482bd41accb329.jpg` — post composer, visibility, gallery and disabled submit state.
5. `Screenshot_2026-08-10-22-11-57-38_f9ee0578fe1cc94de7482bd41accb329.jpg` — dark YouTube Home, topic chips, Shorts shelf and native five-item dock.
6. `Screenshot_2026-08-10-22-12-09-29_f9ee0578fe1cc94de7482bd41accb329.jpg` — full-width video cards with title/channel/age metadata.
7. `Screenshot_2026-08-10-22-17-47-81_f9ee0578fe1cc94de7482bd41accb329.jpg` — watch page with official player followed by metadata and actions.

## Reuse and duplicate assessment

- Reuse `SocialUniversalV2`, its existing `videos`, `shorts`, `feed` and `create` state owners, the official Android YouTube platform player, the App Check-protected public provider client, the existing MoolSocial post/media owners and the existing Mool switcher callback.
- Keep the internal `videos` route/state identifier as a compatibility alias while presenting it to customers as `Home`. This avoids a duplicate route and preserves accepted deep links.
- Replace the visual shell only inside the Social owner. Do not change other family navigation or the read-only HTML screenbook.
- Do not create a second player, media backend, post backend, upload backend, auth owner or provider route.
- Existing real public endpoints already expose page tokens. Bounded client pagination can target 20 eligible items without a provider deployment.

## Required ownership result

- YouTube Home and Shorts use a black, edge-to-edge, YouTube-attributed shell.
- Shorts remove the navy global header, inset stage, side gutter and white legacy dock.
- Following the founder's 2026-08-11 global-navigation clarification, the Social dock becomes `Home · Shorts · + · Feed · Chat · Mool`: Home and Shorts are YouTube-owned; `+` and Feed are MoolSocial-owned; Chat and Mool remain common one-tap global controls. Chat is outside the official player and replaces the redundant Social header Chat control, so Shorts keep the full available viewport without an overlay.
- `+` opens the real MoolSocial creation owner. Text, image, carousel and other already-implemented MoolSocial formats remain MoolSocial-hosted.
- YouTube Short distribution is never represented as successful until real owner OAuth, required scopes, upload route, progress/error/retry/cancel and provider tests are separately active. The current public-data capability must show an honest connection/availability gate.
- Home targets 20 eligible current India videos. Shorts targets 20 eligible creator-declared Shorts. If the provider cannot return 20 eligible records within the bounded page budget, the UI shows the truthful available count and never fabricates filler.

## Official YouTube boundary

The redesign uses YouTube branding only for the YouTube component and keeps the logo linked to YouTube content. It retains the official embedded player, its controls and its minimum dimensions. It must not obscure, restyle or place MoolSocial overlays over any part of the embedded player. Supported app chrome may sit outside the player; the player remains the audiovisual owner.

Authoritative references reviewed on 2026-08-11:

- https://developers.google.com/youtube/terms/branding-guidelines
- https://developers.google.com/youtube/terms/required-minimum-functionality
- https://developers.google.com/youtube/player_parameters
- https://developers.google.com/youtube/v3/determine_quota_cost

## Disposition

C29D is permanently closed as founder UI/UX rejected and cannot be rebuilt or reinstalled. C29E is the only active source successor. No new APK candidate exists, and no build/install authority is open. A later device candidate requires completed source tickets, focused tests, complete gates and two fresh host qualification cycles.
