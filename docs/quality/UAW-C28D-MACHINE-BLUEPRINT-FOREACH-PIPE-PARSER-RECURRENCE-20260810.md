# C28D machine-blueprint foreach-pipe parser recurrence

- Date: 2026-08-10
- Phase: read-only APK machine-state blueprint audit
- Rejection: an agent attempted to pipe directly after a PowerShell `foreach`
  statement while checking registered evidence-path existence, producing
  `An empty pipe element is not allowed` before the check executed.
- Product/device effect: none; no repository or OPPO mutation occurred.
- Root cause: the REG939 parser shape recurred in a new read-only inventory
  command instead of emitting objects inside an explicit collection.
- Prevention: keep `foreach` inventory output in a named array or explicit
  `@(...)` collection, then pipe that collection separately. The audit may retry
  only after this recurrence is registered.
