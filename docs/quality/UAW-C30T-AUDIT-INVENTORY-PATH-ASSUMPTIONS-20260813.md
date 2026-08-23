# C30T continuous Social audit inventory path assumptions

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
Scope: no-build test inventory diagnostics only

## Observed mistake

The first comparison between the accepted 49-file focused manifest and the broader 61-file Social/YouTube/Chat/navigation candidate set used a two-backslash string replacement. Windows paths still contained backslashes, so the set comparison falsely classified every candidate as absent. A subsequent read-only registry inspection guessed `config/codex-regression-memory.json`; the durable catalog is `config/codex-development-regression-registry.json`.

No application source, provider, device, AAB, Google Play track, Firebase setting, or external message was changed by either diagnostic.

## Correction and permanent prevention

- Normalize both inventories using the PowerShell regex form `-replace '\\','/'`.
- Assert that normalized paths contain `/` and no `\` before comparing sets.
- Discover the registry with `rg --files config | rg 'codex.*regression'` before reading it.
- Treat an impossible all-missing result or missing guessed durable path as a diagnostic failure requiring registration, never as a release finding.

The next comparison is authorized only after this entry exists and the regression-memory gate passes.
