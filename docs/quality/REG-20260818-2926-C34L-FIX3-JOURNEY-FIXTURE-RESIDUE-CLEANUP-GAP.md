# REG2926 — FIX3 journey fixture residue cleanup gap

## Observed event

The authoritative journey adapter/checker completed dual-host behavior qualification, but final inventory found 64 exact-prefix fixture directories and 3 exact-prefix file-as-root negative fixtures still present from stopped and successful runs.

## Impact

- PS7 and WinPS semantic results are green, but the handoff is not production-grade cleanup evidence.
- Residue is preserved pending exact ownership, reparse, hash, and privacy inventory.
- No broad cleanup, real journey, device, private, build, browser, provider, or external action occurred.

## Root cause

The checker created unique fixture roots for positive and negative cases without one outer `try/finally` that deterministically unlinks checker-created reparse entries and deletes every exact checker-owned root on success and failure.

## Mandatory prevention

1. Add one outer `try/finally` tracking every exact path created by the checker.
2. Before removal, resolve and prove each legacy root is under the repository `tmp` directory, matches the exact journey-fixture prefix, is not an unexpected reparse ancestor, and contains no private/raw-device values.
3. Inventory sanitized relative paths, SHA-256, and bytes for retained incident evidence.
4. Remove only proven checker-owned roots/files using path-kind-appropriate APIs; assert exact absence and never touch other prefix families.
5. Fresh PS7 and WinPS runs must each report `cleanupVerified=true` and leave zero newly created residue.
