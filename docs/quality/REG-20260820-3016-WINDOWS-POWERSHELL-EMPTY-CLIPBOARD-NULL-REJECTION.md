# REG-20260820-3016 Windows PowerShell empty clipboard null rejection

## Incident

After temporary-certificate cleanup passed, the founder ran
`Set-Clipboard -Value ""` in Windows PowerShell 5.1. That host normalized the
empty string to null and raised `ArgumentNullException` instead of clearing the
clipboard.

## Impact

- The clipboard-clear command made no change.
- The clipboard already contained copied terminal text rather than the
  development key hash.
- No repository, provider-console, build, deployment, Play or OPPO state
  changed.

## Root cause

The command assumed PowerShell 7-style acceptance of an empty string without
qualifying Windows PowerShell 5.1 `Set-Clipboard` null normalization.

## Prevention

Do not retry the empty string. In Windows PowerShell 5.1 overwrite the clipboard
with one harmless space, confirm no output is expected, then close the terminal.
Keep host-specific clipboard behavior out of provider-readiness evidence.
