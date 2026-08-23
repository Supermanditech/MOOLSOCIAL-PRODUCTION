# C18D overbroad cycle-1 shard-1 selection rejection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-C17-HOST-QUALIFICATION-REFRESH-AFTER-SCREEN01-LOCK-FIX1-C18D`

State: **PASSED TESTS BUT REJECTED AS A QUALIFYING SHARD**

The first cycle-1 shard-1 command preserved the exact source fingerprint and
excluded all golden owners, but selected 38 files by adding seven top-level
Social suites to the established boundary. It passed 307 tests, not the frozen
252-test shard, so it is not counted toward either qualifying cycle.

The prior evidence was explicit: Universal/Social contains 30 discovered files
(29 `ui_v2/universal` plus one `ui_v2/social`), and the one non-golden Screen04
conformance owner is added separately. The correct boundary is therefore 31
files. REG-390 requires both file-count and expected test-count reconciliation
against the accepted evidence before a refreshed cycle is counted.

No source, golden or installed package changed during the rejected pass.
