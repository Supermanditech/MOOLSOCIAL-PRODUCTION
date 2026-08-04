# R58.8.8 FIX7 technical qualification

Date: 5 August 2026  
Candidate: `BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7`  
Disposition: **technically/device qualified on OPPO; founder review pending**

## Exact identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- Preserved HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,466 files, SHA-256
  `A05B47F0893778064E255574DF3678BF198DAE72A18DA7C81710693557AE1BEE`
- Profile: `1.0.0-r58.23 (2026080419)`
- Wrapper-built and OPPO-pulled APK SHA-256:
  `F0C1061D1D7897130528533F254B41BDC48FE7958E7DD9B50624FEF6EE3B5DC9`
- APK bytes: `134214109`
- Device: OPPO CPH2375, serial `2b3e0f71`, Android 13/API 33

Pre-build, post-build and post-device source manifests are exact. The
wrapper-built APK and the APK pulled from the OPPO are byte-identical.

## Correction and accessibility root cause

FIX7 owns one explicit child-excluding editable semantics node and delegates
tap, focus and set-text to the same visual `TextField`, controller and query
owner. It exports stable label, hint, current value, focus state and editable
actions without changing visual geometry, category matching, motion or
commerce state.

The legacy `uiautomator dump` XML continued to show `NAF=true` for the empty
Flutter `EditText`. Direct Android `AccessibilityNodeInfo` inspection proved
that this is a lossy evidence-harness limitation, not a missing accessible
name: Android API 28+ carries Flutter's combined label and hint through
`setHintText`, while the legacy XML serializer omits `hintText`. The final
device probe returned `hint=Category search, Find a category`, editable,
focusable, clickable and set-text actions, with one passing instrumentation
test. Exact proof: `47l-accessibility-hint-probe-final.log`; platform bridge
trace: `49-accessibility-xml-root-cause.md`. Earlier XML-based FIX5/FIX6
rejections remain preserved as historical evidence and are not deleted.

## Host qualification

- Focused tests: 11 active passed; 1 capture skipped intentionally.
- Related Buy tests: 77 passed.
- Full Buy regressions: two unchanged-source runs, each 359 active passed and
  20 intentional skips.
- Formatting, analysis, 320 px/140% text and Android/iOS capture coverage
  passed.
- Premium-motion policy and self-test, PowerShell compatibility, brand,
  approved Buy reference, 154-route interaction contract, customer copy,
  HTML copy, backend boundary, data egress and their required self-tests passed.
- Splash, Social and Buy protected-boundary gates rejected the exact registered
  known hashes/inventories and were correctly classified as passed.
- The wrong-source machine-gate self-test rejected; the exact source passed.
  The APK was built only through `scripts/build-buy-device-review.ps1`.

## OPPO qualification

- Direct Android accessibility probe passed with the exact category-search
  label/hint and editable actions.
- Cold/process first-frame matrix passed Shop, Wholesale and Medicine at one,
  two and three seconds; every filtered card had 422 px IME clearance.
- Cumulative ownership passed honest no-match/clear, exact category selection,
  Shop product/Back restoration, hot resume, independent cross-vertical state
  and clean Shop exit. A stale harness version-name correction failed closed,
  was root-caused, preserved, corrected and passed in immutable `harness3`.
- Focus, keyboard hide/refocus, retained query, explicit Close and Android Back
  passed with the same 422 px clearance.
- Visible reduced motion passed with static state and exact category restore;
  window/transition/animator scales were independently restored to `1/1/1`.
- Sixteen ready-process Shop sheet arrival/Back cycles passed: 634 presented
  frames, p50 21.455 ms, p90 24.871 ms, p95 31.725 ms, p99 55.037 ms,
  maximum 64.658 ms, 29 intervals above 33.333 ms, zero above 100 ms and zero
  shader/compile markers.
- Runtime scan found zero Flutter errors, fatal exceptions, native fatal
  signals, ANRs or lost-device events. All 16 exits were explicit
  install/force-stop/remove-task harness actions; unexpected exits were zero.

## Boundary

No protected baseline was updated. This result changes no taxonomy, stock,
serviceability, payment, order, provider, backend or personalization fact.
R56.3 finite normal motion and immediate/static reduced motion are reused
unchanged. Technical/device qualification is not founder approval.

