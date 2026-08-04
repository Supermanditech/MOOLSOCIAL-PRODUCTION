# BUY-FV2-084 R38 profile qualification handoff

Date: 31 July 2026

State: `COMPLETE_PROFILE_HARDWARE_QUALIFIED`

## Authority and protected boundary

This qualification continued from the founder-approved R38 native Buy
baseline. The protected Buy tree remains 31 files at
`363ebe4c7342ba0118f9a7108e83fa8c2b0b3ded23332c7dd42a32849f9a5cd7`.
The protected Social tree remains
`54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.
No approved R38 layout, copy, route, Cart/offers/Saved behaviour, branding,
colour or static Flutter UI changed.

## Exact qualified candidate

- Candidate: `BUY-R38-084-PROFILE-QUALIFICATION-FIX1`
- Mode: Flutter profile
- Version: `1.0.0-r38.2`
- Version code: `2026073153`
- Device: OPPO CPH2375, serial `2b3e0f71`, Android 13 / API 33
- Final app/test source fingerprint:
  `57AC2C12E1D5870EE19EBBCAAFA3936BD5A74C1F9D1373C685C57B88F86E8EB0`
- APK bytes: `132870329`
- APK SHA-256:
  `4F264F86C8C25431F760978D88E7EEEEBA2B1F2C976A4574819F4595F5FE83E0`

The build output, device-installed APK and pulled APK match exactly. After an
approved-lock gate caught a qualification-test edit in a hash-locked file, the
file was restored to its approved hash and the assertion moved to additive
evidence. A rebuild from the corrected final source produced the same APK size
and SHA-256, proving the installed runtime remained exact.

## Proven defect and bounded fix

The initial profile candidate crashed after backgrounding in Orders/tracking.
Two fatal Firebase Performance worker exceptions showed
`FirebaseInstallations` rejecting the local placeholder API key. Debug review
builds already disabled Google-hosted collection, but the profile manifest did
not.

The correction changes only
`apps/mobile/android/app/src/profile/AndroidManifest.xml`: it mirrors the
debug review overlay's cleartext allowance and fail-closed Firebase analytics,
Crashlytics, messaging auto-init and performance collection flags. The main
and release manifests are unchanged. No protected Buy file changed. The
additive profile-overlay test and existing approved platform suite both pass.

## Performance result

| Measure | Registered gate | Result | State |
| --- | ---: | ---: | --- |
| Warm Flutter build p90 | <= 16.667 ms | 6.856 ms | Pass |
| Warm scoped raster p90 | <= 16.667 ms | 0.416 ms | Pass |
| Warm presentation-inclusive p95 | <= 33 ms | 19.969 ms | Pass |
| Warm frames above 33 ms | <= 5% | 7/673, 1.04% | Pass |
| Warm frames above 100 ms | 0 unexplained | 0 | Pass |
| Warm maximum | < 100 ms | 84.548 ms | Pass |
| Five cold-start median | <= 2,000 ms | 1,752 ms | Pass |
| Three warm-resume median | <= 750 ms | 146 ms | Pass |
| Total PSS after two loops | <= 350 MiB | 247,628 KiB | Pass |
| PSS growth | <= 20% | 14.224% | Pass |
| Profile APK | <= 210,244,314 bytes | 132,870,329 bytes | Pass |

`Frame`/Flutter build and `CompositorContext::ScopedFrame::Raster` are the
registered CPU build and raster-stage measures. The broader
`Rasterizer::DoDraw` p90 is retained separately at 17.131 ms because it also
includes encode, submit and GPU-fence/presentation work; it is not relabelled
or discarded. The presentation-inclusive p95 uses the worse top-level UI or
submit-inclusive raster duration for every joined frame.

First-interaction evidence contains 555 frames: build p90 7.892 ms, scoped
raster p90 0.408 ms, presentation p95 22.492 ms, seven frames over 33 ms
(1.261%), zero over 100 ms and maximum 95.454 ms. Both first and warm traces
contain zero explicit shader/compile events. Warm maximum improves to
84.548 ms.

The seven warm slow frames are bounded transition-owned UI build work. Four
begin 13.35–89.58 ms after pointer input; the other three occur at the later
scripted route/state action point in their trace. Six have a following
observed frame and all six recover below 33 ms immediately except the known
two-frame Wholesale/Medicine transition cluster, whose following frame is
21.229 ms; the seventh is the final recorded transition frame. Scoped raster
never exceeds 0.934 ms, no shader/compile event appears and no frame exceeds
100 ms. This is an explained, non-sustained transition cost, not an unresolved
runtime-jank failure. ADB `gfxinfo` exposed only two host-window frames and is
preserved as inadequate/automation-contaminated rather than used for closure.

## Lifecycle and resource result

- Cold starts: 1746, 1841, 1799, 1752 and 1728 ms.
- Same-process warm resumes: 181, 146 and 133 ms.
- Two representative journey loops cover Shop, Wholesale, Medicine, aggregate
  Cart, Saved, Coupons/Offers, Orders/tracking and forward/back navigation.
- PSS: 216,791 KiB before and 247,628 KiB after, 14.224% growth.
- Exact app UID network delta: RX 0 bytes, TX 0 bytes.
- Thermal status: 0 before and after.
- Battery: 100% before and after while USB powered; this is a bounded device
  observation, not a fleet battery claim.
- No corrected-candidate fatal, ANR, Flutter error or RenderFlex signature.
- Process recreation honestly resets backend-blocked ephemeral Cart/Saved
  state; no server persistence is invented.

## Reduced motion and regression result

Normal tokens remain press 110 ms, selection 150 ms, state 180 ms, content
240 ms, expand 260 ms, route 280 ms, recovery 220 ms, success 360 ms and brand
420 ms. Every token resolves to `Duration.zero` under
`MediaQuery.disableAnimations`. Static brand/progress treatment, navigation
and semantics remain available.

- Additive profile-overlay proof: 1/1.
- Additive reduced-motion token proof: 1/1.
- Existing focused motion/screen suite: 69/69.
- Full Flutter analysis: no issues.
- Complete Buy regression 1: 167/167; four opt-in capture generators skipped.
- Complete Buy regression 2: 167/167; the same four generators skipped.
- Exact source manifest matches before and after both final regressions.
- Approved UI locks, brand, founder Buy reference, interaction, customer copy,
  screenbook HTML copy, backend boundary/self-test, data-egress/self-test,
  protected Social and protected Buy gates all pass.

## Durable evidence and remaining boundaries

Evidence is additive under
`artifacts/quality/buy-fv2-084-profile-qualification-oppo-20260731-43`.
Earlier R36/R37/R38 evidence is unchanged.

`BUY-FV2-084` is complete. `BUY-FV2-085` remains open for founder combined
visual acceptance. No new protected Buy baseline, backend connection, tip
policy, cross-relaunch persistence, paid advertising, inline video, commit,
push, deployment or publication is authorized by this handoff.
