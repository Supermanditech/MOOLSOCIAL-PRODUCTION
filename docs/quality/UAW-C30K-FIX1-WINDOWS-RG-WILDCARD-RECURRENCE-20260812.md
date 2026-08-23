# C30K-FIX1 Windows rg wildcard recurrence

- Scope: local read-only delivery-gate owner discovery.
- Rejection: wildcard-bearing script paths were again passed directly to `rg` on Windows.
- Root cause: the registered REG-1412 path-discovery prevention was not applied.
- Prevention: discover scripts with `rg --files -g` or `Get-ChildItem -Filter` and pass only literal resolved paths to content searches.
- Runtime impact: none. The ticket JSON parsed and its hash was recorded; no cloud or device mutation occurred.
