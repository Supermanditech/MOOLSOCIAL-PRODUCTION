# C29L PowerShell gate unset LASTEXITCODE rejection

The first C29L host-qualification attempt stopped before backend typecheck,
Flutter analysis or tests. Its first ticket-specific PowerShell gate passed,
but the wrapper then read `LASTEXITCODE` while strict mode was active. An
in-process PowerShell script does not promise to set that native-process
variable, so the wrapper produced a tooling false failure.

No qualifying-cycle evidence was created. No source owner changed during the
attempt, and no APK build, install, OPPO mutation, provider write, deployment,
external-service write, credential or secret-value access occurred.

The permanent prevention is to let terminating errors represent an
in-process PowerShell gate failure. The qualifier checks `LASTEXITCODE` only
immediately after native commands such as `npm`, `dart` and `flutter`.
