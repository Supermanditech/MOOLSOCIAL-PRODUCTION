# C30M inherited approved-UI-lock drift preflight rejection

- ID: `REG-20260812-1454-C30M-INHERITED-APPROVED-UI-LOCK-DRIFT-PREFLIGHT-REJECTION`
- Date: 2026-08-12
- Scope: local provider-only package qualification
- Result: inherited full UI preflight rejected before backend verification; no cloud action occurred

The legacy private-Dev package preflight revalidated the historical
`login-account-handoff` accepted UI checksum and rejected the preserved newer
Social UI tree. C30M does not rewrite or bypass that accepted reference. The
package owner receives an explicit provider-only qualification mode that skips
only the unrelated approved-UI-lock preflight while retaining regression/MVP
authority, both deployment-control suites, runtime validation, complete backend
verification, export inventory, secret scan and patch-integrity gates. Default
package behavior remains unchanged.
