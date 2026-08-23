# C30O full dirty-status output bounding recurrence

Date: 2026-08-12

## Observed mistake

The mandatory Git reconciliation used unbounded `git status --short --branch` in a repository whose dirty tree contains thousands of founder-owned paths. The output was truncated even though the branch and HEAD were still recovered.

## Root cause

The required status command was run without routing its full output to an in-memory summary or applying the repository's existing large-dirty-tree output-bounding prevention.

## Prevention

- Do not repeat an unbounded status display in this tree.
- For reconciliation, retain the command semantics while reporting only branch, counts, and a bounded sample.
- Continue to preserve the entire dirty tree; output bounding must never become file filtering, deletion, cleaning, or ownership reduction.

## Retained evidence

The conversation tool result records truncation, the required branch `remediation/prototype-conformance-2026-07-20`, and HEAD `f6dfe7587aa02d782e94282d14af8bafff48ded0`. No Git mutation occurred.
