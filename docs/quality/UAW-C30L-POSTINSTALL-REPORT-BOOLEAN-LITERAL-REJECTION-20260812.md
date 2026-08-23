# C30L postinstall report boolean-literal rejection

- Scope: single authorized in-place OPPO install.
- Mutation result: `adb -s 2b3e0f71 install -r <qualified APK>` completed with `Success`; install count is consumed and must not be retried.
- Rejection: the reporting object then used bare `true`/`false` instead of PowerShell `$true`/`$false`.
- Prevention: reconstruct all remaining evidence read-only from the install log, installed package identity and APK checksum. No second install is permitted.
