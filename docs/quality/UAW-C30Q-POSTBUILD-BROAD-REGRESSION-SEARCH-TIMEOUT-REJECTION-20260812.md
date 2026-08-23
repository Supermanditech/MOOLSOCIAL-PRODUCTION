# C30Q post-build broad regression search timeout rejection

Date: 2026-08-12

## Mistake

The follow-up read-only discovery combined a broad recursive content search across `config`, `scripts`, and `docs` with an output cap. The owner set was unnecessarily large and the command exceeded its timeout before returning the registry location.

## Impact

- No repository, artifact, machine, provider, device, credential, or secret state changed.
- No C30Q gate was retried by the timed-out command.

## Permanent prevention

Enumerate bounded filenames first with `rg --files`, filter only the expected registry or memory owner names, and inspect the exact selected file. Do not use broad documentation content search merely to locate a known registry class.
