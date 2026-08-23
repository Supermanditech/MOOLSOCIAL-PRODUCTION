# REG-20260817-2730: C34L regression-registry path assumption

## Truthful event

A read-only C34L checkpoint command ran the MVP scope gate successfully and then guessed `config/regression-memory.json` for the registry count and SHA. That path does not exist, so only the registry-read portion stopped.

No candidate state, device, AAB, Google Play, credential, secret, deployment, or external state changed.

## Root cause

The combined verification command used a remembered generic filename instead of resolving the durable repository owner before composing the command.

## Prevention

- Use `config/codex-development-regression-registry.json` for the durable registry.
- Resolve uncertain owner paths with `rg --files` before a combined verification command.
- Register any failed guessed-path diagnostic before a corrected verification.

## Candidate consequence

C34L is still selection-only. It has no detailed/aggregate candidate state, source seal, cycles, AAB, upload, install, or OPPO acceptance, so this registration invalidates no qualified candidate.
