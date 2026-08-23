# C21 guessed scope and APK state filenames rejection — 2026-08-08

## Rejected action

The C21 read-only source/state inspection attempted to open the nonexistent files `config/uaw-personal-mvp-scope-gate.json` and `config/uaw-personal-mvp-apk-machine-state.json`.

## Impact

PowerShell rejected both reads. No runtime source, protected reference, APK, installed package, or device state was mutated.

## Root cause

The inspection shortened authoritative repository filenames instead of discovering them from the repository. The correct state owners are `config/mvp-scope-gate-state.json` and `config/apk-regression-gate-state.json`.

## Permanent prevention

State files must be selected from `rg --files config` or from the literal paths owned by their checker scripts. Guessed or abbreviated state filenames are rejected before ticket evidence is accepted.
