# UAW C30T r60.45 YouTube player full-screen control nonfunctional — 13 August 2026

The founder played a real public YouTube video inside the Play-installed `1.0.0-r60.45 (2026081345)` MoolSocial app. Inline playback worked, but tapping the player expand/full-screen control did not enter full-screen.

This is an MVP-required YouTube player and reviewer-acceptance blocker. The successor must trace the existing closed player bridge and Android host lifecycle, enter full-screen only from an explicit user tap, preserve the exact video/playback context, return inline through system Back, retain attribution and the single-player lease, and pass future Play-installed device acceptance.

No custom playback, download, attribution bypass, new YouTube scope, secret access, AAB, upload, install or external write is authorized by this ticket registration.

## Pre-selection robustness and reuse assessment

- Customer outcome: an explicit tap on the official YouTube player's full-screen control enters provider full-screen and Android Back returns to the same inline video and playback context.
- Duplicate/reuse inventory: the existing closed Android `WebView` platform view, `WebChromeClient`, Flutter embedded-player adapter/controller, single-player lease and Social watch surface already own the complete playback journey. No duplicate player, screen, route, service or backend owner is needed.
- Implementation disposition: reuse the existing native platform view and test owners; add the smallest full-screen lifecycle handling inside the closed Android adapter.
- Necessity proof: the existing `ProviderWebChromeClient` denies permissions correctly but implements neither `onShowCustomView` nor `onHideCustomView`, so the provider's user-tapped HTML5 full-screen request has no native host. A bounded custom-view host tied to the existing player lifecycle is the smallest complete repair.
- Robustness coverage: explicit user-tap-only provider request; exact video/playback continuity; Android Back and provider exit; orientation and system-bar restoration; disposal/render-process failure cleanup; single-player lease retention; no external navigation or autoplay expansion.
- Explicit exclusions: no custom playback, download, provider-interface copy, attribution bypass, new screen/route/backend, scope expansion, MainActivity redesign, account/secret access, build, AAB, upload, install or external write.
- Dependencies and approvals: founder source-implementation authority; current closed player and r60.45 evidence preserved; future separately authorized Play candidate required for live full-screen acceptance.
- Test plan: native source contract for paired show/hide and cleanup; Flutter Android adapter regression; controller/lease/lifecycle tests; authoritative focused Social manifest; analyzer and Android dependency checks.
- Timeline impact: one source day, within the locked 60–75 day delivery window.

The Back-navigation predecessor is source-qualified and retained. This ticket is now selected alone for source implementation with all build, device-install and external-write authority false.

## Source implementation and non-build qualification

The root cause is confirmed: the approved provider bootstrap already exposes `fs: 1`, and the founder could tap the provider control, but the closed Android adapter's `ProviderWebChromeClient` implemented neither `onShowCustomView` nor `onHideCustomView`. Android therefore reported no native full-screen host to the provider.

The existing adapter now pairs both current and legacy `onShowCustomView` entry points with one provider-owned custom-view host. The host is a black, full-window, immersive Android dialog created only in response to the provider callback. Android Back cancels that dialog, provider exit hides it, and detach, render-process failure and disposal all run the same idempotent cleanup. The exact prior requested orientation and inline root visibility are restored, the provider callback is completed once, and the existing WebView, playback session and single-player lease remain the owners. `MainActivity`, Flutter routes/screens, backend and provider configuration are unchanged.

Qualification completed without an APK/AAB build, upload, install, device mutation or external write:

- Focused Android player, bridge, controller and public-runtime partition: 48 passed.
- Authoritative C30T 59-file Social manifest: 380 passed with 3 declared skips.
- Dart formatting: 498 files checked, 0 changed.
- `flutter analyze`: no issues found.
- Backend verification: 505 passed, 0 failed.
- Firebase Hosting/App Links static verification: 7 passed, 0 failed.
- YouTube deployment-control suite: all local contracts passed with the exact `No cloud command was performed.` marker.
- Release dependency graph: `BUILD SUCCESSFUL`; no APK/AAB task was invoked.
- Release generated-plugin registrant restored: 16 allowed release plugins; development integration-test registration absent.

The source state is therefore `source_implemented_and_non_build_qualified_live_Play_acceptance_pending`. A future separately authorized Play candidate must still prove real user-tapped inline-to-full-screen-to-inline continuity, Android Back, rotation, app interruption, retained playback context and single-player behavior on OPPO. This result is not a live full-screen success claim and does not authorize or justify an AAB.
