# C24 state filename zero-match exit rejection — 2026-08-09

The bounded `rg --files config` search for a separate parent/current ticket state produced no matching filenames. Because the pipeline did not explicitly normalize ripgrep's expected exit code 1, the tool call surfaced as a failure even though zero matches was the truthful result.

No files were changed by that search. C24 will treat the existing `config/mvp-scope-gate-state.json` as the discovered authoritative selection state unless another literal owner is found by an explicitly zero-safe search.

This rejection is permanently registered as `REG-20260809-608-C24-STATE-FILENAME-ZERO-MATCH-EXIT-UNHANDLED`.
