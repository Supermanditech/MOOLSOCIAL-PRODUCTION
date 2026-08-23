# REG-20260820-3013 PowerShell finally separated and temporary certificate cleanup did not run

## Incident

The founder's isolated Facebook development-key-hash attempt successfully
exported the Android debug certificate, derived the fingerprint, copied it to
the clipboard and pasted it into Meta. The `try`/`catch` statement completed,
but `finally` was then entered as a separate top-level command. PowerShell
raised `CommandNotFoundException`, so the intended temporary-certificate and
in-process object cleanup did not run.

## Impact

- The fingerprint value remained founder-controlled and was not read or emitted
  by Codex.
- Meta displayed the populated field, but Save was not reported.
- One uniquely prefixed temporary certificate may remain in the OS temporary
  directory, and the interactive PowerShell process may retain disposable
  certificate/hash objects until it closes.
- No repository build, deployment, Play or OPPO action occurred.

## Root cause

The compound PowerShell statement was pasted in separate interactions, allowing
the completed `try`/`catch` to terminate before its `finally` clause.

## Prevention

Never split `try`/`catch`/`finally` across terminal submissions. Use one invoked
scriptblock as a single parser unit, or perform verified cleanup before emitting
the success marker. After refreshed gates, remove only exact uniquely prefixed
temporary certificate files through resolved literal paths, then close the
interactive PowerShell process.
