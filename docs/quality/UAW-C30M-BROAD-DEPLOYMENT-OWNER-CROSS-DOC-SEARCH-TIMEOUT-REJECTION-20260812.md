# C30M broad deployment-owner cross-doc search timeout rejection

- ID: `REG-20260812-1446-C30M-BROAD-DEPLOYMENT-OWNER-CROSS-DOC-SEARCH-TIMEOUT-REJECTION`
- Date: 2026-08-12
- Scope: local read-only provider-package owner discovery
- Result: timed out; no source or cloud mutation occurred

The inventory searched a script, a deployment directory and the complete docs
tree in one command. It exceeded the bounded command window and returned no
accepted output. C30M retries only the exact known package-content owner first;
additional literal paths are queried individually and only if that owner points
to them.
