# C30T credential-hit cause misclassification — 2026-08-13

## Mistake

The initial explanation blamed credential-scanner self-matches before collecting safe filename-only evidence. `rg -l` then proved all seven matches were existing backend security/redaction test fixture files.

## Impact

- No credential value was read or printed.
- No AAB, upload, install or device mutation occurred.

## Prevention

Credential-scan causes must be based on a filename-only inventory. C30T requires zero credential-shaped matches in production source. Test fixtures are allowed only through an exact seven-file filename allowlist, without reading or printing their matching values.
