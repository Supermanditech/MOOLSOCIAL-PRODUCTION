# C30T restart dirty-status NUL inventory recurrence — 2026-08-13

## Outcome

A resumed read-only reconciliation command captured the complete NUL-delimited
Git status and enumerated all untracked paths internally before printing only
counts. This repeated a prohibited evidence-heavy-workspace inventory pattern.

The command changed no file, source, build artifact, device or external
service. The accepted C30T source manifest was independently checked file by
file and still matched all 1,109 owners before this regression was registered.

## Root cause and prevention

The restart audit optimized for scalar counts instead of applying the permanent
dirty-tree boundary. Future C30T reconciliation uses branch and HEAD scalar
reads, tracked-only status, named C30T owner reads and the accepted source
manifest. It does not capture NUL-delimited full status or enumerate the
complete untracked evidence tree.

Because the regression registry and this evidence are source-sealed, both
no-AAB qualification cycles must be repeated before build authority can be
activated.
