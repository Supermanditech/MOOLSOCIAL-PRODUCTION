# C30M cross-file patch-hunk owner rejection

- ID: `REG-20260812-1448-C30M-CROSS-FILE-PATCH-HUNK-OWNER-REJECTION`
- Date: 2026-08-12
- Scope: local provider-only deployment-control hardening
- Result: patch verification rejected the complete change; no file or cloud mutation occurred

One patch placed a test-file hunk under the deployment-script update header, so
the expected lines could not exist in that owner. C30M retries with a separate
explicit `Update File` header for each owner and verifies the resulting syntax
before execution.
