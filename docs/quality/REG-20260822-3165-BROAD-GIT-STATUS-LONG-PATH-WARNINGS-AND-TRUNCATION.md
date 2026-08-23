# REG3165 - Broad git status long-path warnings and truncation

## Classification

Registered dirty-digest rejection with zero repository mutation.

## Evidence

`git status --porcelain=v1 --untracked-files=all` traversed legacy browser-profile evidence whose Windows paths exceed Git's open limit. It emitted 267 warning lines, skipped paths and the result truncated. The visible count and digest are not credited.

## Prevention

Use the repository's existing bounded non-emitting dirty-digest owner. Suppress path warnings and emit only native exit, count and hash after a complete successful read.
