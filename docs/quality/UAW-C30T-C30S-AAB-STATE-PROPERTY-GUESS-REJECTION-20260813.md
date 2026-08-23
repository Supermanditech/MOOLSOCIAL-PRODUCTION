# C30T C30S AAB state-property guess rejection — 2026-08-13

## Rejection

The first preserved-artifact check guessed `candidate.aabPath` in the C30S
machine state. That property does not exist. PowerShell converted the null path
into the repository directory, and `Get-FileHash` correctly rejected the
directory.

No artifact or source changed. The failed output is not integrity evidence.

## Permanent prevention

Enumerate the exact state properties before resolving an artifact; require a
nonempty path and `Test-Path -PathType Leaf`; only then compare its byte count
and SHA-256 to the sealed predecessor values.
