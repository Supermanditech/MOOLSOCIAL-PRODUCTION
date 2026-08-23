# C30S process snapshot absent-name nonzero

Date: 2026-08-12

A read-only monitoring snapshot requested `dart`, `flutter` and `pwsh` in one
`Get-Process` call. Active Dart and PowerShell rows were returned, but the call
exited `1` because no process named `flutter` existed. Qualification continued
unchanged.

Optional processes are now enumerated from the process table or queried with
explicit expected-absence handling.
