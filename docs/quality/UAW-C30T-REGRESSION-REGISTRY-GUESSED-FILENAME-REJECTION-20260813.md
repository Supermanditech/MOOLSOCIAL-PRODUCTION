# UAW C30T regression-registry guessed-filename rejection — 2026-08-13

## Outcome

The follow-up attempted to read the nonexistent file
`config/codex-regression-memory.json`. The canonical registry is
`config/codex-development-regression-registry.json` and the canonical checker is
`scripts/check-codex-development-regression-memory.ps1`.

The failed lookup changed no product or release state. The registry was then
located by filename inventory before this entry was added.

## Permanent prevention

Never reconstruct or shorten the permanent registry filename from memory. Use
`rg --files` to locate the canonical registry and run the repository checker
before the next mutation.
