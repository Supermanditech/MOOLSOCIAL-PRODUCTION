# C30M gcloud logging-filter backslash-quote rejection

- ID: `REG-20260812-1462-C30M-GCLOUD-LOGGING-FILTER-BACKSLASH-QUOTE-REJECTION`
- Date: 2026-08-12
- Scope: read-only post-deployment provider log proof
- Result: argument parsing rejected; deployment and device proof remain unchanged

The first bounded log query used backslash-escaped quotes inside a PowerShell
double-quoted native argument. PowerShell passed the backslashes as data and
gcloud split the filter. No log result is accepted. C30M materializes one filter
string using PowerShell single-quoted fragments plus the bounded UTC value and
passes that one variable as the native argument.
