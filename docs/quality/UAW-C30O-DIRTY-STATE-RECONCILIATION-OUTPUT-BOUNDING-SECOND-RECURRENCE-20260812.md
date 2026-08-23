# C30O dirty-state reconciliation output-bounding second recurrence

Date: 2026-08-12

During post-failure reconciliation, one PowerShell command captured NUL-delimited
`git status` output in a scalar and returned no usable summary. Its replacement
then combined a recursively enumerating full untracked status with a broad
multi-owner search. The displayed result truncated, emitted long-path warnings,
and reported an invalid dirty count because it counted the `Measure-Object`
wrapper rather than its line result.

No file was changed or deleted by either read-only diagnostic. The output is
rejected as dirty-tree evidence. This repeats permanent bounded-dirty-tree
rules and the C30O recurrence already registered as
`REG-20260812-1539-C30O-FULL-DIRTY-STATUS-OUTPUT-BOUNDING-RECURRENCE`.

Prevention: never request the full untracked path set in this repository and
never combine dirty-state inventory with content search. Read branch and HEAD
as scalars, use bounded tracked-owner counts and top-level untracked-owner
counts separately, and validate the numeric property selected from any
aggregation object before reporting it.
