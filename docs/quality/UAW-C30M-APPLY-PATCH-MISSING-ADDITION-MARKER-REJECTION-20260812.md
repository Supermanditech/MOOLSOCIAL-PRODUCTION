# C30M apply-patch missing addition-marker rejection

- ID: `REG-20260812-1440-C30M-APPLY-PATCH-MISSING-ADDITION-MARKER-REJECTION`
- Date: 2026-08-12
- Scope: local regression-evidence registration
- Result: patch parser rejection; no file or cloud mutation occurred

One added-file patch line omitted its leading `+`, so the patch parser rejected
the complete change. C30M reissues a complete valid patch and verifies every
line in an `Add File` body carries the required addition marker.
