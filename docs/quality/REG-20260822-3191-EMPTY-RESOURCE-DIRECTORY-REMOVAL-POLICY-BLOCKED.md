# REG3191 - Empty resource-directory removal policy blocked

## Classification

Registered execution safety-policy rejection with zero filesystem mutation,
APK, install or device action; immediate founder help required.

## Evidence

The exact path `apps/mobile/android/app/src/main/res/drawable-v21` was proven
repository-confined, present and empty. A nonrecursive native PowerShell
`Remove-Item -LiteralPath` command was rejected by the execution safety layer
before process creation. Readback before the attempt proved item count zero;
the rejection performed no deletion.

## Prevention and external-help boundary

Do not attempt a cross-shell or alternate deletion workaround. Ask the founder
immediately to run one literal PowerShell removal command in the production
repository. Afterward, independently prove the directory is absent, rerun final
lint, and continue sealing only if the report has zero errors and no obsolete
directory warning.
