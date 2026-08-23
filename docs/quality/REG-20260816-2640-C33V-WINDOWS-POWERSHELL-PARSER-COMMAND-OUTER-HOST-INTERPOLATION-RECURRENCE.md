# REG2640 — C33V Windows PowerShell parser command repeated outer-host interpolation

Date: 2026-08-16 IST

The first C33V Windows PowerShell parser-validation command placed its script
body in a double-quoted argument launched from PowerShell 7. The outer host
expanded the inner variables, so Windows PowerShell received a malformed
`foreach` statement and parsed none of the candidate files.

This is a recurrence of the cross-host interpolation class registered in
REG2637. No repository script ran, no source manifest was sealed, and no AAB,
Play or OPPO authority was consumed. Count no Windows PowerShell parser result.

Retry only with a single-quoted literal command body owned entirely by Windows
PowerShell. Require one clean `PARSE_OK` marker per bounded file and no error
records while retaining the independent PowerShell 7 parser result.
