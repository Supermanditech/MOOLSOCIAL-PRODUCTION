# C30R MVP scope-state monolithic patch context rejection

Date: 2026-08-12

The first attempt to transition `config/mvp-scope-gate-state.json` from C30Q to
C30R used one large contextual patch. One expected exclusion string did not
match the exact current JSON text, so `apply_patch` rejected the entire patch
before changing the file.

No device, Play, provider, build, upload, install, runtime, email or quota state
changed. The C30R ticket, findings, machine state and checker created before the
failed scope-state patch remain present but are not executable until the MVP
scope state is successfully pinned and its gates pass.

Prevention: update the large machine state in small exact-context sections,
parse the resulting JSON after every bounded patch group, recompute and verify
the immutable ticket manifest hash, then run the delivery and MVP scope gates
before any external action.
