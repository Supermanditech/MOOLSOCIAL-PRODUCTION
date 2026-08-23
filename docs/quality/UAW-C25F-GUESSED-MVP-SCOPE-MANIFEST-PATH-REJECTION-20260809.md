# C25F guessed MVP scope manifest path rejection

- Date: 2026-08-09
- Status: registered before C25F selection

The scope audit attempted to read `config/mvp-scope-manifest.json`, which does not exist. The repository uses each selected ticket JSON as the sealed manifest and stores that path in the scope-gate state.

Future selection work must enumerate or read the current state’s exact `manifestPath`; it must not infer a generic manifest filename.
