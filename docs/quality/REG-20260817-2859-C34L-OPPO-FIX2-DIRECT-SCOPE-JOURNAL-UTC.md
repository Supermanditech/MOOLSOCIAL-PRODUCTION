# REG2859 — C34L OPPO FIX2 direct-scope journal UTC

Date: 17 August 2026
State: registered first required PS7 direct+nested OPPO failure

## Mistake

The required PS7 direct/nested OPPO run completed the stable source checker, then
the OPPO child found its journal `preparedUtc` wire token quoted once but not in
the canonical format (`canonical=0`, runtime type `System.DateTime`). Isolated
PS7 and WinPS child suites were green, so caller-scope JSON date coercion still
changes a journal-save path. No WinPS direct retry or later mutation followed.

## Prevention

Normalize every journal UTC field to invariant canonical text immediately before
each save, serialize from a fresh exact wire DTO rather than a reparsed typed
object, and assert raw prepared/committed token cardinality after every write in
isolated and source-checker-preceded scopes on both hosts.
