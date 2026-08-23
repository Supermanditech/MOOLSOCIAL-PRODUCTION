# C30M Windows rg positional-wildcard path rejection

- ID: `REG-20260812-1438-C30M-WINDOWS-RG-POSITIONAL-WILDCARD-PATH-REJECTION`
- Date: 2026-08-12
- Scope: local read-only regression-gate owner discovery
- Result: rejected; no cloud call, source mutation, build, install or device mutation occurred

The discovery command passed `docs/quality/UAW-C30M-*.md` as a positional path
to Windows `rg`, which rejected the wildcard path. Its partial matches are not
accepted as complete inventory evidence. C30M uses literal directories plus
explicit `-g` include patterns, or an exact already-known script path, and
preserves the immediate child exit status.
