# Chat audit Windows positional wildcard recurrence — 15 August 2026

A read-only capability inventory passed `apps/mobile/test/chat*` as a
positional ripgrep path. PowerShell did not expand that filename wildcard, so
ripgrep reported invalid Windows filename syntax after emitting partial
matches from the command's literal source directories.

The mixed-output command is rejected and provides no complete test inventory.
No source, test, device, backend or external state changed. The retry must first
resolve Chat test owners with `rg --files apps/mobile/test` and then search only
the returned literal paths, or use an ripgrep `--glob` rooted at the literal
existing directory. This recurrence is registered before that retry.

The corrected inventory resolved exactly three Chat test files and the rooted
`--glob 'chat*.dart'` search completed successfully. The registry status is now
resolved; the prevention remains active.
