# Buy current-screen hash optional ripgrep no-match recurrence

Date: 15 August 2026
Regression: `REG-20260815-2262-BUY-CURRENT-SCREEN-HASH-OPTIONAL-RG-NO-MATCH-RECURRENCE`

An optional search found no existing config or quality record containing the current Buy-screen SHA-256 and returned ripgrep exit code 1. The command did not explicitly accept that normal no-match result.

No file changed. The lookup will not be retried; the Buy audit continues from direct source, declared baselines and existing ticket evidence only.
