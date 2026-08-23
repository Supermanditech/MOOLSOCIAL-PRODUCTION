# REG-20260820-3049 Firebase runtime finally pasted separately after success

## Observed failure

The secure build shell emitted `MOOLSOCIAL_FIREBASE_RUNTIME_READY`, then the
cleanup `finally` block was pasted as a separate command. PowerShell rejected
the detached `finally`. Runtime environment values remain ready; only temporary
non-secret parsing variables were not removed.

## Root cause

A multi-block top-level `try/catch/finally` recipe was copied in fragments, so
PowerShell no longer parsed `finally` as part of the originating statement.

## Impact

- Firebase runtime environment values were set successfully in the secure
  build process;
- no value was printed or copied outside that process;
- no repository, provider, build, Play, OPPO or device action occurred;
- temporary parsing variables remain until standalone cleanup.

## Prevention and authorized continuation

Do not retry the detached `finally`. Use one standalone `Remove-Variable`
cleanup command. Future founder-paste recipes must wrap multi-block control flow
in one invocation or avoid detachable `finally` blocks entirely.
