# Buy FV2 R58.5.1 Medicine prescription-match continuity handoff

Date: 3 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED; FOUNDER REVIEW PENDING**

Candidate: `BUY-R58-MEDICINE-PRESCRIPTION-MATCH-CONTINUITY-FIX1`

Profile: `1.0.0-r58.5` (`2026080318`)

## Exact identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,420 files, SHA-256
  `31FAA75DB70CEF0385FC547896AD5CFBDC19EA830DE40A71581F7C41B4016078`
- Wrapper-produced and pulled-installed APK: 134,033,889 bytes, SHA-256
  `EEB613C2619F73240D66EBEE3F5CA6FFE1C4C1F1EAA94F82831F154DB7257163`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Immutable evidence:
  `artifacts/quality/buy-medicine-continuation-r58-5-audit-20260803-128`

## Defect and bounded fix

The established prescription sheet recorded real matched product IDs but a
saved prescription exposed them only through a non-clickable 2.6-second notice.
After expiry the Medicine root had no exact matched-medicine continuation
owner.

The qualified fix exposes one read-only session getter and one stable native
Medicine-root lane containing only products already present in the real
prescription match state. Each item opens the existing product detail and
reuses R54/R55/R58.1 navigation. The lane uses finite intent-depth arrival,
settles immediately under reduced motion and retains pharmacist review plus
`Not medical advice`.

Exact runtime/test files:

- `apps/mobile/lib/features/buy/buy_v2_session.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_prescription_match_continuity_test.dart`

## Qualification result

Host qualification passed clean analysis, four corrected focused tests,
48 active related tests plus one established skip, two complete Buy regressions
at 308 active passes plus 15 established skips each, responsive/reduced-motion
captures, all positive release gates and exact protected-boundary fail-closed
classification.

On the checksum-matched OPPO install:

- Dr Meera exposed exactly Telmisartan and Atorvastatin, never Metformin;
- both matches were native focusable/clickable product buttons with safety
  semantics;
- hot resume retained exact actions and geometry;
- Telmisartan -> Atorvastatin continued without a grid Back, then one Android
  Back restored the original Medicine match lane;
- the pending Telmisartan prescription flow stayed on the exact product,
  changed only the real quantity and restored the exact query on Back;
- process recreation exposed no invented match state;
- the accepted 90-frame trace has p95 18.313 ms, zero frames over 33 or 100 ms
  and zero shader/compile events;
- classified MoolSocial failures are zero;
- post-device source remains exact.

## Founder review points

1. Open Medicine -> Prescription centre -> Dr Meera Sharma. Confirm the stable
   lane contains only Telmisartan and Atorvastatin.
2. Confirm the lane explicitly says matched in this session, pharmacist review
   is required before payment and `Not medical advice`.
3. Open Telmisartan, scroll to `More Medicine essentials`, open Atorvastatin,
   then press Android Back. Confirm the original Medicine match lane returns.
4. Start a clean Medicine search for `telmisartan`, open the pending Rx product,
   choose Dr Meera and confirm the product remains open with quantity one.
5. With reduced motion enabled, confirm the lane appears immediately/static
   and no heading, buttons or surrounding catalogue geometry jumps.

Technical/device qualification is not founder approval. R58.2 remains founder
approved/protected. R58.1, R58.3.1 and R58.4.1 remain founder-review pending.
R58.6 requires its own read-only audit, candidate registration and source seal.
