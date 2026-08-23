# C20H multiline package-dump output rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The first post-install identity diagnostic converted the complete `dumpsys
package` output into a single multiline PowerShell string before applying
`Select-String`. One match therefore printed the entire package dump rather
than the intended version and install-time lines. The actual identity checks
still passed, but the output shape is not reused as concise evidence.

## Prevention

Subsequent device evidence filters raw ADB output line-wise or extracts exact
anchored values before joining. No second install or other device mutation was
performed because of this diagnostic issue.
