# C30M curl JSON native-argument split rejection

- ID: `REG-20260812-1463-C30M-CURL-JSON-NATIVE-ARGUMENT-SPLIT-REJECTION`
- Date: 2026-08-12
- Scope: unauthenticated post-deployment provider-denial proof
- Result: malformed client command produced HTTP 400 plus a curl URL parse error; no cloud mutation occurred

The first no-credential curl command used backslash-escaped JSON inside a
PowerShell double-quoted argument. Native argument splitting produced one
malformed request and an extra invalid URL argument. Neither the HTTP 400 nor
the command is accepted as an authorization-denial proof. C30M retries once
with a single-quoted literal JSON argument, captures body and status separately,
and requires a successful curl process plus the expected denial status.
