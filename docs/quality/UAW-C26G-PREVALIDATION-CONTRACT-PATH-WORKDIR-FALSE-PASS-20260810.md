# C26G suite prevalidation contract-path false pass

## Detection

The first suite prevalidation was launched from `apps/mobile` while attempting to read `config/mvp-personal-domain-navigation-host-qualification-c25g.json`. That repository-root-relative path was invalid from the selected working directory. PowerShell emitted path and null-value errors, but because they were non-terminating, Flutter ran only the five explicitly appended C26 tests and returned success.

The result is rejected and is not C26G qualifying evidence.

## Permanent prevention

C26G qualification resolves every path from an explicit repository root, sets `ErrorActionPreference = Stop`, asserts the sealed exact unique test count before Flutter invocation, and rejects missing owners before execution. The permanent regression memory gate retains this rule.
