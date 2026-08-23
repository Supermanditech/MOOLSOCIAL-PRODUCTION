# REG-20260820-3028 Firebase private reauth transcript recurrence

## Incident

The same completed Firebase reauthentication transcript class recurred in the
deployment-failure report, again including the private browser authorization
URL, consumed state and founder account identifier. No password, code or token
was returned.

## Impact

- The OAuth state was already consumed by the completed reauthentication.
- No additional authentication or deployment action occurred from sharing the
  transcript.
- Private values are not repeated or retained in durable evidence.

## Prevention

Never copy terminal history. For every later command return only the lines after
that command's start, with authentication URLs and identifiers omitted. A
deployment failure report contains only the final sanitized Firebase error.
