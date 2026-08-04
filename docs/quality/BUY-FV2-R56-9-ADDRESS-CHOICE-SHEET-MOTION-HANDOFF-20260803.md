# Buy Flutter V2 R56.9 address-choice sheet motion handoff

Date: 3 August 2026

State: **FIX4 TECHNICALLY/DEVICE QUALIFIED — FOUNDER REVIEW PENDING**

## Qualified candidate

`BUY-R56-ADDRESS-CHOICE-SHEET-MOTION-FIX4`, profile `1.0.0-r56.9`
(`2026080311`), owns only the existing saved delivery-address choice family.
It uses one finite 280 ms arrival/220 ms reverse, immediate static reduced
motion, stable white/navy geometry, explicit close and native selected-address
semantics. Selection returns to the existing owner only after reverse.

Exact app/test source is 2,406 files at SHA-256
`4A938B1D41814661C7C85B8AEAD0764C303BDAAE7E7D18A35E9FB2A4F695F07B`.
The wrapper-built profile APK and checksum-matched OPPO installed pull are
133,919,053 bytes at SHA-256
`E91071F93028BCEA41F36E4229171A80EDCBED2E437C68523990A8856718F049`.

## Preserved device rejections

- FIX1 exposed a clipped 42-pixel Add action at the OPPO app-viewport edge.
- FIX2 attempted caller MediaQuery padding; OPPO still reported zero.
- FIX3 resolved MediaQuery, raw View padding and viewport exclusion; OPPO
  edge-to-edge still exposed none, so the action remained clipped.
- FIX4 retains those real-inset sources and adds the bounded 24 logical pixel
  fallback needed by an edge-to-edge device that reports zero for all three.

Every rejected source, APK, installed pull, hierarchy and decision is retained.

## Qualification

Final focused coverage passes 24 active checks plus two capture skips. Four
responsive captures, full analysis, two unchanged-source full Buy regressions
at 278 active plus 14 skips, every release/protected gate, APK identity and
signature, exact install/pull checksum, Account and Checkout replay, native
accessibility, focus/keyboard/Back, lifecycle, process recreation, clean
failure scan and the warmed profile trace all pass.

On OPPO the Add address native Button is `[32,1352][688,1440]`, a complete
88-pixel tap target within the 1,442-pixel application viewport. Performance
p95 is 28.264 ms, zero frames exceed 100 ms and no shader/compile event occurs.

## Protected boundary and next work

R43/R45-R48/R52.1/R53/R54/R55 and qualified R56.6-R56.8 remain unchanged.
R56.10 request/add-address forms were exercised only for reachability and Back/
keyboard recovery; their runtime implementation is not changed by R56.9.
No geocode, serviceability, address validation, provider, payment, order or
backend result is invented.

Technical/device qualification is not founder approval. Exact evidence:
`artifacts/quality/buy-address-choice-sheet-motion-r56-9-fix4-20260803-115`.
R56.10 is the next registered popup family.

