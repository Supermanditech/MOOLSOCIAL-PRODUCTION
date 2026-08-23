# C30T Cloud Run environment missing valueFrom property

Date: 2026-08-13

C30T qualification cycle 1 passed release configuration, canonical formatting, static analysis, 369 focused Flutter tests with three declared skips, backend verification, Hosting tests, provider controls and release dependency checks. During read-only live Cloud Run verification it failed because StrictMode rejected direct access to an absent optional `valueFrom` property.

The expected capability flags are direct non-secret `value` entries. The correction explicitly inspects the PowerShell JSON property collection, requires a direct value, rejects any `valueFrom` property, and compares the exact expected safe flag. No secret values are read or emitted.

No AAB, upload, install or OPPO mutation occurred.
