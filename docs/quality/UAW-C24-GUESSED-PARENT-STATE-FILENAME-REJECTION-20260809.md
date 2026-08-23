# C24 guessed parent-state filename rejection — 2026-08-09

## Rejected attempt

The C24 planning inspection correctly read `config/mvp-scope-gate-state.json`, then attempted to read a guessed `config/uaw-personal-mvp-parent-scope-state.json`. The guessed path does not exist and the compound command exited nonzero.

No authoritative state was changed. The valid scope-state output remains read-only evidence; the missing guessed path authorizes no conclusion.

## Required prevention

Resolve state-owner filenames with a bounded `rg --files config` search before opening them. Use only literal returned paths, and keep optional state discovery separate from authoritative reads.

This rejection is permanently registered as `REG-20260809-607-C24-GUESSED-PARENT-STATE-FILENAME`.
