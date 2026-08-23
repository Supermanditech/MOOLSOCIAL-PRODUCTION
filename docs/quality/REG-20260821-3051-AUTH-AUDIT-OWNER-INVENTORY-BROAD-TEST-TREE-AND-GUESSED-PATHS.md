# REG-20260821-3051 auth audit owner inventory broad test tree and guessed paths

## Observed failure

The initial authentication owner inventory included the complete mobile test
and golden tree and two nonexistent guessed directories. Output was truncated
and the inventory is rejected.

## Root cause

The command grouped verified auth owners with a broad test root and unverified
backend/web path assumptions instead of applying bounded auth filename/content
filters to existing roots independently.

## Impact

- no source, ticket, test, build, Play, OPPO, provider or device action ran;
- no source inventory was accepted from the truncated output;
- no credential or private configuration content was read.

## Prevention and authorized continuation

Inventory each verified root independently. Filter mobile tests by exact auth,
login, OAuth, Firebase and provider filename tokens; enumerate backend auth only
from its existing literal directory; discover web roots before use; emit bounded
counts and literal owners only.
