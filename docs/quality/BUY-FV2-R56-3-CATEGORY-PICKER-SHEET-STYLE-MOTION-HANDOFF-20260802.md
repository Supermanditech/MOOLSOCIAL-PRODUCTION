# BUY R56.3 category-picker sheet style/motion handoff

Date: 2 August 2026

State: **FOUNDER APPROVED AND PROTECTED**

## Qualified candidate

- Candidate: `BUY-R56-CATEGORY-PICKER-SHEET-STYLE-MOTION-FIX3`
- Profile: `1.0.0-r56.3` (`2026080219`)
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,346 app/test files, SHA-256 `3B9F3FCFF96B3157F7455C0F303A7CD718B87614458C1C0A3EA88F4ABCB7F881`
- APK/install: 133,820,701 bytes, SHA-256 `03B1960A0B899954502E7FC188C4BD12D68A908F368F2F8671357CABE6BE3146`
- Evidence: `artifacts/quality/buy-category-picker-sheet-style-motion-r56-3-fix3-20260802-96`

Founder decision: exact FIX3 was approved and protected on 2 August 2026.
Decision evidence:
`artifacts/quality/buy-category-picker-sheet-style-motion-r56-3-founder-approval-20260802-97`.

## Scope and policy

R56.3 owns only the existing Shop/Wholesale/Medicine category picker. It reuses founder-approved R40.3 260 ms forward/reverse route timing, immediate/static reduced motion and selection-after-dismissal ownership. It adds no nested motion, timer, invented loading/result, shared colour token or second modal family.

FIX3 adds one keyed `RepaintBoundary` around the otherwise static sheet subtree. This allows route translation to reuse a composited child and corrects FIX2's performance rejection without changing pixels, geometry, focus, keyboard, semantics, state or timing.

Premium-motion disposition:

- Applied: static category-sheet compositor isolation.
- Reused: R40.3 route timing, DES-001 reduced motion, ripple/haptic ownership and FIX2's IME-safe truthful empty recovery.
- Dependency-held: 080/098 loading and 082/083/140 media/campaign effects.
- Inapplicable: nested/decorative motion, fake loading/prefetch, Lottie without an approved asset and broad modal migration.

## Preserved rejected predecessors

- FIX1 `BUY-R56-CATEGORY-PICKER-SHEET-STYLE-MOTION-FIX1`: rejected because the real-IME no-match explanation/Clear action were occluded. Source SHA-256 `FFE179DD78CBCCA744DF742B60F212A0BD241BA444F3254661CF8E23A87527A3`; APK/install SHA-256 `856541CAA5734223B710E8B5B00434B9797D2DF7DBA175B225CD4C95C9276BE0`.
- FIX2 `BUY-R56-CATEGORY-PICKER-SHEET-STYLE-MOTION-FIX2`: IME and UX corrected, but rejected at p95 34.248 ms initially and 44.594 ms after deterministic pre-warm. Source SHA-256 `3C6EEE6279A3246E0638B8F67997759493C2171626D991CDC2F9CC198BB00110`; APK/install SHA-256 `B34CAB62E3FB874974DB470DA7737FD89CFD15776E1C36CFF52B1A9C23BEBEB1`.

Both folders remain immutable and neither candidate is founder-review eligible.

## Qualification result

Formatting, analysis, focused tests, protected integration, two complete 225-active-test Buy regressions, mandatory positive gates and exact source seals pass. Responsive/reduced captures cover Android/iOS sizes and 320x700 at 140% text.

The checksum-matched OPPO CPH2375 replay passes all three destinations, real-IME no-match/Clear recovery, selection after reverse, Back/close/scrim/drag, hot resume, process recreation and native accessibility hint/focus/visibility. The warmed 97-frame exact-profile trace has presentation p95 29.903 ms, 4/97 frames over 33 ms, none over 100 ms and zero shader/compile events. The corrected logcat/exit-info scan is clean.

## Founder review and boundary

The founder completed review of the exact OPPO candidate and approved it.

Preserve R43/R45-R48/R50/R52.1/R53/R54/R55, approved R56.3,
R56.1/R56.2 and R57.1. R51 FIX16 remains deferred. R56.4 and every later
popup family require separate qualification and approval; never mix them into
the approved R56.3 identity.
