# UAW-C33F FIX6 static needles used interpolating strings

Date: 2026-08-15

## Preserved mistake

The first FIX6 main-gate patch expressed PowerShell source-code needles such as `$fixture`, `$state` and `$aggregate` in double-quoted strings. Under strict mode, the undefined fixture variable would throw before the static contract ran, while defined variables could interpolate object text instead of the required literal source line.

The mistake was found by immediate patch review before parser execution, lifecycle-test replay, preupload retry or any external action.

## Prevention

Register before correction. Static PowerShell source needles containing dollar-prefixed variable names must use single-quoted literals or explicit escaping. Review every new needle for interpolation semantics before invoking a parser or gate, and retain the bounded source-block assertion after correction.
