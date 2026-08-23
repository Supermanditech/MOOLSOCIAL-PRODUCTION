# UAW C10 rg multi-file operand existence failure

## Incident

A startup-route search included `apps/mobile/lib/app.dart`, which does not exist
in the current repository. `rg` printed matches from valid operands and then
exited with an error for the missing file. The complete partial result was
discarded.

## Prevention

Every explicit multi-file operand is now resolved from `rg --files` or checked
with `Test-Path -LiteralPath` before search. A missing operand invalidates all
output from that multi-root command; conventional Flutter filenames are never
assumed.

The failed read-only discovery command changed no product, APK or OPPO state.
