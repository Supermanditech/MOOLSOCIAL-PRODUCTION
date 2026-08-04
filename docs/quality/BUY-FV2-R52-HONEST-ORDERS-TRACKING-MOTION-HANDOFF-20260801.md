# BUY-FV2 R52 honest Orders/tracking motion handoff — 1 August 2026

## Current state

**R52.1 TECHNICALLY/DEVICE QUALIFIED AND FOUNDER APPROVED ON THE CUMULATIVE
R55.4 OPPO BINARY — 2 AUGUST 2026**.

The qualified successor is `BUY-R52-ORDERS-TRACKING-MOTION-FIX2`, profile
`1.0.0-r52.1` (`2026080204`), APK/install SHA-256
`A3101715DE27F828F02EAB2F7F674EEB99F64CFC674A2560A08A5208E02AEEF0`.
Its immutable qualification evidence is
`artifacts/quality/buy-orders-tracking-motion-r52-1-20260802-79`. Founder
disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

The source-only R52 FIX1 history follows.

R52 deduplicates the uncovered Orders/tracking owner across `BUY-FV2-076`,
`BUY-FV2-079` and the completed test-only integrity owner `BUY-FV2-115`.
Candidate identity is `BUY-R52-ORDERS-TRACKING-MOTION-FIX1`, planned profile
`1.0.0-r52` (`2026080128`). Evidence is retained in
`artifacts/quality/buy-orders-tracking-motion-r52-20260801-72`.

The prewrite snapshot is branch
`remediation/prototype-conformance-2026-07-20`, HEAD
`f1ac83dea2047f40b39d772696bd0d1224edce8e`, 2,224 app/test source files and
source-manifest SHA-256
`6AE96E45C10A6A89A6EE79B67F42BE43CB83A59F4D631BA12561A21A1426AECF`.
All existing dirty and untracked work is preserved.

## Contracted correction

The existing progress bars replay from zero whenever Orders or Tracking mounts,
and the tracking header claims `LIVE` without a proven live-provider adapter.
R52 will render current progress immediately on first paint and animate only a
later real update for the same order. Tab, timeline and alert motion will remain
finite, state-owned and reduced-motion safe. No timer, pulse, location, provider
event, promise or backend state may be invented.

A post-edit scoped replay audit found the identical zero-to-current builder in
the Buy Assist current-order card. R52's contract was extended before touching
that call site so the same truthful primitive is used there without changing
Assist layout, copy, actions or intent.

Full pre-implementation contract:
`artifacts/quality/buy-orders-tracking-motion-r52-20260801-72/00-r52-honest-orders-tracking-motion-contract.md`.

## Protected predecessor

R51 FIX10 remains unchanged and founder-review pending on the connected OPPO:

- candidate `BUY-R51-077-CONTEXTUAL-GLASS-HEADER-FIX10`;
- profile `1.0.0-r51.9` (`2026080127`);
- APK/install SHA-256
  `22846F9ABD60D2F99A04B8D3A432F529B96F4602451610120E5722C1A3CD0BCE`.

R52 has not changed the APK regression machine state, built an APK, or altered
the device. The founder's FIX10 visual decision must be recorded independently
when supplied.

## Source implementation and verification result

The three zero-to-current Orders/Tracking progress builders and the identical
Buy Assist current-order builder now use one truthful fixed-owner progress
primitive. First paint is exact current state; a later same-order real change
may transition once; owner replacement and reduced motion snap immediately.
The unproven `LIVE` pulse is removed in favor of static `CURRENT`, and the local
preference copy is limited to `Order alerts are on/paused`. Active/Delivered
tab and same-order timeline changes receive finite state-owned treatment.

Verification passes:

- focused honest-order/motion/session set: `35/35`;
- final complete Buy-screen set: `69/69`;
- two independent unchanged-source Buy regressions: `181/181` each with four
  intentional opt-in capture skips;
- full Flutter analysis: no issues;
- 320/140-percent text, brand, immutable Buy reference, interaction, rendered
  copy, nine-state HTML copy, backend/self-test and data-egress/self-test gates;
- `git diff --check` and source no-drift seal.

Final prebuild source identity is 2,225 files, SHA-256
`14828310D032659A10850CD8395A7FBBCA3D1528B511246397F0B17D3E0EDEF6`.
Summary:
`artifacts/quality/buy-orders-tracking-motion-r52-20260801-72/09-source-qualification-summary.md`.

At this source-only FIX1 checkpoint, R52 was neither APK/device qualified nor
founder accepted. The later R52.1 FIX2 completed every listed gate and is the
founder-approved object recorded at the top of this handoff.
