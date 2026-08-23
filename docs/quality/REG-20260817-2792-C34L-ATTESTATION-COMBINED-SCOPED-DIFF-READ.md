# REG2792 — C34L attestation combined scoped diff read

Date: 17 August 2026
State: registered read-only command-hygiene recurrence; zero mutation

## Mistake

While already stopped, the evidence-attestation agent combined two scoped
`git diff` reads with a semicolon in one shell command. The command only
displayed untracked source-attestation work and changed no repository or
external state.

## Prevention

Run one scoped repository-facing inspection per shell call. Do not combine
independent diff or gate reads with shell separators, even when both operations
are read-only.
