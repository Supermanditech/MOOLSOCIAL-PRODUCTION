# Temporary navigation prototype full dirty-status output-bounding recurrence

## Observation

The branch gate for the family-root HTML revision rendered the repository's complete dirty status. The output contained thousands of unrelated retained evidence paths and was truncated before the intended compact file-size inventory.

## Cause

The required branch check was combined with an unbounded full-tree status display even though the existing dirty tree had already been reconciled and the current revision has an exact four-file scope.

## Permanent prevention

- Read branch and HEAD with their exact bounded commands.
- Count and hash the full porcelain state without printing its rows.
- Display status only for exact current-scope paths.
- Never use the founder's preserved dirty tree as routine diagnostic output.

## Resolution evidence

All retries for this HTML revision use a bounded branch/HEAD response, a row count and digest for preservation, and target-only status output.
