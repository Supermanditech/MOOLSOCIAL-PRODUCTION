# C30O upload-key helper FileInfo Source-property rejection

Date: 2026-08-12

## Observed mistake

The founder ran the password-safe upload-key helper. Its PATH lookup did not find `keytool`, so it selected the qualified Android Studio JDK executable using `Get-Item`. The helper then invoked `$keytool.Source`, but the fallback object was a `FileInfo` whose executable path property is `FullName`. Strict mode rejected the missing property before `keytool` ran.

## Root cause

The helper used one variable for two different PowerShell object types and assumed their path properties were identical.

## Prevention

- Do not repeat the failed helper version.
- Normalize both discovery paths immediately into one validated string variable, `$keytoolPath`.
- Invoke only the normalized string path.
- Revalidate script syntax, qualified tool existence, and exact target absence before asking the founder to retry.

## Retained evidence

The founder-provided terminal output records `PropertyNotFoundStrict` for `Source`. The exact keystore target remained absent; no password prompt, private key, or keystore was created.
