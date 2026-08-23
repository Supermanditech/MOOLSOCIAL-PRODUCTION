# REG2641 — C33V registry discovery assumed a nonexistent path

Date: 2026-08-16 IST

The first read-only attempt to inspect recent regression entries assumed
`config/first-attempt-regression-tests.json`. That path does not exist, so the
command returned no registry entries.

No candidate file or external system was changed. Count no result from that
lookup. Before reading registry metadata, discover the repository-owned path
with `rg --files`; use only
`config/codex-development-regression-registry.json` and verify its parsed entry
count.
