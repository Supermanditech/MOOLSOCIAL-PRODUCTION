# UAW-C33F FIX3 Firebase SHA-list colon parser false empty

- Recorded at: `2026-08-15T10:45:26.3508492Z`
- Regression: `REG-20260815-2397-C33F-FIX3-FIREBASE-SHA-LIST-COLON-PARSER-FALSE-EMPTY`

After founder-completed reauthentication, the isolated read-only Firebase SHA-list process exited zero. The initial parser matched only colon-delimited certificate values and returned zero rows, which contradicts the known existing Firebase fingerprints and cannot be treated as provider truth.

No raw CLI output or certificate value was emitted or persisted. Before reparsing, all possible certificate, application, OAuth, API-key, token, account and URL values must be redacted in memory; only the sanitized output labels may be inspected.
