# UAW C30T r60.45 YouTube Shorts top-inset collision — 13 August 2026

## Release result

The Google Play Internal installed `1.0.0-r60.45 (2026081345)` successfully loaded real YouTube Shorts content on OPPO CPH2375, but the screen is not release-qualified. The MoolSocial title/channel layer intersects the Android status-bar region and visibly collides with the clock and system status icons.

## Exact evidence

- Screenshot: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/20-youtube-shorts-live.png`
- Screenshot SHA-256: `DDE9828749C044F60473350E26E08D347B390624633EB0627DB160EF41BC6BE8`
- Stable hierarchy: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/20-youtube-shorts-live.xml`
- Device: OPPO CPH2375, serial `2b3e0f71`, physical `720x1612`, density `320 dpi`

Real catalogue loading and the provider-owned video surface passed. The top-inset collision is the blocker.

## Successor boundary

A successor must diagnose the exact header/inset owner, keep all MoolSocial title and channel content below the effective Android top inset, preserve the official provider player boundary, and add a current-owner regression at the exact OPPO geometry. The complete Home/search/video/player/Shorts/return journey must then be replayed.

No second C30T AAB, upload or install is authorized. No source, provider, Hosting, Play or communication mutation accompanies this finding.

## Preselection assessment

- Customer outcome: at the exact OPPO 720×1612, 320 dpi geometry, provider title and channel controls remain entirely below Android status content while Shorts playback and the MoolSocial bottom rail remain usable.
- Classification: `mvp_required`. The collision obscures provider-owned identity and controls on a core live YouTube reviewer journey.
- Reuse: the current Shorts `PageView` is the only provider-stage owner; the outer screen already owns the transparent status-bar style; the accepted C29E Android test already owns current view-padding and provider-stage geometry.
- Necessity proof: `SocialUniversalV2` deliberately disables the outer top `SafeArea` for Shorts so its black background can remain edge-to-edge, but `_buildShorts` places the provider `PageView` at logical y=0. The provider then renders its own title/channel controls through the system status region. Insetting only the page viewport is the smallest complete correction.
- Minimum implementation: retain the edge-to-edge black background and transparent status bar; pad the Shorts page and refresh notice by the current effective `MediaQuery.viewPadding.top`; keep the provider stage exactly equal to that inset page viewport.
- New screens, routes, players and backend owners: none.
- Exclusions: no custom YouTube controls, provider-interface copy, attribution change, backend/provider/Hosting/Play/device write, build, AAB, upload or install.
- Dependencies: the current official embedded-player boundary, single-player lease and bottom exported-semantics clearance remain unchanged; live proof requires a future separately authorized Play candidate.
- Test plan: update the accepted Android Shorts geometry contract, add the exact OPPO physical size/density/inset case in the same current owner, and run the authoritative Social/YouTube manifest plus analyzer and non-build gates.

The founder authorized continued implementation of registered production-grade defects while explicitly withholding every successor AAB, upload and install authority. This ticket is selected only for source and non-build qualification.

## Source implementation and non-build qualification

The root cause is confirmed in the current owner: Shorts intentionally disables
the outer top `SafeArea` so the app's black background can remain edge-to-edge
behind a transparent Android status bar, but its provider `PageView` also began
at logical y=0. The official embedded player therefore placed provider title
and channel controls under the system clock and status icons.

The existing Shorts stack now reads the current `MediaQuery.viewPadding.top`
and applies it only to the provider `PageView`. The surrounding black background
still fills the status region, the transparent status-bar style is unchanged,
the provider stage still exactly equals its page viewport, and the existing
bottom navigation/exported-semantics clearance is unchanged. The same inset is
applied to the optional refresh notice. No fixed device constant, local metadata
overlay, custom player or provider-interface copy was added.

Qualification completed without an APK/AAB build, upload, install, OPPO action,
provider deployment, Hosting deployment or external write:

- Exact OPPO geometry plus Screen 04 matrix: 31 passed.
- Exact retained geometry: 720×1612 physical pixels, 2× density, 48 physical
  top-inset pixels = 24 logical pixels; provider page/stage top = 24 logical.
- Authoritative C30T 59-file Social/YouTube/Chat/navigation manifest: 371 passed
  with 3 declared skips.
- Dart format audit: 474 owned `lib` and `test` files checked, 0 changed.
- `flutter analyze`: no issues found.
- Backend 505/505, Hosting 7/7, local YouTube deployment controls and Android
  release dependency graph remain passed from the immediately preceding
  unchanged non-UI qualification; the last control marker was
  `No cloud command was performed.` and the dependency result was
  `BUILD SUCCESSFUL`.

The ticket state is
`source_implemented_and_non_build_qualified_live_Play_acceptance_pending`.
The installed r60.45 still contains the collision. A future separately
authorized Play candidate must prove the live Shorts title/channel/status-bar
geometry and full Home/search/video/player/Shorts/return journey on OPPO. This
is not live acceptance and does not authorize an AAB.
