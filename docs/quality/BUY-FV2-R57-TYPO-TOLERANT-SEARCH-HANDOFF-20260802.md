# Buy R57.1 typo-tolerant search handoff

Date: 2 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED — FOUNDER REVIEW PENDING**

`BUY-R57-TYPO-TOLERANT-SEARCH-RANKING-FIX1` is the bounded successor under
existing `BUY-FV2-104`/`105`/`106`. It adds deterministic local relevance
ranking over the existing product title, brand, variant and seller/provider
strings. Direct exact, prefix, exact-token and substring matches dominate;
bounded Damerau-Levenshtein token matches are fallback-only. Tokens below four
characters and offer IDs are never fuzzed, every query token must match, and
destination/category/filter ownership runs first.

Qualified identity:

- profile `1.0.0-r57` (`2026080216`);
- source: 2,329 files, SHA-256
  `9A061A1260F44D4752F84045CD8D899398DED70295A798E9E8BE7428837A6487`;
- APK/install: 133,804,309 bytes, SHA-256
  `6C2CA8264191A99E379D75BEAAF83CC2DBF2E69AF7156AE79C4F5BD0D430E08E`;
- evidence:
  `artifacts/quality/buy-search-typo-tolerance-ranking-r57-1-20260802-93`.

Formatting, analysis, the 51-test integrated correction suite, two complete
217-active-test Buy regressions, all mandatory gates, wrapper build,
checksum-matched OPPO pull, exact/near/multi-word/short/ID/vertical/seller
replay, accessibility, IME/Back/Clear, lifecycle/process recreation, failure
scan and post-device source seal pass. The 97-frame profile trace has p95 20.55
ms, 3.093% over 33 ms, none over 100 ms and no shader/compile event.

No backend search, service catalogue, phonetic/synonym dictionary, popularity,
history, personalization, recommendation, provider availability or fabricated
fact was introduced. Search/result motion is the protected R48/R40 owner; this
ticket adds no animation. Technical qualification is not founder approval.
Stop here: R56.2 remains separately pending, R56.3 is not started and R51
FIX16 remains deferred.
