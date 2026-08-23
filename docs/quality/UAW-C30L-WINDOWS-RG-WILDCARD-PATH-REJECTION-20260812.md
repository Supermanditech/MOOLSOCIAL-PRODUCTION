# C30L Windows rg wildcard-path rejection

- Scope: local read-only regression registration verification.
- Rejection: `rg` received a wildcard-bearing Windows path as a literal filename and reported invalid filename syntax.
- Root cause: shell-style glob expansion was assumed for a Windows executable argument.
- Prevention: discover matching paths with `rg --files -g` or `Get-ChildItem -Filter`, then read resolved literal paths.
- Runtime impact: none. The regression gate itself passed, and no cloud write, deployment, build, install, or device mutation occurred.
