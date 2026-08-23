# C17F full untracked Git-status long-path rejection — 2026-08-08

## Rejection

The first C17F reconciliation invoked `git status --porcelain=v1 -uall` across the entire preserved dirty repository. Git emitted many `Filename too long` warnings while traversing historical Chromium profile artifacts below `artifacts/quality/.../html-copy-chrome-profile-rerun`. Although the command returned branch `remediation/prototype-conformance-2026-07-20`, HEAD `f6dfe7587aa02d782e94282d14af8bafff48ded0`, and 51,778 status lines, that full-untracked count and its derived hash are not admitted as a complete dirty-state identity because rejected paths may be omitted.

No file is deleted, moved, renamed, ignored, normalized, or otherwise changed to make the command pass.

## Prevention

- C17F reuses the established bounded source/status inventory covering production runtime, tests, gates, configs, governance, and current-ticket evidence.
- Tracked status is reconciled independently with untracked traversal disabled.
- Authorized current-ticket untracked paths are inventoried from verified literal roots with hashing that can fail explicitly per file.
- Historical browser-profile evidence remains preserved and outside the build source manifest.
- A command containing any path warning cannot seal whole-repository dirty identity even when its exit code is zero.
