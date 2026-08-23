# C33E C30Z gate wrong-workdir error masked by later Flutter success

Date: 15 August 2026
Regression: `REG-20260815-2335-C33E-C30Z-GATE-WRONG-WORKDIR-ERROR-MASKED-BY-LATER-FLUTTER-SUCCESS`

## Observation

The first C33E local replay called the repository-relative C30Z PowerShell
gate while the process working directory was `apps/mobile`. PowerShell could
not resolve the gate. The following Flutter command still ran and passed 31
tests, leaving the combined shell cell with exit code zero even though the
earlier gate had failed to start.

The 31 Flutter passes are retained as valid test evidence. They are not
evidence that the C30Z PowerShell gate ran.

## Recovery

The retry is split by owner and working directory. The C30Z gate must run
alone from the repository root under fail-fast PowerShell handling and produce
its own successful exit. Mobile tests, if repeated, run separately from
`apps/mobile`. A later command's zero exit code cannot classify an earlier
PowerShell error as success.

No runtime, build, Play, OPPO install/update, provider, secret or external
service state changed.
