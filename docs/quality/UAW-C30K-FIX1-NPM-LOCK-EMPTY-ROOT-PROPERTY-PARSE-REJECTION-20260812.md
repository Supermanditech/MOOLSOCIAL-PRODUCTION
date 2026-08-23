# C30K-FIX1 npm lock empty-root-property parse rejection

- Scope: local dependency patch verification.
- Result: `firebase-functions@7.3.2` installed successfully, but the follow-up PowerShell parser could not represent package-lock's empty-string root package property as a normal object property.
- Root cause: `ConvertFrom-Json` was used without `-AsHashtable`.
- Prevention: parse package-lock with hashtable mode or use npm's package query; keep package-manager exit status separate from follow-up metadata parsing.
- Cloud/device impact: none.
