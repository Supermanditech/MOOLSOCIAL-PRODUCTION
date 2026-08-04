# Buy FV2 R56.5 product-review and issue-report form motion handoff

## FIX1/FIX2 device rejection and final bounded FIX3 registration

FIX1 profile `1.0.0-r56.5` (`2026080222`) is preserved/device rejected at
source SHA-256 `C3B3E180744C30DF02238E66178AD603C589A6D9C525C713826AE29935B4DBB7`
and APK/install SHA-256
`42419EFDE5DEA133B499C7819D0A9437092C72902289459514D986A2F90447CB`.
The real OPPO review `EditText` is editable/focusable but `NAF=true` and unnamed
in native accessibility. FIX1 is not founder-review eligible.

Corrective `BUY-R56-REVIEW-ISSUE-FORMS-MOTION-FIX2`, planned profile
`1.0.0-r56.5` (`2026080223`), is registered against the exact rejected source.
Only review-field semantics, 1-star singular copy and their assertions may
change. Evidence:
`artifacts/quality/buy-review-issue-forms-motion-r56-5-fix2-20260802-102`.

FIX2 completed host/build/install qualification on 2,374-file source SHA-256
`D2231BB867CA03AB7914D68E219E516032F18C9886B99B445F9C3AB0405E8F79` and
checksum-matched APK/install SHA-256
`C398831A0A38E09FF4C1BD118347C6BDAA6CAA2D5E04E2DB6C08AD8374A18B70`, but
is device rejected: the OPPO tree still contains duplicate review `EditText`
nodes and an unnamed `NAF=true` editable owner.

Final bounded successor `BUY-R56-REVIEW-ISSUE-FORMS-MOTION-FIX3`, planned
profile `1.0.0-r56.5` (`2026080224`), owns only one explicit native semantics
proxy plus its deterministic assertion. It preserves exact FIX2 pixels,
motion, validation, focus-first Back, report flow and session truth. If the
native OPPO tree still fails, R56.5 stops without another retry. Evidence:
`artifacts/quality/buy-review-issue-forms-motion-r56-5-fix3-20260803-103`.

FIX3 is now preserved/device rejected. It passed the complete host/build/install
qualification on exact source SHA-256
`52E0A858CCE1577634DF1C5FA626F0D7B6C9447C53F38265219CEB70E008E471` and
checksum-matched OPPO APK SHA-256
`7EAFA32D855DCCC4D2217B0388CAD65D6D813C842AD2945097A0971E32E66EBF`.
The real path contains one native review `EditText`, but it remains `NAF=true`
with no native name. No FIX4 is authorized; R56.5 is stopped and R56.6 remains
held/not started pending a separate native-semantics decision.

## Registered candidate

- Candidate: `BUY-R56-REVIEW-ISSUE-FORMS-MOTION-FIX1`
- Planned profile: `1.0.0-r56.5` (`2026080222`)
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Pre-candidate app/test source: 2,364 files, SHA-256 `A9807D9AF2171878B12031BD8B10D51B9D60C5AC431D29276DB6A552A3F3F6FD`
- Evidence: `artifacts/quality/buy-review-issue-forms-motion-r56-5-20260802-101`

## Scope and acceptance

R56.5 owns only `_showProductReviewSheet` and `_showProductReportSheet` in the real product-detail reviews panel. It applies a dedicated finite 280 ms arrival/220 ms reverse, bounded keyboard inset, immediate reduced motion, named semantics routes, explicit close actions, stable max-width geometry and local form availability derived only from rating/comment/reason state.

Existing `BuyV2Session.submitProductReview` and `reportProduct` remain the only mutation and completion owners. No review moderation, backend delivery, report acceptance or provider fact may be invented. Dismissal and invalid local state never mutate.

R56.4 exact household-only FIX2 is founder approved/protected at APK/install SHA-256 `EC78E90323790BC602774A304F0F60F263B9A4107E77F81D1E3E705D2181BAD1`. The unreachable Saved helper remains outside that approval. R56.6 and every later popup family are registered/not started.

Technical/device qualification requires focused normal/reduced/responsive/keyboard tests, two full Buy regressions, every mandatory release/protected gate, one machine-gated profile APK, checksum-matched OPPO replay of both forms, accessibility/focus/Back/lifecycle/process evidence, failure scan, performance and exact source seals. Stop after R56.5; technical qualification is not founder approval.
