# FSC02B native YouTube Videos preselection

- Ticket: `MOOLSOCIAL-FSC02B-NATIVE-YOUTUBE-VIDEOS-DISCOVERY-WATCH`
- Founder direction: on 2026-08-10 the founder stopped HTML work, authorized direct Flutter implementation and asked that the Social micro-tickets proceed sequentially toward OPPO review.
- Classification: `mvp_required`
- Customer outcome: a Personal user discovers only real eligible public YouTube videos and opens one official watch surface with supported provider metadata, native Back restoration and truthful loading, empty, unavailable, error and retry behavior.

## Reuse and duplicate assessment

The required owners already exist:

- `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`;
- `apps/mobile/lib/ui_v2/social/social_v2_youtube_public_runtime.dart`;
- `apps/mobile/lib/core/youtube/youtube_private_dev_client.dart`;
- `apps/mobile/lib/core/youtube/youtube_embedded_player_android.dart`;
- `apps/mobile/lib/core/youtube/youtube_embedded_player_contract.dart`;
- the current Screen 04 discovery, watch, metadata-sheet and navigation tests.

No new screen, route, backend, API client, player or OAuth owner is needed. The
current public runtime already positively admits public, processed, embeddable,
region-available provider records. The defect is that the normal build falls
back to `_videoCatalog`, a hard-coded provider-like catalogue, and the named
watch state can resolve that catalogue before any provider response.

## Smallest complete native scope

1. Make Videos provider-owned only and remove `_videoCatalog` plus every fixture-derived discovery or watch path.
2. Reuse the real provider loader and one official active player.
3. Preserve native discovery-to-watch and Back restoration with supported current provider metadata.
4. Add professional provider-access, loading, empty, unavailable, transport-error and retry states.
5. Keep Save, Discuss and Share visibly MoolSocial-owned; do not add Like, Comment, Subscribe, upload or other provider-write actions.
6. Preserve the Mool switcher, accepted global navigation, one-tap Social destinations, 44-by-44 targets and compact-phone fitment.
7. Add focused source, widget, fitment, copy and navigation tests before any APK work.

## Exclusions and gates

- No fabricated video, channel, thumbnail, metric, recommendation or engagement fallback.
- No personalized YouTube Home claim, pixel clone, OAuth, upload `+`, provider Like, Comment or Subscribe.
- No Feed, Create or Shorts redesign in this ticket.
- No new route, screen, backend, client or player owner.
- No credential access/copy, Firebase or external-service write, Production write, commit, push, deploy or promotion.
- Runtime availability still requires the authorized private-Dev Firebase/App Check provider boundary and `capabilities.publicData=true`.
- No APK candidate, build or OPPO mutation may occur until provider authority exists and a fresh successor host qualification passes.
- Connected OPPO r60.28 and all C28D/C28F evidence remain protected.

## Native implementation result

The bounded Flutter source correction is complete:

- Videos no longer resolves `_videoCatalog`, fixture discovery records or a
  fixture named-watch state;
- discovery and watch use only positively admitted records returned by the real
  public provider loader;
- provider access, loading, eligible-empty, unavailable, transport-error and
  retry states are distinct and customer-readable;
- a provider thumbnail failure renders a neutral unavailable treatment, never a
  MoolSocial grocery or other fabricated media fallback;
- Save, Discuss, Share and details remain explicitly MoolSocial-owned and are
  not presented as YouTube Like, Comment, Subscribe or upload actions;
- native Back returns from the active provider watch to the exact discovery
  position, including at 320x568 and 140% text;
- the Mool switcher, accepted global navigation, one-tap Social destinations
  and minimum 44-by-44 action targets remain intact.

Focused verification passed on 2026-08-10: Flutter analysis reported no issues
for the changed runtime and test owners, and 76 tests across six current Social
files passed. The previously selected C03 predecessor suite was restored
untouched and excluded because it asserts navigation keys that predate the
accepted C28F owner; that selection failure is retained in the permanent
regression registry.

## Exact APK and OPPO gate

No Videos APK candidate is truthful yet. Provider availability requires all of:

- `MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF=true`;
- `MOOLSOCIAL_USE_EMULATORS=false`;
- Firebase project `moolsocial-dev-503018`;
- an authorized valid `MOOLSOCIAL_YOUTUBE_PROVIDER_URL`;
- accepted Firebase Auth identity and Play Integrity App Check;
- provider response `capabilities.publicData=true`.

There is also a separate Android player packaging boundary: the current
embedded-player contract and Android adapter require `kDebugMode`, while the
selected Android build configuration is `profile`. The profile path therefore
cannot be claimed to host the official player until a separately authorized
shared-system ticket qualifies secure private-Dev player packaging and plugin
registration for that build mode, or qualifies a debug-only proof candidate.

Until both boundaries and a fresh APK host qualification pass, there will be no
build, candidate registration or OPPO install. The connected CPH2375
(`2b3e0f71`) remains on protected r60.28/versionCode 2026081028 with no install,
uninstall, data clear or downgrade performed.
