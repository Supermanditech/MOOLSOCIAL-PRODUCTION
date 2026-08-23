# REG2918 — Codex config full-read output truncation

## Observed event

Before changing the founder-authorized Codex context settings, the primary agent attempted to emit the complete `C:\Users\jisal\.codex\config.toml` through the command tool. The tool reported that the output exceeded the available model context and was truncated.

## Impact

- The command was read-only.
- No Codex configuration, repository file, process, session, build, device, browser, provider, private value, or external state was changed.
- The incomplete output is inadmissible and must not be used as the edit basis.

## Root cause

The config was printed before measuring its size and before limiting inspection to the three exact requested top-level keys. A configuration owner may contain many unrelated sections and potentially sensitive values, so a full projection was unnecessary and unsafe.

## Mandatory prevention

1. Measure only file bytes and line count first.
2. Locate the first section header and inspect only exact top-level occurrences of `model`, `model_context_window`, and `model_auto_compact_token_limit`.
3. Never print unrelated configuration values or full personal configuration owners.
4. Apply one minimal top-level patch before all section headers, preserving every unrelated line.
5. Parse the resulting TOML and assert only the three requested effective values without serializing the remaining configuration.
