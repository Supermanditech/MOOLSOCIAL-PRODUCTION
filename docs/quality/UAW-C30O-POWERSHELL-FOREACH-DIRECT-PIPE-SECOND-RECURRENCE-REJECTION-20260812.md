# C30O PowerShell foreach direct-pipe second recurrence rejection

Date: `2026-08-12`

State: `REJECTED_READ_ONLY_COMMAND_NO_REPOSITORY_OR_EXTERNAL_MUTATION`

During the founder-authorized Google Play Internal Testing and YouTube
compliance reconciliation, a bounded file-inventory command placed a
statement-form `foreach` block directly before `Format-Table`. PowerShell
rejected the command at parse time with `An empty pipe element is not allowed`.

This repeats the active prevention in `REG-20260812-1479` and
`REG-20260812-1480`. The failed command produced no accepted inventory evidence
and changed no repository file, device, provider, browser or console state.

Before retry, the inventory output must be materialized as
`$rows = @(foreach (...) { ... })`, and only `$rows` may enter the formatter
pipeline. `scripts/check-codex-development-regression-memory.ps1` remains the
machine prevention gate. The corrected read-only inventory completed only
after this recurrence was explicitly acknowledged; normal product work stays
paused until this durable record is present.
