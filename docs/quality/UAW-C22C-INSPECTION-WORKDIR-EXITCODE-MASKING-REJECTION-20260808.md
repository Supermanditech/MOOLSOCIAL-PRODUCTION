# C22C inspection workdir and exit-code masking rejection — 2026-08-08

A read-only inspection used an app-relative path from the repository root, and a later successful native search obscured the cmdlet error. A follow-up also applied native `$LASTEXITCODE` handling to PowerShell cmdlets. No source or device state changed. REG-20260808-527 requires literal workdir-resolved paths and cmdlet-appropriate error handling.
