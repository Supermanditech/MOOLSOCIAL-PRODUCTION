# C23H REG598 evidence filename assumption rejection

Date: 2026-08-09

While preparing the permanent registration for the lost C23H gate output, the
inspection command guessed a shortened REG598 evidence filename. That path did
not exist. PowerShell emitted non-terminating path errors while the compound
command still reported exit code zero. No repository file was mutated.

This repeated the already-active exact-owner discovery rule. The corrected
workflow first inventories bounded `docs/quality` filenames, then reads only a
literal returned owner. Any PowerShell error record invalidates the compound
inspection even when the shell process exits zero.
