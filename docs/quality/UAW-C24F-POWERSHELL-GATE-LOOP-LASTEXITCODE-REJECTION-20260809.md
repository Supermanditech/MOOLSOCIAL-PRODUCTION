# C24F PowerShell gate-loop LASTEXITCODE rejection — 2026-08-09

The first compound post-Buy gate command ran the C24F script successfully but
checked native-process `$LASTEXITCODE` after invoking a PowerShell script. A
null or stale value ended the loop with success before the remaining named
gates ran. The cycle is rejected. The retry uses PowerShell exception and
immediate `$?` semantics and requires visible output from every named gate.
