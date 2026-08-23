# C30L regression-gate path guess rejection

- Scope: local read-only deployment-preparation audit.
- Rejection: a command requested the nonexistent shortened path `scripts/check-codex-development-regressions.ps1`.
- Root cause: a remembered name was used instead of the exact registered gate path.
- Prevention: use `scripts/check-codex-development-regression-memory.ps1` from the registry or discover paths first with `rg --files`.
- Runtime impact: none. No cloud write, deployment, build, install, or device mutation occurred.
