# C17F unbounded successor uniqueness search rejection

- Date: 2026-08-08
- Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-CUMULATIVE-OPPO-QUALIFICATION-FIX2-C17F`
- State: rejected lookup; no candidate selection, build authorization, build, install, or device mutation resulted.

## Observation

The first r60.17 uniqueness lookup recursively traversed the repository-wide historical artifact tree and exceeded its bounded command time before it could return complete evidence. A timed-out partial search cannot establish candidate uniqueness.

## Permanent prevention

Candidate-id, version-name and version-code uniqueness are checked separately in `config` and `docs/quality`, then against bounded top-level artifact directory and file names. Binary APKs, generated build output, `tmp`, device matrices and unrelated historical evidence are excluded. The machine gate still requires exact registered candidate, version, source-manifest and runtime-define identity before the single guarded build.
