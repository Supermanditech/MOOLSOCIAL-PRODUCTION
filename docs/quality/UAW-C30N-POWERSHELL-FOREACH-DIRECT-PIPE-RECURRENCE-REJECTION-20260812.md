# PowerShell foreach direct-pipe recurrence rejection

During the August 12 release-sequencing audit, a read-only repository inventory
repeated the statement-form `foreach { ... } | ConvertTo-Json` parser mistake
already prohibited by REG-20260812-1479. PowerShell rejected the command before
execution, so no child command ran and no repository or external state changed.

Root cause: the active memory rule was not applied while composing the bounded
inventory. Permanent strengthening: every PowerShell collection loop is first
assigned with `$rows = @(foreach (...) { ... })`; only `$rows` may enter a
formatter pipeline. The corrected attempt remains blocked until this recurrence
is registered and the regression-memory gate passes.
