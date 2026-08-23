# UAW C10D Flutter analyze repository-root recurrence

- Registry: `REG-20260807-208-FLUTTER-ANALYZE-RAN-FROM-REPOSITORY-ROOT-AGAIN`
- State: resolved; explicit workdir gate active
- Impact: read-only noisy analysis of preserved artifact trees; no file or device mutation.
- Durable rule: format from repository root when using repository-relative operands, then run Flutter analysis separately from `apps/mobile`.
