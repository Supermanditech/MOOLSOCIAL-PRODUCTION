# C24I OPPO power-audit parser rejection

Date: 2026-08-09

The first compact, read-only C24I OPPO readiness audit captured the connected OPPO CPH2375, 100% battery, 32.9 C temperature, ample `/data` storage and `mWakefulness=Asleep`. It also emitted a non-terminating PowerShell error because an optional `mInteractive` match was absent and the parser called `Trim()` on null.

No device, application, repository runtime or build authority was mutated. The installed r60.22 predecessor remains preserved.

The retry is permitted only with null-safe handling of optional `dumpsys power` fields. Device readiness is evaluated from fields that are actually present and retained in evidence; a missing optional field cannot be fabricated or treated as an implicit pass.
