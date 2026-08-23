# REG-20260820-3009 Meta Quickstart PowerShell placeholder pipeline parser

## Incident

The founder copied Meta's Windows development-key-hash example literally into
Windows PowerShell. The example still contained placeholder path segments and
placed quoted executable-path strings in a native pipeline without PowerShell's
call operator. PowerShell rejected the text during parsing with
`ExpressionsMustBeFirstInPipeline` and `Unexpected token` errors.

## Impact

- Exit was a parser failure before command execution.
- No keystore, certificate, key hash or credential value was read by Codex.
- No repository, provider-console, build, Play, OPPO or external state changed.
- The failed command is not accepted as key-hash evidence and must not be
  retried.

## Root cause

The provider Quickstart example was a template for another shell/tool layout,
not a ready-to-run PowerShell command. Placeholder paths were not resolved and
quoted executable strings were treated as expressions rather than invoked
commands.

## Prevention

Do not retry the provider command. Use `keytool` to export the certificate to a
unique temporary file, compute SHA-1 over the DER certificate with .NET, copy
only the Base64 fingerprint to the founder's clipboard, and remove the
temporary certificate in `finally`. The founder pastes the value directly into
Meta and never returns it through chat, logs or repository evidence.
