# Temporary navigation prototype stale LASTEXITCODE recurrence

Date: 2026-08-09

The prototype verification wrapper invoked the PowerShell regression-memory checker, received its explicit passing output, and then incorrectly tested `$LASTEXITCODE`. That variable retained an unrelated native-process value, causing a false failure before the HTML syntax check ran.

This repeated the active prevention already recorded by REG076, REG156, REG255, REG502, REG528, REG684, REG721 and REG755.

Correction: repository PowerShell gates run alone and pass by returning without a terminating error. A following native validator runs in a separate command and checks its own exit code immediately.

No production runtime, Flutter source, accepted screenbook or device state changed.
