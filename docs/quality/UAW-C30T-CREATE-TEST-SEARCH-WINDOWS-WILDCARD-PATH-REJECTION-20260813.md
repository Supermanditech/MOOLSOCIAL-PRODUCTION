# C30T Create test-search Windows wildcard-path rejection — 2026-08-13

## Rejection

A read-only Create audit passed `apps/mobile/test/*create*test.dart` as a
literal `rg` path on Windows. The wildcard was not expanded, so that search leg
failed with an invalid filename/path result.

## Prevention

The retry uses the exact verified `apps/mobile/test` directory plus `rg --glob`
or exact enumerated files. No source, provider, build, Play, OPPO, Hosting or
communication state changed because of the failed read-only search.
