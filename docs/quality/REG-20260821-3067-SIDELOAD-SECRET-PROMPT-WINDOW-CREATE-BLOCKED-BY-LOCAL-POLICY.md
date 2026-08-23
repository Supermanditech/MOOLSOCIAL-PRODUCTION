# REG-20260821-3067 sideload secret-prompt window create blocked by local policy

## Observed failure

The attempt to launch an encoded PowerShell window that would collect all
sideload build inputs was blocked by the local process policy before launch.

## Root cause

The command combined window creation, interactive secret prompts and extensive
runtime configuration in one process-launch payload, which the local policy
correctly rejected.

## Impact

- no window or process was created;
- no secret, environment value, build, Play or device state changed;
- the existing founder helper windows remain unaffected.

## Prevention and authorized continuation

Use a repository-owned prompt script containing no values. The founder invokes
it manually in an existing PowerShell window and enters every secret directly;
only bounded readiness markers may be emitted.
