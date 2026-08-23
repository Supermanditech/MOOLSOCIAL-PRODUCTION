# Full Chat regression registry filename guess rejection

Date: 2026-08-14
Registry ID: `REG-20260814-2120-FULL-CHAT-REGRESSION-REGISTRY-FILENAME-GUESS-REJECTION`

The first registration lookup requested the nonexistent `config/development-regression-memory.json` path. The authoritative owner is `config/codex-development-regression-registry.json`.

The corrected lookup enumerates the bounded `config` root and copies the returned registry path literally. The nonzero lookup is not accepted as evidence. No Chat source, backend, test, reference or machine state was changed by the failed command.
