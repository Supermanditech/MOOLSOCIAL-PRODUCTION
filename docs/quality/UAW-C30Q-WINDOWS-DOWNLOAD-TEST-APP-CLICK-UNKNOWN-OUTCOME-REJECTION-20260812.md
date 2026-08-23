# C30Q Windows Download test app click unknown-outcome rejection

Date: 2026-08-12

## Mistake

The first Windows-control click on the visible `Download test app` link returned an unknown input/refresh outcome. A required fresh observation proved that the page had not navigated and the same tester link remained visible.

## Impact

- No download or installation started.
- No Play, repository machine state, device, account, credential, or application data changed.

## Permanent prevention

Discard the failed observation and its element indexes. Re-observe the current window, activate it, then use exactly one fresh input derived from the new observation. If semantic input fails again, stop and hand the visible link click to the founder rather than looping.
