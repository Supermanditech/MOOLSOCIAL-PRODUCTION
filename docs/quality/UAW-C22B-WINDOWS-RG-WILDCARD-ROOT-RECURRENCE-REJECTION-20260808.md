# C22B Windows rg wildcard-root recurrence rejection

Date: 2026-08-08

The first stale-width verification supplied wildcard expressions as ripgrep roots for config and quality documents. Windows returned error 123. The literal scope file still exposed four stale 78 px values, but the mixed-error command is rejected as verification.

The correction searches literal `config` and `docs/quality` roots with `--glob`, updates every stale value to the invariant 72 px metric, and rebinds scope to the exact current C22B ticket hash.
