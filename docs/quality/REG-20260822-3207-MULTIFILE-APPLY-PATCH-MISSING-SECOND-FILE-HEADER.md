# REG-20260822-3207 — Multi-file apply patch missing second file header

## Incident

A multi-file REG3205 evidence correction omitted the second `Update File`
header, so `apply_patch` searched for document prose in the registry JSON and
rejected the patch atomically.

## Impact

- Partial repository changes: `0`
- Additional APK or AAB builds: `0`
- Sealed artifacts: `0`
- OPPO actions: `0`

## Root cause

Two file-specific hunks were composed under one file header instead of
declaring an explicit `Update File` boundary for each owner.

## Permanent prevention

Use one explicit `Update File` header per owner in every multi-file patch,
verify patch boundaries before execution, and rely on atomic rejection rather
than inferring any partial edit.
