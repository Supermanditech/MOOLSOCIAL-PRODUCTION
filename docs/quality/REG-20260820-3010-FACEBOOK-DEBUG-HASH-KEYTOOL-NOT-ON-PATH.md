# REG-20260820-3010 Facebook debug hash keytool not on PATH

## Incident

The corrected PowerShell certificate-hash workflow reached its first native
tool invocation, but Windows PowerShell could not resolve `keytool` from PATH
and raised `CommandNotFoundException`.

## Impact

- The certificate export did not start.
- The `finally` cleanup ran for the unique temporary path.
- No certificate, keystore password, key hash or credential value was read by
  Codex or returned in the transcript.
- No repository, provider-console, build, Play, OPPO or external state changed.
- The failed workflow is not accepted as development-key-hash evidence.

## Root cause

The workflow assumed Java's `keytool` executable was available on PATH instead
of resolving the exact configured JDK executable before creating or invoking
the export operation.

## Prevention

Do not retry the unresolved executable name. After refreshed gates, resolve one
exact existing `keytool.exe` from the repository's configured Java/Android
runtime using bounded path checks, invoke that literal executable, keep the
hash clipboard-only, and retain `finally` cleanup of the temporary certificate
and in-memory fingerprint variables.
