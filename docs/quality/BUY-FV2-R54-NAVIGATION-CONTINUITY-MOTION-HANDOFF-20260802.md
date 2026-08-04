# BUY-FV2 R54 navigation-continuity motion handoff

Date: 2 August 2026

State: **R54.1 MOTION AND CURRENT R55.4 ROOT-EXIT OUTCOME FOUNDER APPROVED —
2 AUGUST 2026**

Tickets: existing `BUY-FV2-138`, `BUY-FV2-076`, `BUY-FV2-017`.

Current candidate: `BUY-R54-NAVIGATION-CONTINUITY-MOTION-FIX2`, profile
`1.0.0-r54.1` (`2026080207`).

The final route/restoration successor is
`BUY-R55-NAVIGATION-ROOT-EXIT-AND-PRODUCT-CONTINUITY-FIX5`, profile
`1.0.0-r55.4` (`2026080212`), APK/install SHA-256
`DB5A4F687CFB0352B6940ECD473D5637205A601689FF6A4A317C6E18D49D548D`.
The founder confirmed its corrected Buy-root Back outcome and reaffirmed R54.1.
Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

## Founder authority

The founder authorized the prepared motion tickets for implementation one by
one and will review qualified visuals together. R54 is the first unblocked
prepared owner. R55 product continuity and R56 transient surfaces remain
separate and are not part of this candidate.

## Exact predecessor

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- R53 source manifest: 2,306 files, SHA-256
  `7515088ED6D5F0FC66B61645EDA147C50C082C971753164C26DB2AD70A8F8C0C`
- R53 APK and pulled OPPO install SHA-256:
  `6C1743A9C43468B6CF4BD40D0ED648D2A4B61D95A491838C5606B2DC1F221B80`
- R53 machine state SHA-256 before R54:
  `CC63BCB0A8D264FD8E305D658D861AA9B66E20C81ED11821D9ACCC9245818C35`

## Runtime contract

The current fixed Buy body briefly replaces real content with a boxed selected
placeholder across two post-frame phases. R54 removes that interstitial. One
fixed body owner presents the real current `BuyV2View` immediately and applies
a finite shared-axis fade/translation for an existing forward/back event, or a
shallower fade for an existing same-level replacement.

The session may expose a monotonic presentation event and direction. These are
observations only: they cannot choose a route, create stack entries, defer a
callback, announce loading, persist, restore or mutate commerce state. Repeated
selection of the already-current destination cannot replay motion.

Only the newest incoming surface is retained and it owns pointer events and
semantics throughout. An early retained-outgoing prototype proved unsafe
because every Buy view reads the same mutable session: after Orders replaced a
catalogue, an outgoing catalogue could rebuild against Orders state. That
prototype was rejected before qualification. Incoming-only motion eliminates
the stale-tree, duplicate-semantics and duplicate-raster risks. Rapid
replacement cancels the superseded visual and settles to the newest genuine
view. Unrelated notice, Saved, quantity, Cart arithmetic and lifecycle
notifications cannot replay navigation motion.

## Protected boundary

R54 cannot move or alter the accepted header, Search, mini-Cart or dock. It
cannot change R49.1 root Back, internal Back, deliberate Social departure,
one-action Buy rediscovery, invalid-route fallback, restored destination,
focus/keyboard ownership, route literals, deep links, persistence, copy,
product/Cart/order rules, backend state, Screen 01 or protected Social.

## Reduced motion

`MediaQuery.disableAnimations` resolves to an immediate final view with the
same route, focus, semantics, stack and restoration outcome. No hidden ticker,
outgoing semantic copy, intermediate placeholder or delayed action remains.

## Risks and required evidence

Primary risks are duplicate semantics, stale hit testing, Back-direction
inversion, lifecycle replay, rapid-replacement residue, large-view raster cost,
keyboard/focus loss and accidental route/persistence drift.

Qualification requires focused forward/back/replace/interrupt/reduced-motion
tests; Android and iOS-size captures including 320 px at 140-percent text; OPPO
root/internal Back, Search-first, Social departure/return, lifecycle and process
restoration replay; accessibility tree and failure scan; affected profile
trace; two complete unchanged-source Buy regressions; every mandatory lock,
reference, brand, copy, HTML-copy, backend, data-egress and Social gate; and
source-manifest equality before build and after device replay.

Founder visual approval remains distinct from technical/device qualification.
No commit, push, deploy, publish, merge, branch switch or protected-baseline
replacement is authorized.

## FIX1 rejection and FIX2

FIX1 profile `1.0.0-r54` (`2026080206`) built and installed checksum-exact at
SHA-256
`D3719EBD2FFEADF9DBDBF648F1F2103FE3B5879A3E3E2011E7B1FD9AC8DCB842`.
It is rejected before visual review because an invalid/unavailable Checkout
attempt could emit a forward presentation event despite remaining on the same
Cart surface. That violates the contract above.

FIX2 `BUY-R54-NAVIGATION-CONTINUITY-MOTION-FIX2`, planned profile
`1.0.0-r54.1` (`2026080207`), adds a structural session surface identity:
destination, view and the existing selected product/order/recovery owner where
applicable. A navigation sequence advances only when that identity changes.
Notices, invalid actions, Cart arithmetic, repeated selection and other
same-surface notifications cannot replay the body motion. Visual geometry,
timing, semantics, routes and commerce outcomes remain FIX1-exact.

## FIX2 build/install checkpoint

- Full Flutter analysis: clean.
- Expanded FIX2 focused suite: 123/123 passed.
- Two complete unchanged-source Buy regressions: 189 passed plus the same four
  established capture-only skips in each run.
- All positive gates pass. Protected Screen 01 and Social remain exact to the
  predecessor; Buy reaches only the expected authorized fail-closed drift.
- Accepted Search plus mini-Cart remains exact at 16,182 bytes and SHA-256
  `E99C6F35FF40611759465D1AE3D4648382F651C04C57B65009213A56B72744CB`.
- Sealed prebuild and post-build source: 2,307 files, SHA-256
  `5661D4E42E3B51E11AC14F1F4ED03A5F4337D846E7A83E316AB642E8D7B27414`.
- Machine-gated profile APK: 133,591,225 bytes, 709 ZIP entries, APK Signature
  Scheme v2, SHA-256
  `44A6468D02820758B26118659050D3E4D6ABF1E3216FB8142DC013B9EFE33CB1`.
- OPPO CPH2375 (`2b3e0f71`) reports `1.0.0-r54.1` / `2026080207`; its pulled
  installed `base.apk` is byte-exact to the archived APK at the same SHA-256.
- After founder unlock, device navigation/accessibility, root-Back/Social
  continuity, lifecycle, established force-stop restoration, failure scan and
  profile-performance gates all pass on the exact installed APK.
- Root Back lands on Social with Buy visible; one tap returns to Buy. Search
  Back dismisses keyboard, then collapses Search, while staying in Buy.
- Hot resume and force-stop/MainActivity cold restoration retain Medicine.
- Profile trace: 88 joined frames, p95 20.085 ms, one frame over 33 ms, none
  over 100 ms, maximum 43.259 ms and zero shader/compile events.
- Final current-process failure scan: zero matches.
- Post-device source remains exact at the sealed 2,307-file SHA-256.
- Continuous MP4 capture is unavailable because OPPO lacks `screenrecord` and
  scrcpy's Windows recorder crashes after connecting. Real OPPO intermediate/
  settled PNG and accessibility evidence is complete; no synthetic reel is
  represented as runtime video.
- Qualification summary:
  `artifacts/quality/buy-navigation-continuity-motion-r54-1-20260802-82/80-technical-device-qualification-summary.md`.
  No further R54 build is authorized or needed.

## Founder approval and R54.3 root-exit correction

The founder approved R54 motion and every other reviewed item, then reported
that Android Back from the Buy Shop root reached Eat. The successor stayed
inside `BUY-FV2-138`, `076` and `017`.

FIX3 failed the exact Eat-invoker replay because Social-shell Eat state remained
beneath a pushed Buy route. FIX4 replaced the route and passed the root exit,
but failed the mandatory Medicine process-restoration gate. Final FIX5 also
route-addresses catalogue vertical selection.

Exact installed FIX5 is `1.0.0-r55.4` (`2026080212`) with APK/install SHA-256
`DB5A4F687CFB0352B6940ECD473D5637205A601689FF6A4A317C6E18D49D548D`.
Eat -> Buy -> one Android Back now lands canonical Social, the Mool choices are
open and Buy is one tap away; a repeated cycle passes. The founder subsequently
confirmed this corrected result and reaffirmed R54.1. Evidence:
`artifacts/quality/buy-navigation-root-exit-r54-4-r55-4-20260802-87`.
