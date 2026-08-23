# C30L C30J inventory filename guess rejection

- Scope: local read-only host-qualification owner discovery.
- Rejection: after listing the exact C30J inventory files, the command still requested a nonexistent `source-manifest.txt` copied from another ticket's naming convention.
- Prevention: read only the exact returned `inventory-seal.md` and `test-inventory.txt` paths.
- Cloud/device impact: none.
