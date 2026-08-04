# Buy FV2 R58.1 product-detail continuous-discovery handoff

Date: 3 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED; FOUNDER REVIEW PENDING**

## Qualified outcome

R58.1 removes the founder-reported product-detail dead end without reopening
approved R54/R55 navigation. After description, reviews and issue reporting, a
truthful current-catalogue lane lets a customer open another product directly,
then another, without using Back between products. One Back after the chain
returns to the original Shop, Wholesale or Medicine catalogue owner.

Selection is local and deterministic: same category is scored before same
brand, followed by stable price and product-ID ordering. The current product is
excluded. The selector does not consume Cart/history/profile/popularity,
network, provider, clinical or personalization signals.

Copy remains vertical-safe:

- Shop: `You may also like` / `More from the current Shop catalogue`;
- Wholesale: `More for business restocking` / current trade packs only; and
- Medicine: `More Medicine essentials` / `not medical advice`.

The horizontal lane is deliberate and non-autonomous. Cards have stable
geometry and one native semantic/click owner. A finite product-keyed reveal
uses the approved motion system; reduced motion renders the final state
immediately. R43, R45-R48, R52.1, R53, R54 and R55 behavior remains protected.

## Exact qualified identity

- Candidate: `BUY-R58-PRODUCT-DETAIL-CONTINUOUS-DISCOVERY-FIX1`
- Profile: `1.0.0-r58` (`2026080314`)
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,416 app/test files, SHA-256
  `07AFF6B40C9F020CAEC2322C1D6BC4F0E18FEA81369F2B6B4F38DAD3F81AE745`
- APK/install: 134,017,349 bytes, SHA-256
  `5D666CD05C711BFFD1E5A33759247952ECE5754F6B443F1C8EDAB2F9ED9EA68D`
- Device: OPPO CPH2375, serial `2b3e0f71`

Pre-build, post-build and post-device source manifests match exactly. The OPPO
installed package reports the exact version/code and the pulled base APK is
checksum-identical to the wrapper-produced archive.

## Qualification result

Full analysis is clean. The focused suite passes 38/38. Two complete
unchanged-source Buy regressions each pass 295 active tests with the same 15
established intentional skips. Every positive release gate passes; the three
protected gates reach their exact expected fail-closed outcomes and no
protected baseline was replaced.

Connected-device proof covers Shop two-hop continuation, Wholesale and
Medicine continuation, current-product exclusion, original return depth,
native `clickable=true` accessibility nodes, hot resume, approved force-stop
restoration and a zero-app-failure scan. The warmed 72-frame trace has p95
26.121 ms, one frame over 33 ms, no frame over 100 ms and no shader/compile
event.

## Founder review points

On the installed OPPO, review:

1. Shop -> Fresh tomatoes -> detail bottom -> `You may also like`.
2. Tap Fresh red onions, then Fresh tomatoes, without Back.
3. Press Back once and confirm the original Shop root.
4. Review the Wholesale business-restocking lane and Medicine
   `not medical advice` lane.
5. Confirm the lane style, density, finite arrival motion and static
   reduced-motion result.

## Boundaries and next queue

This is technical/device qualification, not founder approval. It neither
approves nor implements the remaining navigation families. R58.2 category and
result continuation is the next registered logical audit. R58.3-R58.8 remain
queued separately. Real asynchronous pagination/loading (`080`/`098`) and
video/campaign effects (`082`/`083`/`140`) remain dependency-held.

Evidence owner:
`artifacts/quality/buy-product-detail-continuous-discovery-r58-1-20260803-124`.

Program matrix:
`docs/quality/BUY-R58-CONTINUOUS-NAVIGATION-TICKET-MATRIX-20260803.md`.
