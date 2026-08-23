# C30T Comment owner ripgrep quoted-regex parse error

- Regression: `REG-20260813-1963-C30T-COMMENT-OWNER-RG-QUOTED-REGEX-PARSE-ERROR`
- Date: 2026-08-13
- Scope: read-only Comment/Reply owner discovery.

## Incident

PowerShell quoting transformed a combined ripgrep expression, producing an
unclosed group. The command returned no admissible owner evidence.

## Required prevention

Use separate literal `rg -F -e` patterns or a verified single-quoted regex.
Register every parse error before retry.

This record creates no build, upload, install, deployment or device authority.
