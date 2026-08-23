# C29W assumed backend source-directory ripgrep rejection

- Date: 2026-08-11
- Candidate: `1.0.0-r60.35` (`2026081135`)
- Result: path lookup rejected before source read

A bounded owner search guessed `functions/src`, but that path does not exist in this repository layout. The search produced no accepted evidence. The exact backend source directory is resolved from the repository's `firebase.json` and durable C29U owner evidence before retrying. No source, build, device or provider mutation occurred.
