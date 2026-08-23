# C29L backend status wrong-relative-working-directory rejection

The C29L backend verification command ran from `backend/functions` but prefixed its read-only Git status and tracked-file paths with `backend/functions` again. Git warned that the doubled `backend/functions/backend/` path does not exist. The following `npm run typecheck` still completed cleanly.

The permanent prevention is to use repository-relative paths only from the repository root, or local `.`/`lib` paths from the backend package directory, and never mix the two path frames in one command. No source, build, device, provider or protected runtime changed.
