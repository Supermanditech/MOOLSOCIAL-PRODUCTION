# C30M unbounded dirty-tree reconciliation truncation rejection

- ID: `REG-20260812-1434-C30M-UNBOUNDED-DIRTY-TREE-RECONCILIATION-TRUNCATION-REJECTION`
- Date: 2026-08-12
- Scope: local read-only Git reconciliation
- Result: rejected; no source, cloud or device mutation occurred

The first reconciliation printed the full preserved dirty tree and truncated. Its output is not used. C30M retries exact branch and HEAD separately and represents the dirty tree only by bounded category counts and samples; all existing files remain preserved.
