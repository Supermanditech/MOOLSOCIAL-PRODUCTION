# C29U PowerShell backslash-quote rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1289-C29U-POWERSHELL-BACKSLASH-QUOTE-REJECTION`

The first C29U source-seal run searched for a Dev project constant using
backslash-escaped double quotes in a PowerShell string. PowerShell retained the
backslash, so the assertion falsely rejected the correct TypeScript literal.

The assertion now uses a single-quoted PowerShell string containing the exact
double-quoted TypeScript constant. The failed gate produced no cloud, build or
device action.
