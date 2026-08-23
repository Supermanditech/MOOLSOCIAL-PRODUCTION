# C30Q Play draft release DOM snapshot timeout rejection

Date: 2026-08-12

## Mistake

After the first file-chooser rejection, the Play tab was reclaimed and a read-only DOM snapshot was requested to prove upload state. The release page did not answer within the browser-control execution window, so the control session reset before returning a snapshot.

## Impact

- No file was selected or uploaded by this command.
- No Play release confirmation or rollout action was performed.
- No repository, artifact, machine, device, credential, or secret state changed.

## Permanent prevention

Before another Play upload attempt, require Chrome extension file-URL access to be enabled. On reconnection, obtain the cheapest bounded state signal first (title and URL, then a targeted locator count) instead of waiting on a full-page DOM snapshot.
