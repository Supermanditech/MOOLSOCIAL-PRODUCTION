# Authentication audit Windows rg wildcard-path regression

- Regression: `REG-20260815-2456-AUTH-AUDIT-WINDOWS-RG-WILDCARD-PATH`
- Failure: a shell-style wildcard was passed to `rg` as a positional Windows path.
- Impact: one read-only composite diagnostic emitted an invalid-filename error; no source or external state changed.
- Prevention: search repository directories and use `--glob` for file patterns; do not accept a pipeline-masked exit as a clean diagnostic.
