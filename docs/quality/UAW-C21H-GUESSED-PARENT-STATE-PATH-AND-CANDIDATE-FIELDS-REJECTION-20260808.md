# C21H guessed parent state path and candidate fields rejection

Date: 2026-08-08

The first read-only verification after opening the one-build authorization guessed a nonexistent parent C21 state filename and queried candidate/build-result property names that are not part of the current machine-state schema. The candidate identity therefore printed empty version diagnostics even though the JSON itself remained valid.

The result is rejected as build-authorization evidence. The corrected workflow selects the literal parent ticket path returned by the repository inventory, parses each JSON owner, enumerates the relevant property names, and uses `candidate.versionName`, `candidate.versionCode`, and `buildResult.state`. No build or installation occurred during the rejected probe.
