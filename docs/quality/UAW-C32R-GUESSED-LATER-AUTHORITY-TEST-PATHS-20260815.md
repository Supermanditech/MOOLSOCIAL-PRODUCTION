# C32R guessed later-authority test paths

Regression: `REG-20260815-2276-C32R-GUESSED-LATER-AUTHORITY-TEST-PATHS`

During the source-preserving C32R applicability comparison, one command first
listed the matching test owners correctly but then searched two guessed paths:
the C29N Social owner under `ui_v2/universal` instead of its inventoried
`ui_v2/social` location, and a C32P filename that was not present in the
inventory. Ripgrep returned partial evidence and exit code 1.

No source, test expectation, runtime, device, build, backend or external state
changed. The failed command is retained as process evidence. The next bounded
comparison must consume only exact paths returned by `rg --files`; nonexistent
ticket-derived filenames must not be retried.
