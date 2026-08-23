# REG-20260820-3030 Firebase private reauth transcript second recurrence

## Incident

The deployment transcript attachment again contained the earlier private
Firebase authorization URL, consumed state and founder account identifier.
Codex does not repeat or retain those values.

## Impact

- No password, code, access token, refresh token or provider secret was
  returned.
- The OAuth state had already been consumed by the earlier successful login.
- The recurrence adds no deployment authority or evidence.

## Prevention

Stop copying full PowerShell history. For all remaining work return only a new
command's final sanitized marker or a screenshot cropped below private login
history, with URLs and identifiers excluded.
