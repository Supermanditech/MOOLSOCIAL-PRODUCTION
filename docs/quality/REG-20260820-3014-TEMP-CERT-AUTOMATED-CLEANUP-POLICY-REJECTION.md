# REG-20260820-3014 temporary certificate automated cleanup policy rejection

## Incident

After the founder saved the Facebook development key hash, the primary attempted
an automated bounded cleanup command that enumerated only the uniquely prefixed
temporary certificate files, validated their resolved parent and filename, and
then removed them by literal path. The execution layer rejected the dense
destructive command before process creation.

## Impact

- No cleanup command body executed.
- No file, repository, provider-console, build, Play or OPPO state changed by
  the rejected command.
- The exact interactive PowerShell session still owns the literal `$certPath`
  and disposable objects needed for simpler cleanup.

## Root cause

A dense shell command combined enumeration, confinement, reparse checks and
deletion in one nested execution string, triggering the execution policy before
the PowerShell process started.

## Prevention

Do not retry the rejected command. Use the founder's existing interactive shell
and its already-resolved exact `$certPath`; dispose the two in-process objects,
remove only that literal file, clear the variables and close the terminal. Do
not rescan or construct a destructive target.
