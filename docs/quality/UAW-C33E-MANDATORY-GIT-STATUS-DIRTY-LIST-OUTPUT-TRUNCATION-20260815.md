# UAW C33E mandatory Git-status dirty-list output truncation

Date: 2026-08-15
Regression: `REG-20260815-2347-C33E-MANDATORY-GIT-STATUS-DIRTY-LIST-OUTPUT-TRUNCATED`

## Failure

The mandatory repository identity check printed the complete `git status --short --branch` listing for the founder-owned dirty tree. The tool truncated the listing because it contains thousands of preserved paths.

## Root cause and recovery

The identity check did not bound the known-large dirty-path inventory. The independently returned branch and HEAD values are valid, but the partial dirty-path listing is not treated as a complete inventory. Future identity checks must emit only the branch, HEAD, porcelain count and explicitly scoped ticket-owned paths; the full dirty tree remains preserved and is never rewritten or cleaned.

No repository file was mutated by the failed read.
