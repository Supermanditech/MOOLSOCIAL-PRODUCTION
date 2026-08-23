# REG2902 — C34L final-audit retained multirange read after truncation stop

## Incident

After the REG2901 transition output had already truncated, the independent auditor issued one later read instead of stopping immediately. That command loaded `scripts/check-release-retained-evidence-c34l.ps1` and emitted ranges 63–196, 461–768, 769–968, and 969–1327. It exited zero but also returned `Warning: truncated output`, with 15,202 original tokens and 1,005 output lines.

## Impact

- The retained-evidence read is inadmissible as complete audit evidence.
- The command was read-only. No behavior gate, repository mutation, recovery, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret, or external action occurred.
- No command followed this second truncation.

## Root cause

The auditor did not enforce the stop boundary immediately after the first incomplete read and repeated the same oversized multirange projection against another dense release owner.

## Prevention

- Stop immediately on the first truncation warning, independent of exit code.
- Do not issue a later diagnostic/read until the incident is registered and memory replay passes.
- Page dense owners in independent nonoverlapping slices of at most 100 lines and accept only complete results.

## Disposition

Registered separately from REG2901. No omitted retained-evidence lines are accepted as reviewed.
