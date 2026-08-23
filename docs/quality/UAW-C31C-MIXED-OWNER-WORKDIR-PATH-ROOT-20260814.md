# UAW C31C mixed-owner working-directory path root

## Incident

The first C31C compile checkpoint ran from `apps/mobile` while passing backend
paths relative to the repository root. PowerShell therefore resolved those
owners beneath `apps/mobile/backend` and failed on the first missing path.

## Impact

The command stopped before Dart formatting, TypeScript compilation or tests.
No application source, generated artifact, backend service, device, live data
or credential state was changed by the failed command.

## Prevention

Backend audits and compilation run from the repository or backend owner root.
Flutter formatting, analysis and tests run separately from `apps/mobile`.
Cross-owner relative paths are never combined under one working directory.
