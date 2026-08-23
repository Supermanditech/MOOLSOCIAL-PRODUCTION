# REG-20260822-3136 — APK-state inline-if concatenation parser recurrence

Date: 22 August 2026

State: registered; zero machine-state read or mutation

A read-only APK machine-state projection placed a statement-form PowerShell
`if` directly after the string concatenation operator while formatting optional
runtime-define values. PowerShell rejected the command before the JSON values
were projected.

No source, machine state, registry, build, APK, OPPO, provider, account, email,
SMS, Play or cloud state changed from the failed projection.

Root cause: the command repeated the already registered rule that statement
forms cannot serve as inline value expressions in PowerShell concatenation.

Prevention: compute each optional runtime-define display value into a named
scalar first, then concatenate only that scalar. Never place statement-form
`if` directly after `+` or inside a property value.
