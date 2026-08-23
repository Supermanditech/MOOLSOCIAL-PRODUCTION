# REG-20260816-2541 C33L FIX1 gate double-backslash Dart newline mismatch

- Date: 2026-08-16
- Failure: the parsed FIX1 gate expected two literal backslashes before `n`
  while the Dart source correctly contains one `\n` escape.
- Impact: the gate failed before Flutter retry; no build, service, Play or OPPO
  action occurred.
- Prevention: keep exactly one literal backslash in PowerShell expected Dart
  tokens, then reparse and pass both PowerShell hosts before testing.
- Resolution: exact single-backslash Dart tokens passed the focused gate on
  PowerShell 7 and Windows PowerShell before the 43-test affected batch.
