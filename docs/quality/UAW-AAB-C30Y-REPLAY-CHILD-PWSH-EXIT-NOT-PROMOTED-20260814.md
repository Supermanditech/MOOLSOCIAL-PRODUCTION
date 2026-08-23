# C30Y replay child PowerShell exit not promoted

- Incident: `REG-20260814-2174-AAB-C30Y-REPLAY-CHILD-PWSH-EXIT-NOT-PROMOTED`
- Scope: read-only prebuild replay command

The replay used a child `pwsh` process for regression memory. Its nonzero native exit did not become a terminating outer PowerShell error, so later read-only gates ran and passed before the combined command returned zero. Those later results remain individually valid, but the combined command is not atomic all-pass evidence.

Every retry must invoke a script in-process or assert `$LASTEXITCODE` immediately after each child process. No state count, AAB, Play action, OPPO mutation, deployment or secret input occurred.

## Resolution

Both post-FIX1 cycles invoked repository scripts in-process and asserted `$LASTEXITCODE` immediately after every Windows PowerShell child. The final pre-prompt replay used the same rule and returned one complete all-pass result. No child failure was masked, and release-action counts remain `0/0/0`.
