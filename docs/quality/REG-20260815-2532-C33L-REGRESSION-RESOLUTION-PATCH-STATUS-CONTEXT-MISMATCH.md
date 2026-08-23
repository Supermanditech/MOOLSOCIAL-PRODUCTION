# REG-20260815-2532 C33L regression-resolution patch context mismatch

- Date: 2026-08-15
- Failure: the combined resolution patch expected an underscore in the
  `REG-2531` status where the registry used a hyphen, so `apply_patch`
  rejected the entire operation.
- Impact: no partial write, build, deployment, external-service or device
  action occurred.
- Root cause: the patch did not copy the exact current token from the immediate
  registry read.
- Prevention: use narrow one-owner hunks copied from the current file and do
  not repeat the rejected multi-file context.
- Resolution: the exact current tokens were re-read and narrow owner-specific
  hunks applied without a partial write.
