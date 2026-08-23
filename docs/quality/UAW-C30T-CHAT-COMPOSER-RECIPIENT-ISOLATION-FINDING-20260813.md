# C30T Chat composer recipient-isolation finding — 2026-08-13

## Finding

The reused production Chat thread screen owned one text controller for every recipient, while send success/error feedback was global. Switching from thread A to thread B during a pending send could expose A's unsent text to B, allow A's late completion to clear B's newly typed draft, and render A's result banner on B.

## Bounded correction

Retain text drafts by thread, clear only the exact sent text for its owning thread, and own send success/error feedback by thread. Existing text-only provider and idempotency contracts remain unchanged.

## Verification

A delayed fake-gateway widget test sends from thread A, reuses the screen for thread B, types a new B draft, completes A and proves that B's draft remains unchanged and A's result banner is absent. Returning to A shows its result but not its already sent draft. The focused production Chat and journey suites passed `13` tests. Evidence SHA-256: `87511B10BC187A91009F24B7D4D970E9799C797BAC8E099138A655672877957C`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. No real message, backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
