# C21H stale LASTEXITCODE after PowerShell gate rejection

Date: 2026-08-08

The first authorized-install precheck invoked the device-phase regression-memory PowerShell script, which passed with 501 entries and 104 applicable device/profile entries. The caller then inspected a stale native-process `$LASTEXITCODE`, incorrectly threw, and stopped before computing the install input or invoking `adb install -r`.

No installation attempt occurred, so the exactly-one install authorization remains unused. The retry uses terminating PowerShell semantics for `.ps1` gates and inspects `$LASTEXITCODE` only immediately after native ADB calls.
