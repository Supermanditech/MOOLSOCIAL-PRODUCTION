# FSC02A native YouTube Shorts preselection

- Ticket: `MOOLSOCIAL-FSC02A-NATIVE-YOUTUBE-SHORTS-PROVIDER-DISTRIBUTION`
- Founder direction: on 2026-08-10 the founder stopped the HTML review path and explicitly directed implementation in Flutter.
- Classification: `mvp_required`
- Customer outcome: a Personal user opens Shorts and receives a provider-owned YouTube Shorts journey using only current, positively admitted provider records and the official embedded player, with truthful loading, empty, unavailable, failure and retry behavior.

## Reuse and duplicate assessment

The existing owners are sufficient and must be reused:

- `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`
- `apps/mobile/lib/ui_v2/social/social_v2_youtube_public_runtime.dart`
- `apps/mobile/lib/core/youtube/youtube_private_dev_client.dart`
- `apps/mobile/lib/core/youtube/youtube_embedded_player_android.dart`
- `apps/mobile/lib/core/youtube/youtube_embedded_player_contract.dart`
- existing YouTube public-runtime and embedded-player tests

No new screen, route, backend, API client, OAuth owner or player is necessary. The existing public runtime already requires current provider records to be public, processed, embeddable, available and not excluded in India, and admits Shorts only when the creator declares the format and the duration is within the supported maximum.

## Smallest complete native scope

1. Make the Shorts destination YouTube-owned only; do not append MoolSocial Reels or fixture YouTube records.
2. Retain the real public-data catalogue and official player owners.
3. Provide a professional portrait player layout with clear YouTube attribution and a separate MoolSocial Save, Discuss and Share rail.
4. Provide truthful loading, empty, unavailable, error and retry states.
5. Preserve the Mool switcher, accepted global navigation, one-tap Shorts/Videos/Feed/Create reach and minimum 44-by-44 targets.
6. Add focused widget/source tests before any APK work.

## Exclusions and gates

- No upload `+`, OAuth upload claim, like, comment, subscribe, remix or fabricated provider action.
- No fabricated provider video, creator, thumbnail, metric or engagement fallback.
- No Feed, Create or Videos redesign in this ticket.
- No new route, screen, backend, client or player owner.
- No credentials, Firebase submission, external-service write, Production write, commit, push, deploy or promotion.
- Build and install remain held until focused tests pass and a fresh APK host qualification explicitly authorizes a new candidate.
- The installed OPPO r60.28 package and data remain protected until a checksum-unique successor is qualified.

## Native implementation result

The selected source-only implementation is complete and its focused host gates
pass. `social_v2_consumer.dart` now exposes only the real public-runtime Shorts
catalogue: MoolSocial Reels, fixture YouTube records, `For You` and `Promoted`
Short modes, simulated provider actions and their orphaned widgets were removed.

The provider-available state uses one official embedded YouTube player in a
portrait surface with clear YouTube attribution. Save, Discuss and Share remain
visibly separate MoolSocial actions. The normal build fails closed when public
provider access is not authorized; loading, empty, unavailable, transport error
and retry states are distinct and customer-ready.

An `@visibleForTesting` loader seam verifies the available state with a
provider-shaped `Screen04YouTubePublicVideo` record at 320-by-568 and 140% text.
The production default remains `loadScreen04YouTubePublicShorts`; the seam adds
no runtime fixture catalogue, credential path, backend state or provider claim.

Focused evidence covers:

- zero-warning Flutter analysis for the changed runtime and test owners;
- public/processed/embeddable/region and creator-declared Short admission;
- no fabricated Shorts fallback or upload/Like/Comment/Subscribe/Remix action;
- provider-owned player plus separate MoolSocial Save/Discuss/Share actions;
- 44-by-44 reach, compact-phone fitment, customer copy and connected navigation;
- permanent regression memory, MVP scope and delivery-discipline gates.

The final combined focused Flutter replay passed all 75 tests across six test
owners. The changed runtime and test owners also passed focused Flutter analysis
with no issues.

No APK was built. No app was installed, downgraded, uninstalled or cleared. The
installed OPPO r60.28 identity and all C28D evidence remain unchanged. The next
step is a separately recorded APK host qualification; only a checksum-unique
qualified successor may proceed to OPPO testing and founder review.

## Provider-runtime and OPPO gate

A read-only replay found the intended OPPO connected as `2b3e0f71` / `CPH2375`.
It still holds `com.moolsocial.app` version `1.0.0-r60.28` / `2026081028`, last
updated at `2026-08-10 20:18:55`. No device mutation occurred.

An available-state APK candidate is not yet truthful to register. The reused
client admits public YouTube data only when all of these are supplied by the
authorized external environment:

- `MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF=true`;
- `MOOLSOCIAL_USE_EMULATORS=false`;
- Firebase project `moolsocial-dev-503018`;
- an authorized valid `MOOLSOCIAL_YOUTUBE_PROVIDER_URL`;
- accepted Firebase Auth identity and Play Integrity App Check;
- provider response `capabilities.publicData=true`.

No endpoint or credential was read or copied. Until that authority exists, a
new APK could show only the truthful provider-unavailable state; using fixture
videos or hard-coded IDs to demonstrate the player on OPPO would violate this
ticket. Therefore no successor device candidate was registered, no APK host
qualification was opened, and r60.28 remains installed for protection.
