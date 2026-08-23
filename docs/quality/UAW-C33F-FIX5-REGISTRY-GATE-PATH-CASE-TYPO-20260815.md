# UAW-C33F FIX5 registry gate-path case typo

Date: 2026-08-15

## Preserved mistake

While updating resolved FIX5 regression entries, the REG-2420 gates array introduced `successOR` instead of the exact existing `successor` filename. The mistake was found by immediate bounded review before regression memory or any release gate was retried. No Play, OPPO or other external action occurred.

## Prevention

Register before correction. Every newly added registry gate path must be compared byte-for-byte with `rg --files` output and checked with `Test-Path -PathType Leaf` before the regression-memory gate runs. Case-insensitive Windows path resolution is not accepted as evidence that a durable registry path is spelled correctly.
