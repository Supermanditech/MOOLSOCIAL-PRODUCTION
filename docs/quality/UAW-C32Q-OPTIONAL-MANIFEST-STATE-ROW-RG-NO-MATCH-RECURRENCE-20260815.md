# UAW C32Q optional manifest state-row rg no-match recurrence

Date: 15 August 2026
Regression: `REG-20260815-2274-C32Q-OPTIONAL-MANIFEST-STATE-ROW-RG-NO-MATCH-RECURRENCE`

An optional `rg` lookup for state or qualification rows in the retained C32N-C32P manifest returned the normal no-match exit code 1, which the caller treated as failure. Nothing changed.

The lookup will not be retried. C32Q uses the manifest format already established by direct reads: ordered repository-relative path and SHA-256 rows, with the aggregate computed over UTF-8 rows joined by LF and no final LF.
