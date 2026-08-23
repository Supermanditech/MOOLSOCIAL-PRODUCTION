# C12 untracked artifact fingerprint scan recurrence

- Regression: `REG-20260807-268-C12-UNTRACKED-ARTIFACT-FINGERPRINT-SCAN-RECURRENCE`
- Phase: pre-build source sealing

The first C12 dirty-workspace fingerprint probe used
`git ls-files --others --exclude-standard` without path scoping. It traversed
the entire retained artifacts tree, reached historical browser-profile paths,
emitted filename-too-long warnings and timed out before producing a seal. No
source or machine state changed.

This repeats the registered unbounded-artifact search class. Permanent
prevention: source fingerprints enumerate only explicit production scopes
(`AGENTS.md`, `apps/mobile`, `apps/web`, `config`, `docs`, `scripts`, and
`tests`). Retained `artifacts` and `tmp` evidence never participates in a
source-dirty inventory unless an exact artifact directory is intentionally
named.
