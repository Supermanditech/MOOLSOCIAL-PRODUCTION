# R58.8.8 FIX7 candidate registration

Date: 5 August 2026  
Candidate: `BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7`  
Profile reserved: `1.0.0-r58.23 (2026080419)`

## Starting identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- Preserved HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Rejected FIX6 source: 2,466 files, SHA-256
  `5294852BF5653B2B674A614311AF3F4E3182217AAA296893452267CF43EE839F`
- Rejected FIX6 APK:
  `3AFDDA9EAA6FBB84D0340F16A788DC2CDA11A5D3E6A4EAE7C121F219E6BD120A`
- Rejection:
  `artifacts/quality/buy-category-sheet-ime-result-visibility-r58-8-8-fix6-20260804-174/48-fix6-oppo-accessibility-rejection.md`

## Bounded correction

FIX7 replaces the ineffective implicit semantics merge with one explicit,
container-owned, child-excluding editable semantic node. It must expose a stable
label, hint, current value, focused state, tap/focus actions and set-text action
while delegating visual input to the existing `TextField` and `FocusNode`.

## Acceptance criteria

1. Empty OPPO UIAutomator output contains exactly one accessible editable
   category-search owner; it is not NAF and has the `Category search` name plus
   `Find a category` purpose.
2. Focus, tap and accessibility set-text actions focus and edit the same visual
   field; typed value, clear and query filtering remain exact.
3. Flutter tests prove one explicit named text-field node, current value and
   actions before/after focus and entry, with no duplicate label/hint.
4. Visual label/hint, 44 px field geometry, normal `.64` sheet geometry,
   genuine-IME expansion, opaque surface and whole-sheet repaint boundary are
   unchanged.
5. R56.3 finite normal motion and immediate/static reduced motion are unchanged.
6. 320 px/140%, Android/iOS captures, filtered result/label above IME, Close,
   Android Back, product/Back, hot resume, process recreation and vertical
   isolation pass.
7. Focused/related tests, two complete unchanged-source Buy regressions and all
   mandatory positive/expected-rejection gates pass.
8. The unique wrapper APK is checksum-matched on OPPO; accessibility XML,
   performance, runtime scan and final source identity pass.

## Risks

- Excluding child semantics can remove native edit actions unless explicitly
  restored.
- Focus state can become stale without a FocusNode listener.
- Accessibility `setText` can diverge from the controller/query unless both are
  updated atomically with a collapsed selection.

## Reduced motion and protected boundaries

No motion, geometry, styling, search matching, category/product truth, Cart,
order, payment, provider, backend, Social or approved behavior may change.
Reduced motion stays immediate/static. Backend taxonomy/pagination, stock,
nearby/serviceability and personalization remain dependency-held. Technical
qualification is not founder approval; no protected baseline may be updated.
