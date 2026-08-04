# BUY-FV2 R56.2 scanner manual-code sheet motion handoff

Date: 2 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED — FOUNDER REVIEW PENDING**

R56.2 is complete as one bounded logical popup family. Only the existing
scanner manual-code sheet under `BUY-FV2-076`/`030` received the scoped route,
keyboard-inset, reduced-motion and persistent-field-label policy. R56.1 and the
remaining popup families are unchanged.

Exact candidate:

- `BUY-R56-SCANNER-MANUAL-CODE-SHEET-MOTION-FIX2`
- profile `1.0.0-r56.2` (`2026080215`)
- source SHA-256
  `BC4CE8648382262611CFB565FC533230DD71F296B4DD5D01E6CAC2BA385FBC3C`
- APK/install SHA-256
  `11630014586963BB8E79FFDFA9F5F87712FBF1A7CBA5EABE11C6B194886E1CF4`
- evidence
  `artifacts/quality/buy-scanner-manual-code-sheet-motion-r56-2-fix2-20260802-92`

All required automated gates, two Buy regressions, responsive/reduced captures,
machine-gated build/install checksum, OPPO journey/accessibility/keyboard/Back/
dismissal/permission/lifecycle/process replay, failure scan, performance trace
and post-device source identity pass. Performance p95 is 16.375 ms with no
frame over 33 ms. Founder review remains the only pending gate.

The remaining 11 native modal call sites are registered as eight separate
R56.3-R56.10 logical families in
`docs/quality/BUY-R56-POPUP-MOTION-STYLE-UX-TICKET-MATRIX-20260802.md`. Do not
start R56.3 until a new execution authorizes that one family and its pre-runtime
contract is registered. Technical qualification of R56.2 is not visual
approval of any R56 candidate.
