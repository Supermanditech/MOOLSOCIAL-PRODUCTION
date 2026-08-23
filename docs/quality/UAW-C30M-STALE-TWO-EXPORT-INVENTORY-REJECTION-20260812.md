# C30M stale two-export inventory rejection

- ID: `REG-20260812-1457-C30M-STALE-TWO-EXPORT-INVENTORY-REJECTION`
- Date: 2026-08-12
- Scope: local provider-only full qualification
- Result: export gate rejected the current three-function source; no cloud action occurred

The legacy export gate still expected only `youtubeProvider` and
`youtubeOAuthCallback`, although `moolSocialContent` is now a source-owned and
already deployed function. C30M audits the exact export owner and updates the
allowlist to the truthful three current exports; it does not add or deploy any
new function.
