# Combined baseline defect correction

Founder goal: reconcile all useful Cursor/Codex implementation and qualify a new baseline without regressions or known in-scope defects. Parent 6e7e34c0e7aa15d4710b1132bf4371f7dddf65d3 preserves both exact source tips and all 347 divergent commits.

BASELINE-CART-01 / REG4628: broader retained-behaviour tests expose Paracetamol split inside one word at 320x844, 200 percent text. The illustration-sized Cart thumbnail reduces text width even after controls move below. Preserve truthful thumbnail disclosure and full product name, use responsive composition when the longest word does not fit. Existing failing oracle is R5 readability cart m-paracetamol-500 320x844-2.0 in buy_v2_screen_test.dart. Add a focused Cart regression, run existing failing case and connected Cart checks. No new Redmi test for this fix per founder. No production deployment.

Retained failure: C:/Users/jisal/Documents/Codex/2026-09-18/whi/work/integration-historical-useful-behaviour-tests.log. Do not label the broader suite passed. Review baseline strict production boundary remains unresolved; source reconciliation is not production publication authority.
