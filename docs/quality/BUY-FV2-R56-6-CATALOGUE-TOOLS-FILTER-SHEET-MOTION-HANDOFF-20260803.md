# R56.6 catalogue tools/filter sheet motion handoff

State: technically/device qualified; founder review pending.

Qualified candidate: `BUY-R56-CATALOGUE-FILTER-SHEET-MOTION-FIX3`, profile
`1.0.0-r56.6` (`2026080303`).

- Source: 2,388 app/test files, SHA-256
  `F22B224BEA32AC13843FE4537B1CB1CD120762784842534281ED100149E2A4C0`.
- APK/checksum-matched OPPO install: 133,837,085 bytes, SHA-256
  `32CD47F12F27D9A326CDCF7AA54320509CA5C736597AB13F98C9897F33341709`.
- Evidence:
  `artifacts/quality/buy-catalogue-filter-sheet-motion-r56-6-fix3-20260803-107`.

FIX3 makes the existing catalogue header control open one native sheet for its
existing tools and destination-specific filters. It retains session truth,
waits for reverse before tool/filter actions, provides zero-duration reduced
motion, and introduces no provider/backend/live result.

Qualification passes responsive/reduced captures, 248-active-test dual Buy
regressions, all positive and protected-boundary gates, OPPO reachability and
semantics, Shop/Wholesale/Medicine replay, Back/Close, lifecycle/recreation,
failure scan and a 104-frame presentation p95 of 32.021 ms. FIX1's reachability
rejection and FIX2's performance rejection remain immutable.

Founder review should follow the six exact observation points in
`56-technical-device-qualification-summary.md`. Approval must name FIX3 and its
APK checksum. R56.7 is separate and receives no approval from this handoff.
