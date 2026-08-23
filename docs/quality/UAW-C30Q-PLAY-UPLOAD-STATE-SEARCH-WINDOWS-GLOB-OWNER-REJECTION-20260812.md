# C30Q Play upload-state search Windows glob owner rejection

Date: 2026-08-12

## Mistake

A read-only search for the C30Q upload-state transition passed `docs/quality/UAW-C30Q*` as a ripgrep path owner. On Windows that wildcard was not expanded and ripgrep reported an invalid filename after returning matches from the valid owners.

## Impact

- The Play-accepted C30Q upload and its draft remained unchanged.
- No release details, rollout action, repository machine state, device state, credential, or secret changed.

## Permanent prevention

Enumerate matching evidence files with `rg --files docs/quality` and filter the names, or search the exact directory with a bounded `--glob`. Never pass an unexpanded wildcard as a Windows path owner.
