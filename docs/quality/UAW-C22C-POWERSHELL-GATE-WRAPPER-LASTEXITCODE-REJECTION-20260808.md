# C22C PowerShell gate-wrapper rejection — 2026-08-08

The first C22C protected-gate wrapper passed the delivery lock but stopped because it checked native `$LASTEXITCODE` after a PowerShell `.ps1` invocation. No later gate was claimed. REG-20260808-528 requires PowerShell-native terminating-error handling for script gates.
