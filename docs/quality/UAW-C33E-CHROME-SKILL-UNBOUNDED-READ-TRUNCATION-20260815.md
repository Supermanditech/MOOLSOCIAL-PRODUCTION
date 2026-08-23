# UAW C33E Chrome skill unbounded read truncation

Date: 2026-08-15
Regression: `REG-20260815-2359-CHROME-SKILL-UNBOUNDED-READ-TRUNCATED`

The first attempt to read the installed Chrome-control skill used one unbounded `Get-Content -Raw` operation. The tool result exceeded the usable response window and was truncated, so it cannot establish that the required skill instructions were read completely.

Recovery: register this failure before retry, measure the file's exact line and byte counts, read non-overlapping bounded line pages through the measured end of file, and verify page coverage before any Chrome-control action. Do not use the browser for a console page if the visible or returned page state could expose an API key, OAuth client-ID value, token, nonce, private verdict, private key, or attestation payload.
