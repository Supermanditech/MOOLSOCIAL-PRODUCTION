# C26G PowerShell script LASTEXITCODE false rejection

The regression-memory script passed, but the surrounding retry command checked native-process `LASTEXITCODE` after the `.ps1` call. It was null and the comparison falsely threw before Flutter tests ran.

Repository PowerShell gates now rely on terminating-error behavior under `ErrorActionPreference = Stop`. `LASTEXITCODE` is checked only immediately after native Flutter or Dart commands.
