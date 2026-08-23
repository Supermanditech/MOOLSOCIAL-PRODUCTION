# REG-20260820-3026 Firebase reauth private OAuth URL transcript

## Incident

Interactive `firebase login --reauth` completed successfully, but the returned
PowerShell transcript included the private browser authorization URL, its
one-time state and the founder account identifier. Codex does not repeat or
retain those values in durable evidence.

## Impact

- Firebase CLI reauthentication succeeded.
- The one-time OAuth state had already been consumed by the completed login.
- No password, authorization code, access token, refresh token or provider
  secret was returned.
- No function deployment occurred yet.

## Root cause

The full interactive authentication transcript was copied instead of returning
only the final sanitized Firebase success marker.

## Prevention

Never copy authentication transcripts, login URLs, chooser content, account
identifiers, codes or tokens into chat. After private interactive login, return
only `FIREBASE_REAUTH_SUCCESS`; verify function absence separately and proceed
without echoing credential surfaces.
