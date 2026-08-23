# UAW-C33J FIX2 Windows rg file-separator filter

Date: 2026-08-15

Regression: `REG-20260815-2517-C33J-FIX2-WINDOWS-RG-FILE-SEPARATOR-FILTER`

## Finding

A read-only inventory command piped `rg --files test` into a regular
expression that required `/` before each filename. On Windows the emitted
paths used `\`, so the filter returned zero matches and exit 1 even though the
target files were not proved absent.

No source mutation, test execution or qualification claim resulted from the
failed inventory command.

## Resolution rule

- Known affected test paths are validated with exact literal `Test-Path`
  checks before execution.
- Repository file filters that must accept both platforms use `[\\/]` rather
  than a single separator.
- A zero-match path filter is not absence evidence until its platform behavior
  is classified.

No build, deployment, live email, Play or device authority is created by this
record.
